import 'package:flutter/material.dart';
import 'survey_2.dart'; // ✨ Survey2 클래스를 가져옵니다.

class Survey1 extends StatefulWidget {
  const Survey1({Key? key}) : super(key: key);

  @override
  _Survey1State createState() => _Survey1State();
}

class _Survey1State extends State<Survey1> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Positioned(
                  top: 54.0,
                  left: 41.0,
                  right: 41.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    child: LinearProgressIndicator(
                      value: 0.167,
                      minHeight: 10.0,
                      backgroundColor: Color(0xFFF5F5F5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFBFE240),
                      ),
                    ),
                  )
              ),

              // 2. 텍스트와 입력 필드
              Positioned(
                top: 120.0,
                left: 20.0,
                right: 20.0,
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
                    const SizedBox(height: 30),
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Color(0xFFDDD7D7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Color(0xFFDDD7D7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide(color: Color(0xFFDDD7D7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: const Text(
                        '한글 또는 영문만 사용하여 2~12자로 입력해주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // 3. 다음 단계 버튼
              Positioned(
                top: MediaQuery.of(context).size.height * 0.85,
                right: MediaQuery.of(context).size.width * 0.10,
                child: FloatingActionButton(
                  onPressed: () {
                    // ✨ 버튼을 누르면 다음 화면(Survey2)으로 이동하는 로직입니다.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Survey2(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  backgroundColor: Color(0xFFBFE240),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
    );
  }
}