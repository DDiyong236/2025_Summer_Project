import 'package:flutter/material.dart';

class Onboarding1 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String desc;

  const Onboarding1({
    super.key,
    this.imageAsset = 'assets/img/walky_logo.png',   // 자유롭게 변경
    this.title = '온보딩 1',
    this.desc = '페이지 1입니다.',
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardBody(imageAsset: imageAsset, title: title, desc: desc);
  }
}

class _OnboardBody extends StatelessWidget {
  final String imageAsset, title, desc;
  const _OnboardBody({required this.imageAsset, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 에셋 이미지(없으면 아이콘으로 대체 가능)
        Image.asset(imageAsset, height: 180, fit: BoxFit.contain),
        const SizedBox(height: 32),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
}
