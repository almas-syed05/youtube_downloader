import express from "express";
import ffmpeg from "fluent-ffmpeg";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import cors from "cors";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const app = express();
app.use(express.json());
app.use(cors()); // Allow Flutter app to connect

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Store merge jobs
const mergeJobs = new Map();

// NEW: yt-dlp endpoint for video info extraction
app.get("/video-info", async (req, res) => {
  const { url } = req.query;
  
  if (!url) {
    return res.status(400).json({ error: "Missing url parameter" });
  }

  try {
    console.log(`📹 Fetching video info for: ${url}`);
    
    // Use yt-dlp to get video information in JSON format
    const { stdout } = await execAsync(`yt-dlp -J --no-playlist "${url}"`);
    const videoInfo = JSON.parse(stdout);
    
    // Extract the best video and audio formats
    const formats = videoInfo.formats || [];
    
    // Get video-only streams (sorted by quality)
    const videoStreams = formats
      .filter(f => f.vcodec && f.vcodec !== 'none' && (!f.acodec || f.acodec === 'none'))
      .sort((a, b) => (b.height || 0) - (a.height || 0));
    
    // Get audio-only streams (sorted by bitrate)
    const audioStreams = formats
      .filter(f => f.acodec && f.acodec !== 'none' && (!f.vcodec || f.vcodec === 'none'))
      .sort((a, b) => (b.abr || 0) - (a.abr || 0));
    
    // Get muxed streams (video + audio combined)
    const muxedStreams = formats
      .filter(f => f.vcodec && f.vcodec !== 'none' && f.acodec && f.acodec !== 'none')
      .sort((a, b) => (b.height || 0) - (a.height || 0));
    
    // Prepare response
    const response = {
      title: videoInfo.title,
      author: videoInfo.uploader || videoInfo.channel,
      duration: videoInfo.duration,
      thumbnail: videoInfo.thumbnail,
      videoOptions: videoStreams.slice(0, 5).map(s => ({
        quality: `${s.height}p (${s.vcodec}) - ${(s.filesize / 1024 / 1024).toFixed(1)} MB`,
        url: s.url,
        height: s.height,
        format_id: s.format_id
      })),
      audioOptions: audioStreams.slice(0, 3).map(s => ({
        quality: `${s.abr ? s.abr.toFixed(0) : 'Unknown'} kbps (${s.acodec}) - ${s.filesize ? (s.filesize / 1024 / 1024).toFixed(1) : 'Unknown'} MB`,
        url: s.url,
        format_id: s.format_id
      })),
      muxedOptions: muxedStreams.slice(0, 5).map(s => ({
        quality: `${s.height}p Combined - ${s.filesize ? (s.filesize / 1024 / 1024).toFixed(1) : 'Unknown'} MB`,
        url: s.url,
        height: s.height,
        format_id: s.format_id
      }))
    };
    
    console.log(`✅ Successfully fetched info for: ${videoInfo.title}`);
    res.json(response);
    
  } catch (error) {
    console.error(`❌ Error fetching video info:`, error.message);
    res.status(500).json({ 
      error: "Failed to fetch video information",
      details: error.message 
    });
  }
});

app.post("/merge", async (req, res) => {
  const { videoUrl, audioUrl, title } = req.body;
  
  if (!videoUrl || !audioUrl) {
    return res.status(400).json({ error: "Missing videoUrl or audioUrl" });
  }

  const jobId = Date.now().toString();
  // Clean title for filename (remove special characters)
  const cleanTitle = (title || 'merged_video')
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '_')
    .substring(0, 100);
  const outputPath = path.join(__dirname, `${cleanTitle}_${jobId}.mp4`);

  console.log(`🎬 Starting merge job ${jobId}...`);
  console.log(`Title: ${cleanTitle}`);
  console.log(`Video: ${videoUrl.substring(0, 80)}...`);
  console.log(`Audio: ${audioUrl.substring(0, 80)}...`);

  // Store job info
  mergeJobs.set(jobId, { 
    status: "processing", 
    outputPath,
    filename: `${cleanTitle}.mp4`,
    progress: 0 
  });

  // Wait for merge to complete using a Promise
  try {
    await new Promise((resolve, reject) => {
      ffmpeg()
        .input(videoUrl)
        .input(audioUrl)
        .outputOptions(["-c:v copy", "-c:a aac", "-shortest"])
        .save(outputPath)
        .on("end", () => {
          console.log(`✅ Merge job ${jobId} complete!`);
          mergeJobs.set(jobId, { 
            status: "complete", 
            outputPath,
            filename: `${cleanTitle}.mp4`,
            progress: 100 
          });
          resolve();
        })
        .on("error", (err) => {
          console.error(`❌ FFmpeg error in job ${jobId}:`, err.message);
          mergeJobs.set(jobId, { 
            status: "error", 
            error: err.message,
            progress: 0 
          });
          reject(err);
        })
        .on("progress", (progress) => {
          const percent = progress.percent || 0;
          console.log(`Job ${jobId}: ${percent.toFixed(2)}% done`);
          // Update progress in the job
          const job = mergeJobs.get(jobId);
          if (job) {
            job.progress = percent;
            mergeJobs.set(jobId, job);
          }
        });
    });

    // Merge completed successfully - return download URL
    res.json({ 
      jobId,
      downloadUrl: `http://10.0.2.2:3000/download/${jobId}`,
      filename: `${cleanTitle}.mp4`,
      message: "Merge complete! Click download to get your video."
    });
  } catch (err) {
    res.status(500).json({ 
      error: `Merge failed: ${err.message}` 
    });
  }
});

// Progress check endpoint
app.get("/progress/:jobId", (req, res) => {
  const { jobId } = req.params;
  const job = mergeJobs.get(jobId);

  if (!job) {
    return res.status(404).json({ error: "Job not found" });
  }

  res.json({
    status: job.status,
    progress: job.progress || 0,
    error: job.error || null
  });
});

// Download endpoint
app.get("/download/:jobId", (req, res) => {
  const { jobId } = req.params;
  const job = mergeJobs.get(jobId);

  if (!job) {
    return res.status(404).send("Job not found");
  }

  if (job.status === "processing") {
    return res.status(202).send("Still processing... Please wait and try again.");
  }

  if (job.status === "error") {
    return res.status(500).send(`Merge failed: ${job.error}`);
  }

  if (job.status === "complete") {
    console.log(`📥 Sending merged file for job ${jobId}`);
    res.download(job.outputPath, job.filename, (err) => {
      if (err) {
        console.error("Download error:", err);
      }
      // Clean up after download
      setTimeout(() => {
        fs.unlink(job.outputPath, (unlinkErr) => {
          if (unlinkErr) console.error("Cleanup error:", unlinkErr);
        });
        mergeJobs.delete(jobId);
      }, 1000);
    });
  }
});

app.get("/", (req, res) => {
  res.send("YouTube Merge Server is running! 🎬");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ FFmpeg merge server running on port ${PORT}`);
  console.log(`📡 POST to /merge with { videoUrl, audioUrl, title }`);
});

// made by almas
