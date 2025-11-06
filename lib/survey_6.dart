import 'package:flutter/material.dart';
import 'loginscreen.dart';

class Survey6 extends StatefulWidget {
  final String nickname;
  final int characterIndex;
  final List<int> environmentIndices;
  final List<int> purposeIndices;
  final List<int> timeIndices;
  const Survey6({Key? key, required this.nickname, required this.characterIndex, required this.environmentIndices, required this.purposeIndices, required this.timeIndices}) : super(key: key);

  @override
  _Survey6State createState() => _Survey6State();
}

class _Survey6State extends State<Survey6> {
  final List<String> items = ['반려동물 산책 가능 장소', '포토 스팟', '벤치, 쉼터', '화장실 근처', '없음'];
  List<int> _selectedIndices = [];

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          nickname: widget.nickname,
          characterIndex: widget.characterIndex,
          environmentIndices: widget.environmentIndices,
          purposeIndices: widget.purposeIndices,
          timeIndices: widget.timeIndices,
          featureIndices: _selectedIndices,
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
                  tween: Tween<double>(begin: 0.833, end: 1.0),
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
              )),

          // 2. 텍스트와 버튼
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
            left: MediaQuery.of(context).size.height * 0.025,
            right: MediaQuery.of(context).size.height * 0.025,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'STEP 3',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF707070),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '산책 시 선호하는 요소를 골라주세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 50),
                Column( // 전체 버튼 그룹을 Column으로 묶습니다.
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // 첫 번째 텍스트 버튼만 포함하는 Wrap
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: [
                        _buildChoiceButton(context, items[0], 0), // 첫 번째 아이템
                      ],
                    ),
                    const SizedBox(height: 10), // 첫 번째 줄과 다음 줄 사이 간격

                    // 나머지 텍스트 버튼들을 포함하는 Wrap
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: items.sublist(1).map((item) { // 첫 번째 아이템 제외한 나머지
                        int index = items.indexOf(item);
                        return _buildChoiceButton(context, item, index);
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. 다음 단계 버튼
          Positioned(
            top: MediaQuery.of(context).size.height * 0.85,
            right: MediaQuery.of(context).size.width * 0.10,
            child: FloatingActionButton(
              onPressed: _selectedIndices.isNotEmpty ? () {
                _saveSelectionAndNavigate(context);
              } : null,
              elevation: 0,
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: _selectedIndices.isNotEmpty ? const Color(0xFFBFE240) : Color(0x80BFE240),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context, String item, int index) {
    final isSelected = _selectedIndices.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          final noneButtonIndex = 4;
          if (index == noneButtonIndex) {
            // '없음' 버튼을 탭한 경우
            _selectedIndices.clear(); // 모든 선택 해제
            if (!isSelected) {
              _selectedIndices.add(index); // '없음'만 선택
            }
          } else {
            // '없음' 외 다른 버튼을 탭한 경우
            _selectedIndices.remove(noneButtonIndex); // '없음' 선택 해제

            if (isSelected) {
              _selectedIndices.remove(index); // 이미 선택된 항목이면 해제
            } else {
              _selectedIndices.add(index); // 선택되지 않은 항목이면 추가
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
          color: isSelected ? const Color(0x28BFE240) : const Color(0xFFFFFFFF),
          border: Border.all(
            color: isSelected ? Color(0xFFBFE240) : Color(0xFFDDD7D7),
            width: 1.4,
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min, // 텍스트 길이에 맞춰 너비 조절
          children: [
            Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}