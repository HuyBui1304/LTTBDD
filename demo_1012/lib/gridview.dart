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
        body: GridView.count(
          crossAxisCount: 2, // 2 cột
          children: <Widget>[
            Container(
              color: Colors.red,
              child: const Center(child: Text('Item 1')),
            ),
            Container(
              color: Colors.green,
              child: const Center(child: Text('Item 2')),
            ),
            Container(
              color: Colors.blue,
              child: const Center(child: Text('Item 3')),
            ),
            Container(
              color: Colors.yellow,
              child: const Center(child: Text('Item 4')),
            ),
          ],
        ),
      ),
    );
  }
}