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

    // Dùng video online có tiếng, nhưng mình chỉ lấy phần audio
    _controller = VideoPlayerController.network(
      'https://www.w3schools.com/html/mov_bbb.mp4',
    )..initialize().then((_) {
        _controller.setVolume(1.0); 
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
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
    final isInitialized = _controller.value.isInitialized;
    final duration =
        isInitialized ? _controller.value.duration : Duration.zero;
    final position =
        isInitialized ? _controller.value.position : Duration.zero;

    // Tránh lỗi khi duration = 0
    final maxSeconds =
        duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final valueSeconds = position.inSeconds
        .clamp(0, duration.inSeconds > 0 ? duration.inSeconds : 1)
        .toDouble();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Bùi Minh Huy - 2286400009"),
        ),
        body: Center(
          child: isInitialized
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICON PHÁT NHẠC
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100,
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Demo",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // SLIDER TUA
                    SizedBox(
                      width: 300,
                      child: Slider(
                        min: 0,
                        max: maxSeconds,
                        value: valueSeconds,
                        onChanged: (value) async {
                          await _controller.seekTo(
                            Duration(seconds: value.toInt()),
                          );
                        },
                      ),
                    ),

                    // HÀNG NÚT ĐIỀU KHIỂN
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tua lùi 10s
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          onPressed: () async {
                            if (!isInitialized) return;
                            final pos = _controller.value.position -
                                const Duration(seconds: 10);
                            await _controller.seekTo(
                                pos < Duration.zero ? Duration.zero : pos);
                          },
                        ),

                        // Play / Pause
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (!isInitialized) return;
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

                        // Bật / tắt tiếng
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                          ),
                          onPressed: () {
                            if (!isInitialized) return;
                            setState(() {
                              _isMuted = !_isMuted;
                              _controller.setVolume(_isMuted ? 0.0 : 1.0);
                            });
                          },
                        ),

                        // Tua tới 10s
                        IconButton(
                          icon: const Icon(Icons.forward_10),
                          onPressed: () async {
                            if (!isInitialized) return;
                            final pos = _controller.value.position +
                                const Duration(seconds: 10);
                            final max = _controller.value.duration;
                            await _controller.seekTo(pos > max ? max : pos);
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