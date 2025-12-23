import 'package:flutter/material.dart';

void main() => runApp(const AnimatedPositionedExampleApp());

class AnimatedPositionedExampleApp extends StatelessWidget {
  const AnimatedPositionedExampleApp({super.key});

  static const Duration duration = Duration(seconds: 2);
  static const Curve curve = Curves.fastOutSlowIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AnimatedPositioned Sample'),
        ),
        body: const Center(
          child: AnimatedPositionedExample(
            duration: duration,
            curve: curve,
          ),
        ),
      ),
    );
  }
}

class AnimatedPositionedExample extends StatefulWidget {
  const AnimatedPositionedExample({
    required this.duration,
    required this.curve,
    super.key,
  });

  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedPositionedExample> createState() =>
      _AnimatedPositionedExampleState();
}

class _AnimatedPositionedExampleState
    extends State<AnimatedPositionedExample> {
  int clickCount = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            clickCount++;
          });
        },
        child: Text(
          'Click ME! $clickCount',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}