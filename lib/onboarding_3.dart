import 'package:flutter/material.dart';
import 'package:walky/services/onboarding_body.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const OnboardBody(
        imageAsset: 'assets/img/tutorial_3.png',
        title: '소중한 순간을\n한 눈에 살펴보세요',
        desc: '그 간의 산책 기록들을 모아보면서\n추억을 되새기세요.',
    );
  }
}