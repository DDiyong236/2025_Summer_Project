// lib/terms_and_cond.dart
import 'package:flutter/material.dart';
import 'package:walky/full_doc_1.dart';
import 'package:walky/full_doc_2.dart';
import 'package:walky/full_doc_3.dart';


import 'package:walky/survey_1.dart';

class TermsAndConditionPage extends StatefulWidget {
  const TermsAndConditionPage({super.key});

  @override
  State<TermsAndConditionPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionPage> {
  bool _isAllAgreed = false;
  final List<bool> _requiredAgreements = [false, false, false];

  void _onToggleAll(bool? value) {
    if (value == null) return;
    setState(() {
      _isAllAgreed = value;
      for (int i = 0; i < _requiredAgreements.length; i++) {
        _requiredAgreements[i] = value;
      }
    });
  }

  void _onToggleRequired(int index, bool? value) {
    if (value == null) return;
    setState(() {
      _requiredAgreements[index] = value;
      _isAllAgreed = _requiredAgreements.every((element) => element);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = _requiredAgreements.every((element) => element);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '약관동의',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '편리한 서비스 이용을 위해 약관에 동의해주세요.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 45),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _buildAgreementItem(
                      title: '전체 동의하기',
                      value: _isAllAgreed,
                      onChanged: _onToggleAll,
                      isBold: true,
                      onTap: null,
                    ),
                  ),
                  _buildAgreementItem(
                    title: '(필수) 서비스 이용 약관',
                    value: _requiredAgreements[0],
                    onChanged: (v) => _onToggleRequired(0, v),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FullDoc1()),
                      );
                    },
                  ),
                  _buildAgreementItem(
                    title: '(필수) 개인정보 수집 동의',
                    value: _requiredAgreements[1],
                    onChanged: (v) => _onToggleRequired(1, v),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FullDoc2()),
                      );
                    },
                  ),
                  _buildAgreementItem(
                    title: '(필수) 위치정보 이용 동의',
                    value: _requiredAgreements[2],
                    onChanged: (v) => _onToggleRequired(2, v),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FullDoc3()),
                      );
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: canProceed
                            ? const Color(0xFFBFE240)
                            : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: canProceed
                          ? () {
                        //  '동의' 버튼 클릭 시 servey_1.dart로 이동
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const Survey1()),
                        );
                      }
                          : null,
                      child: const Text(
                        '동의',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildAgreementItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    Function()? onTap,
    bool isBold = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFBFE240),
              checkColor: Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black87 : Colors.black54,
              ),
            ),
            const Spacer(),
            if (!isBold)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}