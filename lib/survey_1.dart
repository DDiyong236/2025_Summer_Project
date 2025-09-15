import 'package:flutter/material.dart';
import 'dart:async'; // Timer를 사용하기 위해 추가
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

  Timer? _debounce; // 디바운스 타이머 변수

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInput);

    _shakeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // 진동 시간 조절
    );

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _shakeAnimationController,
        curve: Curves.elasticIn, // 진동 효과 곡선
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
    _debounce?.cancel(); // 타이머 취소
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
          // 1. 진행 바
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: MediaQuery.of(context).size.height * 0.03,
            right: MediaQuery.of(context).size.height * 0.03,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 0.167),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: 0.166,
                    minHeight: 7.0,
                    backgroundColor: const Color(0xFFF5F5F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFBFE240),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. 텍스트와 입력 필드
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
            left: MediaQuery.of(context).size.height * 0.025,
            right: MediaQuery.of(context).size.height * 0.025,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'STEP 1',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF707070),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '닉네임을 설정해주세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : const Color(0xFFDDD7D7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Transform.translate(
                  offset: Offset(_showError ? _shakeAnimation.value : 0.0, 0.0),
                  child: Center(
                    child: Text(
                      '한글 또는 영문만 사용하여 2~12자로 입력해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showError ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. 다음 단계 버튼
          Positioned(
            top: MediaQuery.of(context).size.height * 0.85,
            right: MediaQuery.of(context).size.width * 0.10,
            child: FloatingActionButton(
              onPressed: _isNicknameValid
                  ? () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    Survey2(nickname: _nicknameController.text),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
              backgroundColor:
              _isNicknameValid ? const Color(0xFFBFE240) : Color(0x80BFE240),
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