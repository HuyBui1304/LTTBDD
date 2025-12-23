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
          title: const Text("Bùi Minh Huy - 2286400009"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tạo một hộp trống có kích thước cố định
              SizedBox(
                width: 200,
                height: 50,
                child: Card(
                  elevation: 10,
                  color: Colors.green,
                  child: const Center(
                    child: Text(
                      "Hộp trống",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Tạo khoảng trống 20px giữa 2 widget
              const SizedBox(height: 20),

              Card(
                elevation: 10,
                color: Colors.blue,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Card 2",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}