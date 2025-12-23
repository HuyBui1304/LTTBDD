import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Bùi Minh Huy_2286400009',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cat'),
              Tab(text: 'Dog'),
              Tab(text: 'Rabbit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image(
                  image: AssetImage('assets/cat.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image(
                  image: AssetImage('assets/dog.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image(
                  image: AssetImage('assets/rabbit.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}