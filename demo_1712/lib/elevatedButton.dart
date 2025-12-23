import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ElevatedButtonDemo(),
    );
  }
}

class ElevatedButtonDemo extends StatelessWidget {
  const ElevatedButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bùi Minh Huy - 2286400009'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // xử lý khi bấm (hiện tại chưa làm gì)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // nút xanh
            elevation: 0,                 // không nảy
          ),
          child: const Text(
            'Default Elevated Button',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}