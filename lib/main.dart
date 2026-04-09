import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Status Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ───────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<File> _images = [];
  List<File> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final paths = [
      '/sdcard/WhatsApp/Media/.Statuses',
      '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    ];

    List<File> images = [];
    List<File> videos = [];

    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            final name = file.path.toLowerCase();
            if (name.endsWith('.jpg') ||
                name.endsWith('.jpeg') ||
                name.endsWith('.png')) {
              images.add(file);
            } else if (name.endsWith('.mp4')) {
              videos.add(file);
            }
          }
        }
      }
    }

    setState(() {
      _images = images;
      _videos = videos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Saver',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Photos (${_images.length})'),
            Tab(text: 'Videos (${_videos.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(_images, isVideo: false),
          _buildGrid(_videos, isVideo: true),
        ],
      ),
    );
  }

  Widget _buildGrid(List<File> files, {required bool isVideo}) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isVideo ? Icons.videocam_off : Icons.image_not_supported,
                size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              isVideo ? 'No video statuses found' : 'No photo statuses found',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open WhatsApp and view some statuses first',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewScreen(
                  file: files[index],
                  isVideo: isVideo,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(files[index], fit: BoxFit.cover),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 40),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ─── Preview Screen ─────────────────────────────────────────────────────────

class PreviewScreen extends StatefulWidget {
  final File file;
  final bool isVideo;

  const PreviewScreen({super.key, required this.file, required this.isVideo});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _saving = false;
  bool _saved = false;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _saveFile() async {
    setState(() => _saving = true);

    final fileName = widget.file.path.split('/').last;
    final result = await SaverGallery.saveFile(
      filePath: widget.file.path,
      fileName: fileName,
      androidRelativePath: 'Pictures/StatusSaver',
      skipIfExists: false,
    );
    bool? success = result.isSuccess;

    setState(() {
      _saving = false;
      _saved = success == true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success == true
                ? '✅ Saved to gallery!'
                : '❌ Failed to save. Try again.',
          ),
          backgroundColor: success == true ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _togglePlay() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVideo ? 'Video Preview' : 'Photo Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? _videoController != null &&
                  _videoController!.value.isInitialized
                  ? GestureDetector(
                onTap: _togglePlay,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio:
                      _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    if (!_isPlaying)
                      const Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 64),
                  ],
                ),
              )
                  : const CircularProgressIndicator(color: Colors.white)
                  : Image.file(widget.file, fit: BoxFit.contain),
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving || _saved ? null : _saveFile,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Icon(_saved ? Icons.check : Icons.download),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : _saved
                      ? 'Saved!'
                      : 'Save to Gallery',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}