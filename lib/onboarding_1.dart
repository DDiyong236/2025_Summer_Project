import 'package:flutter/material.dart';
import 'package:walky/services/onboarding_body.dart';

class Onboarding1 extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String desc;

  const Onboarding1({
    super.key,
    this.imageAsset = 'assets/img/walky_logo.png',
    this.title = '온보딩 1',
    this.desc = '페이지 1입니다.',
  });

  @override
  Widget build(BuildContext context) {
    return OnboardBody(
      imageAsset: imageAsset,
      title: title,
      desc: desc,
    );
  }
}
