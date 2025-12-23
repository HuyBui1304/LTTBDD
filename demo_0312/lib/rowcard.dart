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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Card(
                color: Colors.red,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Card 1"),
                ),
              ),
              Card(
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Card 2"),
                ),
              ),
              Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Card 3"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}