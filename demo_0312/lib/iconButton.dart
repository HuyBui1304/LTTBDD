import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Bùi Minh Huy - 2286400009"),
        ),
        body: Center(
          child: IconButton(
            icon: Icon(Icons.star),
            iconSize: 50.0,
            color: Colors.amber,
            onPressed: () {
              print('Đã nhấn nút ngôi sao');
            },
            tooltip: 'Thêm vào yêu thích',
          ),
        ),
      ),
    );
  }
}