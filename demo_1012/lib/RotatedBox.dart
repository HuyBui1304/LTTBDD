import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('RotatedBox Example')),
        body: const Center(
          child: RotatedBox(
            quarterTurns: 1, // xoay 90 độ
            child: Text('Hello Flutter!'),
          ),
        ),
      ),
    );
  }
}