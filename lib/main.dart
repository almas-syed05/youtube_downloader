import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const YouTubeDownloaderPage(),
    );
  }
}

class YouTubeDownloaderPage extends StatefulWidget {
  const YouTubeDownloaderPage({super.key});

  @override
  State<YouTubeDownloaderPage> createState() => _YouTubeDownloaderPageState();
}

class _YouTubeDownloaderPageState extends State<YouTubeDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _downloadData;

  // API endpoints - Railway production backend
  static const String backendUrl = "https://youtubedownloader-production-4570.up.railway.app";
  static const String mergeApiUrl = "$backendUrl/merge";
  static const String videoInfoUrl = "$backendUrl/video-info";

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }  Future<void> _mergeVideoAudio(String videoUrl, String audioUrl, String title) async {
    if (!mounted) return;
    
    // Create a ValueNotifier for progress updates
    final progressNotifier = ValueNotifier<String>('Starting merge...');
    final elapsedNotifier = ValueNotifier<int>(0);
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<String>(
        valueListenable: progressNotifier,
        builder: (context, progressText, child) {
          return ValueListenableBuilder<int>(
            valueListenable: elapsedNotifier,
            builder: (context, elapsed, child) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: elapsed > 0 ? (elapsed / 60).clamp(0.0, 0.95) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      progressText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (elapsed > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${elapsed}s elapsed',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'This usually takes 30-60 seconds',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    // Update elapsed time every second
    final timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        elapsedNotifier.value++;
        if (elapsedNotifier.value <= 10) {
          progressNotifier.value = 'Initializing...';
        } else if (elapsedNotifier.value <= 30) {
          progressNotifier.value = 'Merging streams...';
        } else if (elapsedNotifier.value <= 50) {
          progressNotifier.value = 'Processing video...';
        } else {
          progressNotifier.value = 'Almost done...';
        }
      }
    });

    try {
      // Request merge from server (this will wait until complete)
      final response = await http.post(
        Uri.parse(mergeApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "videoUrl": videoUrl, 
          "audioUrl": audioUrl,
          "title": title,
        }),
      );

      timer.cancel();
      progressNotifier.dispose();
      elapsedNotifier.dispose();
      
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data['downloadUrl'];
        final filename = data['filename'] ?? 'merged.mp4';
        
        // Show dialog with download button
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Merge Complete!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your video has been merged successfully!'),
                const SizedBox(height: 12),
                Text('Filename: $filename', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                const Text('Click "Download" to save the merged video.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _launchUrl(downloadUrl);
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Merge failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchDownloadLinks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _downloadData = null;
    });

    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a YouTube URL';
      });
      return;
    }

    try {
      // Use backend yt-dlp endpoint instead of youtube-explode
      print('DEBUG: Fetching from backend: $videoInfoUrl?url=$url');
      
      final response = await http.get(
        Uri.parse('$videoInfoUrl?url=${Uri.encodeComponent(url)}'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
      }
      
      final data = json.decode(response.body);
      
      print('DEBUG: Got response from backend');
      print('DEBUG: Video title: ${data['title']}');
      print('DEBUG: Video options: ${data['videoOptions']?.length ?? 0}');
      print('DEBUG: Audio options: ${data['audioOptions']?.length ?? 0}');
      print('DEBUG: Muxed options: ${data['muxedOptions']?.length ?? 0}');
      
      setState(() {
        _downloadData = {
          'title': data['title'],
          'author': data['author'],
          'duration': data['duration']?.toString() ?? 'Unknown',
          'thumbnail': data['thumbnail'],
          'videoOptions': data['videoOptions'] ?? [],
          'audioOptions': data['audioOptions'] ?? [],
          'muxedOptions': data['muxedOptions'] ?? [],
        };
        _isLoading = false;
      });
      
    } catch (e) {
      String errorMsg = e.toString();
      bool isServerError = errorMsg.contains('500') || errorMsg.contains('Failed to fetch');
      
      setState(() {
        _isLoading = false;
        if (isServerError) {
          _errorMessage = '⚠️ Server Temporary Issue\n\n'
              'The download server is currently processing your request or experiencing issues.\n\n'
              '✅ SOLUTION: Please use one of the alternative websites below:\n'
              '• yt1s.com\n'
              '• y2mate.com\n'
              '• ytmp3.cc\n\n'
              'These websites are always available and should work.';
        } else {
          _errorMessage = 'Error: $errorMsg\n\nMake sure the URL is valid and the video is public.';
        }
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch download link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('YouTube Downloader'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo/Header
            const Icon(
              Icons.download_rounded,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Download YouTube Videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // URL Input Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'Paste YouTube video URL here',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            
            // Download Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchDownloadLinks,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Fetching...' : 'Get Download Links'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Download Links
            if (_downloadData != null) ...[
              const Text(
                'Download Options:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _downloadData!['title'] ?? 'Video Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_downloadData!['author'] != null)
                        Text(
                          'By: ${_downloadData!['author']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Video Quality Options
                      const Text(
                        'Video Options (No Audio):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_downloadData!['videoOptions'] as List<Map<String, dynamic>>).map((option) {
                        return Column(
                          children: [
                            _buildDownloadOption(
                              option['quality'],
                              Icons.videocam,
                              () => _launchUrl(option['url']),
                            ),
                            if (option != (_downloadData!['videoOptions'] as List).last)
                              const Divider(),
                          ],
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Audio Only:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_downloadData!['audioOptions'] as List<Map<String, dynamic>>).map((option) {
                        return _buildDownloadOption(
                          option['quality'],
                          Icons.audio_file,
                          () => _launchUrl(option['url']),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Merge Option
                      const Text(
                        'Merge Video + Audio (Experimental):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This will merge the highest quality video and audio using our server.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final videoUrl = (_downloadData!['videoOptions'] as List<Map<String, dynamic>>)[0]['url'];
                          final audioUrl = (_downloadData!['audioOptions'] as List<Map<String, dynamic>>)[0]['url'];
                          _mergeVideoAudio(videoUrl, audioUrl, _downloadData!['title']);
                        },
                        icon: const Icon(Icons.merge_type),
                        label: const Text('Merge & Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How to use:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Copy YouTube video URL'),
                    SizedBox(height: 4),
                    Text('2. Paste it in the field above'),
                    SizedBox(height: 4),
                    Text('3. Click "Get Download Links"'),
                    SizedBox(height: 4),
                    Text('4. Choose your preferred quality'),
                    SizedBox(height: 12),
                    Text(
                      'Note: Third-party APIs may be unstable. If this fails, visit yt1s.com, y2mate.com, or ytmp3.cc directly.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Alternative Options Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.web, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Alternative Methods:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildWebLink('yt1s.com', 'https://www.yt1s.com'),
                    const SizedBox(height: 8),
                    _buildWebLink('y2mate.com', 'https://www.y2mate.com'),
                    const SizedBox(height: 8),
                    _buildWebLink('ytmp3.cc', 'https://ytmp3.cc'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Footer
            const Text(
              'Made by Almas with ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(String quality, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quality,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.download, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLink(String name, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Row(
        children: [
          const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
