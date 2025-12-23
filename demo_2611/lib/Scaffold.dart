import 'package:flutter/material.dart';

// Định nghĩa đối tượng Phone
class Phone {
  final String brand;
  final String model;
  final String number;

  Phone({
    required this.brand,
    required this.model,
    required this.number,
  });
}

class MyScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tạo đối tượng Phone
    Phone myPhone = Phone(
      brand: "Apple",
      model: "iPhone 13",
      number: "123-456-7890",
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Ví dụ Scaffold'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bùi Minh Huy 2286400009'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
        drawer: Drawer(),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home), 
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone),  // Thêm icon điện thoại
              label: 'Phone',  // Đổi tên mục thành 'Phone'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings), 
              label: 'Settings',
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}