import 'package:flutter/material.dart';
import 'package:walky/services/onboarding_body.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardBody(
      imageAsset: 'assets/img/tutorial_1.png',
      title: '산책 경로 추천을\n받아보세요',
      desc: '당신의 위치에 맞는 다양하고 색다른\n산책 경로를 추천해드려요.',
    );
  }
}