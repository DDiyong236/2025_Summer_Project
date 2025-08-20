import 'package:flutter/material.dart';
import 'package:walky/services/onboarding_body.dart';
import 'onboarding_1.dart' show _OnboardBody; // 같은 레이아웃 재사용

class Onboarding3 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String desc;

  const Onboarding3({
    super.key,
    this.imageAsset = 'assets/img/walky_logo.png',
    this.title = '온보딩 3',
    this.desc = '페이지 3입니다.',
  });

  @override
  Widget build(BuildContext context) {
    return OnboardBody(
        imageAsset: imageAsset,
        title: title,
        desc: desc);
  }
}
