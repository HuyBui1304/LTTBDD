import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showAssetImage = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Bùi Minh Huy - 2286400009"),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
                    width: 250,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                  if (showAssetImage)
                    Image.asset(
                      'assets/4421bef88bb104ef5da0.jpg',
                      width: 320,
                      height: 520,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showAssetImage = !showAssetImage;
                  });
                },
                child: Text(
                  showAssetImage ? 'Ẩn ảnh Asset' : 'Hiện ảnh Asset',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}