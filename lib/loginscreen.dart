import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 왼쪽 캐릭터 이미지
          Align(
            alignment: Alignment(-1.0,0.3),
            child: Image.asset(
              'assets/img/login_character_2.png',
              height: screenHeight * 0.55,
            ),
          ),
          // 오른쪽 캐릭터 이미지
          Align(
            alignment: Alignment(1.0,-0.25),
            child: Image.asset(
              'assets/img/login_character_1.png',
              height: screenHeight * 0.55,
            ),
          ),

          // 텍스트와 버튼을 배치하는 Column
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.1),
                const Text(
                  '산책 시작을 위해\n로그인이 필요해요!',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSocialLoginButton(
                  context,
                  imagePath: 'assets/img/kakao_logo.png',
                  text: '카카오 계정으로 시작하기',
                  backgroundColor: const Color(0xFFFFE500),
                  textColor: Colors.black,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                  context,
                  imagePath: 'assets/img/naver_logo.png',
                  text: '네이버 계정으로 시작하기',
                  backgroundColor: const Color(0xFF03C75A),
                  textColor: Colors.white,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                  context,
                  imagePath: 'assets/img/google_logo.png',
                  text: '구글 계정으로 시작하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black54,
                  borderColor: Colors.grey.shade300,
                  onPressed: () {},
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButton(
      BuildContext context, {
        required String imagePath,
        required String text,
        required Color backgroundColor,
        required Color textColor,
        Color? borderColor,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
          side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13.0),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 24,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}