import 'package:flutter/material.dart';
import 'survey_3.dart'; // survey_3.dart 파일을 임포트합니다.

class Survey2 extends StatefulWidget {
  final String nickname;
  const Survey2({Key? key, required this.nickname}) : super(key: key);

  @override
  _Survey2State createState() => _Survey2State();
}

class _Survey2State extends State<Survey2> {
  final List<String> _characterImages = [
    'assets/img/character1.png',
    'assets/img/character2.png',
    'assets/img/character3.png',
    'assets/img/character4.png',
  ];

  final List<String> _characterNames = [
    '싹둘기',
    '숲냥이',
    '우비덕',
    '뭉게멍',
  ];

  int _selectedIndex = 0;

  void _saveSelectionAndNavigate(BuildContext context) {
    if (_selectedIndex != null) {
      print('선택된 캐릭터 인덱스: $_selectedIndex');
      // 유효성 검사 후 다음 화면으로 이동
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Survey3(
            nickname: widget.nickname,
            characterIndex: _selectedIndex,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.ease));
            return FadeTransition(
              opacity: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else {
      // 캐릭터를 선택하지 않았을 경우 경고 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('캐릭터를 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCharacterCard(int index, double screenWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        children: [
          // 캐릭터 이미지 박스 (고정 크기)
          Container(
            width: screenWidth * 0.35, // 화면 너비의 35%로 고정
            height: screenWidth * 0.35, // 정사각형으로 고정
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _selectedIndex == index
                    ? Colors.blue
                    : Colors.grey[300]!,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                _characterImages[index],
                fit: BoxFit.contain,
              ),
            ),
          ),
          // 캐릭터 이름 (박스 아래)
          const SizedBox(height: 10),
          Text(
            _characterNames[index],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 진행바 (수정된 부분)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: MediaQuery.of(context).size.height * 0.03,
            right: MediaQuery.of(context).size.height * 0.03,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.167, end: 0.334),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
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

          // 2. Header Text (Survey1과 동일한 위치)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
            left: MediaQuery.of(context).size.height * 0.025,
            right: MediaQuery.of(context).size.height * 0.025,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 30),
                Text(
                  'STEP 2',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF707070),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '캐릭터를 골라보세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),

          // 3. Character Selection Grid (화면 중앙)
          Positioned(
            top: screenHeight * 0.28, // 시작 위치 조정
            left: screenWidth * 0.08,   // 좌우 8% 마진
            right: screenWidth * 0.08,
            child: SizedBox(
              height: screenHeight * 0.52, // 화면 높이의 52% 사용
              child: Row(
                children: [
                  // 첫 번째 열
                  Expanded(
                    child: Column(
                      children: [
                        // 첫 번째 캐릭터 (상단 여백 추가)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: _buildCharacterCard(0, screenWidth),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // 세 번째 캐릭터
                        Expanded(
                          child: _buildCharacterCard(2, screenWidth),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 두 번째 열
                  Expanded(
                    child: Column(
                      children: [
                        // 두 번째 캐릭터 (상단 여백 추가)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: _buildCharacterCard(1, screenWidth),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // 네 번째 캐릭터
                        Expanded(
                          child: _buildCharacterCard(3, screenWidth),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Next Button (Survey1과 동일한 위치)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.85,
            right: MediaQuery.of(context).size.width * 0.10,
            child: FloatingActionButton(
              onPressed: () {
                _saveSelectionAndNavigate(context);
              },
              elevation: 0,
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: _selectedIndex != null ? const Color(0xFFBFE240) : Color(0x80BFE240),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}