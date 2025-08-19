import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: const Center(
        child: Text("이곳은 기존 사용자 메인 페이지입니다.",
        style: TextStyle(fontSize: 20),)
      ),
    );
  }
}