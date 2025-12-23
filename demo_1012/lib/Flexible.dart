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
        body: Row(
          children: [
            Flexible(
              flex: 1,
              child: Container(
                color: Colors.red,
                height: 100,
                child: const Center(
                  child: Text('Flexible 1'),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Container(
                color: Colors.blue,
                height: 100,
                child: const Center(
                  child: Text('Flexible 2'),
                ),
              ),
            ),
            Container(
              width: 50,
              height: 100,
              color: Colors.yellow,
              child: const Center(
                child: Text('Fixed Width'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}