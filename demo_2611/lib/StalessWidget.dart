import 'package:flutter/material.dart';

class UserInfoWidget extends StatelessWidget {
  final String username;
  final String email;

  UserInfoWidget({required this.username, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Username: $username', style: const TextStyle(fontSize: 20)),
        Text('Email: $email', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class DemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: UserInfoWidget(
          username: 'huybm',
          email: 'huybm.ds@gmail.com',
        ),
      ),
    );
  }
}