import 'package:client_experimental/start_page_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'WebSockets Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new StartPageScreen(),
    );
  }
}
