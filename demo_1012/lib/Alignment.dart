import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bùi Minh Huy 2286400009'),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Align(
          alignment: Alignment.center,
          child: const Text(
            'Aligned Text',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}