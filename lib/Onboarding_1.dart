import 'package:flutter/material.dart';

class Onboarding_1 extends StatelessWidget {
  const Onboarding_1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: const Center(
          child: Text("이곳은 앱 다운로더 온보딩 페이지입니다.",
            style: TextStyle(fontSize: 20),)
      ),
    )
  }
}