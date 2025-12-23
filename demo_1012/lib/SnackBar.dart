import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

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
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('This is a SnackBar'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      print('Undo pressed');
                    },
                  ),
                ),
              );
            },
            child: const Text('Show SnackBar'),
          ),
        ),
      ),
    );
  }
}