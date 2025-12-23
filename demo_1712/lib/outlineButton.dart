import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OutlinedBtnDemo(),
    );
  }
}

class OutlinedBtnDemo extends StatelessWidget {
  const OutlinedBtnDemo({super.key});

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OutlinedButton Example')),
      body: Center(
        child: OutlinedButton.icon(
          onPressed: () => _showMsg(context, 'OutlinedButton pressed'),
          icon: const Icon(Icons.download),
          label: const Text('Click OutlinedButton!'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green, // icon + text
            side: const BorderSide(color: Colors.green, width: 2), // viền
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}