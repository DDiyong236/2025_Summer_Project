import 'package:flutter/material.dart';
import 'survey_5.dart';

class Survey4 extends StatefulWidget {
  const Survey4({Key? key}) : super(key: key);

  @override
  _Survey4State createState() => _Survey4State();
}

class _Survey4State extends State<Survey4> {
  final List<String> items = ['기분 전환 및 스트레스 해소', '운동 및 건강 관리', '사진 및 기록', '사색 및 아이디어 얻기'];
  int? selectedIndex;

  void _saveSelectionAndNavigate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Survey5(),
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
                  tween: Tween<double>(begin: 0.5, end: 0.667),
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
              )),

          // 2. 텍스트와 리스트뷰
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
                  '산책을 하는 목적을 알려주세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            child: Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40.0),
                                color: isSelected ? const Color(0x28BFE240) : const Color(0xFFFFFFFF),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // 상자 크기를 자식 위젯에 맞춤
                                children: [
                                  Text(
                                    items[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Image.asset(
                                    'assets/img/walk_purpose_${index + 1}.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: selectedIndex != null ? const Color(0xFFBFE240) : Colors.grey,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}