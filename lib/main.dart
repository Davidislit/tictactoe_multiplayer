import 'package:client_experimental/helper/socket_service.dart';
import 'package:client_experimental/start_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

Injector injector;
void main() async {
  runApp(new MyApp());
  SocketService socketService = SocketService();
  socketService.createSocketConnection();
}

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
