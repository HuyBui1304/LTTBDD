import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureSimplePage(),
    );
  }
}

class GestureSimplePage extends StatelessWidget {
  const GestureSimplePage({super.key});

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bùi Minh Huy - 2286400009')),
      body: Center(
        child: GestureDetector(
          onTap: () => _showMsg(context, 'Tapped'),
          onDoubleTap: () => _showMsg(context, 'Double tapped'),
          onLongPress: () => _showMsg(context, 'Long pressed'),
          child: Container(
            width: 120,
            height: 120,
            color: Colors.blue,
            alignment: Alignment.center,
            child: const Text(
              'Tap Me',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}