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
          child: OutlinedButton(
            onPressed: () {
              print('OutlinedButton pressed');
            },
            child: const Text('Tap Me'),
          ),
        ),
      ),
    );
  }
}