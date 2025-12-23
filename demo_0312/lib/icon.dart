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
              Material(
                elevation: 10,
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),

              Material(
                elevation: 10,
                child: Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),

              Material(
                elevation: 10,
                child: Icon(
                  Icons.star,
                  color: Colors.blue,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),

              Material(
                elevation: 10,
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.purple,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),

              Material(
                elevation: 10,
                child: Icon(
                  Icons.phone,
                  color: Colors.orange,
                  size: 50,
                ),
              ),
              SizedBox(height: 30),

              Material(
                elevation: 10,
                child: Icon(
                  Icons.person,
                  color: Colors.brown,
                  size: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}