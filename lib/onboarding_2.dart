import 'package:flutter/material.dart';
import 'package:walky/services/onboarding_body.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const OnboardBody(
        imageAsset: 'assets/img/tutorial_2.png',
        title: '산책과 함께\n 기록해보세요',
        desc: '산책 중 사진을 찍고\n나만의 이야기를 남겨보세요.',
    );
  }
}