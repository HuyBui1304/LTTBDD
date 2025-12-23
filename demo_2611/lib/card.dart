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
          title: Text('Ví dụ du Card'),
        ),
        body: Center(
          child: Card(
            color: Colors.blue[100],  
            elevation: 5.6,  
            shape: RoundedRectangleBorder(  
              borderRadius: BorderRadius.circular(10.0),  
            ),
            margin: EdgeInsets.all(16.0), 
            child: Text(
              'Bùi Minh Huy 2286400009',  
              style: TextStyle(fontSize: 18), 
            ),
          ),
        ),
      ),
    );
  }
}