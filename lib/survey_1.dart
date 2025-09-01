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

    // 자연스러운 진동을 위한 Tween 설정
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
    // 이전 타이머가 있다면 취소
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // 500ms(0.5초) 지연 후 유효성 검사 실행
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final text = _nicknameController.text;
      final bool isValid = _validateNickname(text);

      setState(() {
        _isNicknameValid = isValid;
        _showError = !isValid && text.isNotEmpty;
      });

      // 유효하지 않은 입력이 있고 텍스트가 비어있지 않을 때 진동 애니메이션 시작
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
                    value: value,
                    minHeight: 10.0,
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
                // 조건에 따라 글씨 색상 변경 및 진동 효과 적용
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
              onPressed: _isNicknameValid ? () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const Survey2(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
                      var tween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              } : null,
              backgroundColor:
              _isNicknameValid ? const Color(0xFFBFE240) : Colors.grey,
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