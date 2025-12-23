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
        body: SingleChildScrollView(
          child: Column(
            children: [
              for (int i = 1; i <= 50; i++)
                Center(
                  child: Text('Item $i'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}