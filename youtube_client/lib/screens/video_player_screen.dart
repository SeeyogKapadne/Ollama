import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String filename;
  final double startTime; // in seconds

  const VideoPlayerScreen({required this.filename, this.startTime = 0.0, Key? key})
      : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _isFullScreen = false;
  Duration _currentPosition = Duration.zero;

  // Overlay control
  bool _showControls = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final videoUrl = ApiService.getVideoUrl(widget.filename);

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (widget.startTime > 0) {
          _controller.seekTo(Duration(milliseconds: (widget.startTime * 1000).toInt()));
        }
        _controller.addListener(_updatePosition);
        setState(() => _isLoading = false);
        _controller.play();
      });
  }

  void _updatePosition() {
    setState(() {
      _currentPosition = _controller.value.position;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePosition);
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _stopVideo() {
    _controller.pause();
    _controller.seekTo(Duration.zero);
  }

  void _forwardVideo() {
    final newPos = _controller.value.position + Duration(seconds: 10);
    _controller.seekTo(newPos < _controller.value.duration ? newPos : _controller.value.duration);
  }

  void _rewindVideo() {
    final newPos = _controller.value.position - Duration(seconds: 10);
    _controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  void _showOverlay() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoWidth = _isFullScreen ? MediaQuery.of(context).size.width : 450.0;
    final videoHeight = _isFullScreen ? MediaQuery.of(context).size.height : 240.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(widget.filename),
              backgroundColor: Colors.blueAccent.shade700,
            ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.blueGrey.shade700)
            : MouseRegion(
                onHover: (_) => _showOverlay(),
                child: GestureDetector(
                  onTap: _showOverlay,
                  child: Container(
                    width: videoWidth,
                    height: videoHeight,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: ClipRRect(
                            borderRadius:
                                _isFullScreen ? BorderRadius.zero : BorderRadius.circular(12),
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        // Overlay controls
                        if (_showControls)
                          Container(
                            color: Colors.black38,
                            child: Stack(
                              children: [
                                // Center play/pause/stop/rewind/forward
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: _rewindVideo,
                                        icon: Icon(Icons.replay_10, color: Colors.white),
                                        iconSize: 36,
                                      ),
                                      IconButton(
                                        onPressed: _controller.value.isPlaying
                                            ? _controller.pause
                                            : _controller.play,
                                        icon: Icon(
                                          _controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        iconSize: 50,
                                      ),
                                      IconButton(
                                        onPressed: _stopVideo,
                                        icon: Icon(Icons.stop, color: Colors.white),
                                        iconSize: 36,
                                      ),
                                      IconButton(
                                        onPressed: _forwardVideo,
                                        icon: Icon(Icons.forward_10, color: Colors.white),
                                        iconSize: 36,
                                      ),
                                    ],
                                  ),
                                ),
                                // Top-right fullscreen
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      _isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    onPressed: _toggleFullScreen,
                                  ),
                                ),
                                // Bottom progress bar and time
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      VideoProgressIndicator(
                                        _controller,
                                        allowScrubbing: true,
                                        colors: VideoProgressColors(
                                          playedColor: Colors.red.shade700,
                                          backgroundColor: Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${_formatDuration(_currentPosition)} / ${_formatDuration(_controller.value.duration)}",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Center large play button when paused
                        if (!_controller.value.isPlaying && !_showControls)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
