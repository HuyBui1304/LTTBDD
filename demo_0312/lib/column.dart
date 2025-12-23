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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 10,
                shadowColor: Colors.black,
                color: Colors.red,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Card 1"),
                ),
              ),
              SizedBox(height: 50),
              Card(
                elevation: 10,
                shadowColor: Colors.black,
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Card 2"),
                ),
              ),
              SizedBox(height: 50),
              Card(
                elevation: 10,
                shadowColor: Colors.black,
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