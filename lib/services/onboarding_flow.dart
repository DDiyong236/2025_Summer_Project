import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_page.dart';
import '../onboarding_1.dart';
import '../onboarding_2.dart';
import '../onboarding_3.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    Onboarding1(), // 필요하면 Onboarding1(imageAsset:'...', title:'...', desc:'...')로 교체
    Onboarding2(),
    Onboarding3(),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = index == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Onboarding - ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (i) => setState(() => index = i),
                  children: pages,
                ),
              ),
              const SizedBox(height: 8),
              _DotsIndicator(length: pages.length, current: index),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? '시작' : '다음으로', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인디케이터(좌→우 진행, 현재 페이지만 길고 진하게)
class _DotsIndicator extends StatelessWidget {
  final int length;
  final int current;
  const _DotsIndicator({required this.length, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 18 : 8,
          decoration: BoxDecoration(
            color: selected ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
