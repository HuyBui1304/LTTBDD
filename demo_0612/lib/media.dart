import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    )..initialize().then((_) {
        _controller.setVolume(1.0);
        setState(() {
          _isPlaying = true;
        });
        _controller.play();
      });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Bùi Minh Huy - 2286400028"),
        ),
        body: Center(
          child: _controller.value.isInitialized
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 300,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Slider(
                      min: 0,
                      max: _controller.value.duration.inSeconds.toDouble(),
                      value: _controller.value.position.inSeconds
                          .clamp(
                            0,
                            _controller.value.duration.inSeconds,
                          )
                          .toDouble(),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _controller.seekTo(position);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          onPressed: () async {
                            final current = _controller.value.position;
                            final newPosition =
                                current - const Duration(seconds: 10);
                            final clamped = newPosition < Duration.zero
                                ? Duration.zero
                                : newPosition;
                            await _controller.seekTo(clamped);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                          ),
                          onPressed: () {
                            setState(() {
                              _isMuted = !_isMuted;
                              _controller.setVolume(_isMuted ? 0.0 : 1.0);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10),
                          onPressed: () async {
                            final current = _controller.value.position;
                            final max = _controller.value.duration;
                            final newPosition =
                                current + const Duration(seconds: 10);
                            final clamped =
                                newPosition > max ? max : newPosition;
                            await _controller.seekTo(clamped);
                          },
                        ),
                      ],
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}