import 'package:flutter/material.dart';
import 'survey_6.dart';

class Survey5 extends StatefulWidget {
  final String nickname;
  final int characterIndex;
  final int environmentIndex;
  final int purposeIndex;
  const Survey5({Key? key, required this.nickname, required this.characterIndex, required this.environmentIndex, required this.purposeIndex}) : super(key: key);

  @override
  _Survey5State createState() => _Survey5State();
}

class _Survey5State extends State<Survey5> {
  final List<String> items = ['10분 이내', '10분 - 30분', '30분 - 1시간', '1시간 - 2시간','2시간 - 3시간','3시간 이상'];
  int? selectedIndex;

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Survey6(
          nickname: widget.nickname,
          characterIndex: widget.characterIndex,
          environmentIndex: widget.environmentIndex,
          purposeIndex: widget.purposeIndex,
          timeIndex: selectedIndex!,
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
                  tween: Tween<double>(begin: 0.667, end: 0.833),
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

          // 2. 텍스트와 Wrap 위젯
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
                  '적당한 산책 시간을 알려주세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Wrap(
                    spacing: 10.0, // 상자들 사이의 가로 간격
                    runSpacing: 15.0, // 상자들 사이의 세로 간격
                    children: items.map((item) {
                      int index = items.indexOf(item);
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40.0),
                            color: isSelected ? const Color(0x33BFE240) : const Color(0xFFFFFFFF),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFBFE240) : Color(0xFFDDD7D7),
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // 상자 크기를 자식 위젯에 맞춤
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
                    }).toList(),
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
              onPressed: selectedIndex != null ? () {
                _saveSelectionAndNavigate(context);
              } : null,
              elevation: 0,
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: selectedIndex != null ? const Color(0xFFBFE240) : Color(0x80BFE240),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}