import 'package:flutter/material.dart';

// 온보딩 공용 위젯

class OnboardBody extends StatelessWidget {
  final String imageAsset, title, desc;
  const OnboardBody({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imageAsset, height: 180, fit: BoxFit.contain),
        const SizedBox(height: 32),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
}
