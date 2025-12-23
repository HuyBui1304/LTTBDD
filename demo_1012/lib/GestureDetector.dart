import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Bùi Minh Huy 2286400009')),
        body: Center(
          child: GestureDetector(
            onTap: () => print('Tapped'),
            onDoubleTap: () => print('Double Tapped'),
            onLongPress: () => print('Long Pressed'),
            child: Container(
              width: 120,
              height: 120,
              color: Colors.blue,
              child: const Center(child: Text('Tap Me')),
            ),
          ),
        ),
      ),
    );
  }
}