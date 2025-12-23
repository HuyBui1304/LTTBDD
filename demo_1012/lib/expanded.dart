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
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              height: 100,
              color: Colors.red,
              child: const Center(
                child: Text('Top Container'),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.green,
                child: const Center(
                  child: Text('Expanded Container'),
                ),
              ),
            ),
            Container(
              height: 100,
              color: Colors.blue,
              child: const Center(
                child: Text('Bottom Container'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}