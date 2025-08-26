import 'package:flutter/material.dart';

class Survey2 extends StatefulWidget {
  const Survey2({Key? key}) : super(key: key);

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

  final TextEditingController _nicknameController = TextEditingController();
  int? _selectedIndex;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _saveSelectionToDatabase(int index) {
    print('선택된 캐릭터 인덱스: $index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 54.0,
            left: 41.0,
            right: 41.0,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              child: LinearProgressIndicator(
                value: 0.334,
                minHeight: 10.0,
                backgroundColor: const Color(0xFFF5F5F5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFBFE240),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120.0,
            left: 20.0,
            right: 20.0,
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 25.0, // 상자와 텍스트를 포함한 전체 위젯 간의 수직 간격
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    // ✨ 상자와 텍스트를 별도의 Column으로 묶었습니다.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded( // 상자가 남은 공간을 차지하도록 Expanded 추가
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _selectedIndex == index
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: 3.0,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(_characterImages[index]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // 상자와 텍스트 사이 간격
                        Text(
                          _characterNames[index], // ✨ 상자 바깥에 텍스트를 배치
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.85,
            right: MediaQuery.of(context).size.width * 0.10,
            child: FloatingActionButton(
              onPressed: () {
                if (_selectedIndex != null) {
                  _saveSelectionToDatabase(_selectedIndex!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('캐릭터를 선택해주세요.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              backgroundColor: const Color(0xFFBFE240),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}