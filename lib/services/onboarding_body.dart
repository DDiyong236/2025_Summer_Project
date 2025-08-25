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
      // 텍스트를 왼쪽으로 정렬
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          // 이미지는 중앙에 배치
          child: Image.asset(imageAsset, height: 270, fit: BoxFit.contain),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 여백 추가
          child: Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 여백 추가
          child: Text(
            desc,
            style: const TextStyle(fontSize: 20, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}