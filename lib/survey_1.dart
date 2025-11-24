import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'survey_2.dart';

class Survey1 extends StatefulWidget {
  const Survey1({Key? key}) : super(key: key);

  @override
  _Survey1State createState() => _Survey1State();
}

class _Survey1State extends State<Survey1> with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  final _nicknameRegExp = RegExp(r'^[가-힣a-zA-Z]+$');
  bool _isNicknameValid = false;
  bool _showError = false;

  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInput);

    _shakeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _shakeAnimationController,
        curve: Curves.elasticIn,
      ),
    );

    _shakeAnimationController.addListener(() {
      if (_shakeAnimationController.isCompleted) {
        _shakeAnimationController.reverse();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nicknameController.removeListener(_validateInput);
    _nicknameController.dispose();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  void _validateInput() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final text = _nicknameController.text;
      final bool isValid = _validateNickname(text);

      setState(() {
        _isNicknameValid = isValid;
        _showError = !isValid && text.isNotEmpty;
      });

      if (!isValid && text.isNotEmpty) {
        _shakeAnimationController.forward(from: 0.0);
      }
    });
  }

  bool _validateNickname(String nickname) {
    if (nickname.isEmpty) {
      return false;
    }
    return _nicknameRegExp.hasMatch(nickname) &&
        nickname.length >= 2 &&
        nickname.length <= 12;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0.08.sh,
            left: 0.03.sh,
            right: 0.03.sh,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(15.r)),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 0.167),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: 0.166,
                    minHeight: 7.0.h,
                    backgroundColor: const Color(0xFFF5F5F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFBFE240),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0.13.sh,
            left: 0.025.sh,
            right: 0.025.sh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                Text(
                  'STEP 1',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF707070),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '닉네임을 설정해주세요',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 50.h),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0.r),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0.r),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0.r),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Transform.translate(
                  offset: Offset(_showError ? _shakeAnimation.value : 0.0, 0.0),
                  child: Center(
                    child: Text(
                      '한글 또는 영문만 사용하여 2~12자로 입력해주세요.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _showError ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0.85.sh,
            right: 0.10.sw,
            child: FloatingActionButton(
              onPressed: _isNicknameValid
                  ? () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        Survey2(nickname: _nicknameController.text),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var tween = Tween(begin: 0.0, end: 1.0).chain(
                        CurveTween(curve: Curves.ease),
                      );
                      return FadeTransition(
                        opacity: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              }
                  : null,
              elevation: 0,
              backgroundColor: _isNicknameValid
                  ? const Color(0xFFBFE240)
                  : const Color(0x80BFE240),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}