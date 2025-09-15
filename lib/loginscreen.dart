import 'package:flutter/material.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:walky/services/firestore_manager.dart';
import 'package:walky/services/google_auth_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'main_page.dart';
import 'services/firebase_db.dart';
import 'services/firebase_storage_manager.dart';

class LoginScreen extends StatelessWidget {
  final String nickname;
  final int characterIndex;
  final int environmentIndex;
  final int purposeIndex;
  final int timeIndex;
  final int featureIndex;
  const LoginScreen({super.key, required this.nickname, required this.characterIndex, required this.environmentIndex, required this.purposeIndex, required this.timeIndex, required this.featureIndex});


  Future<void> _saveSurveyData() async{
    final UserProfileService _userProfileService = UserProfileService();
    final surveyResults = {
      'environmentIndex': environmentIndex,
      'purposeIndex': purposeIndex,
      'timeIndex': timeIndex,
      'featureIndex': featureIndex,
    };
    try{
      await _userProfileService.createORUpdateProfile(
        nickname: nickname,
        character: characterIndex,
        survey: surveyResults,
        isCreate: true,
      );
      print("설문 데이터가 성공적으로 저장되었습니다.");
    }catch(e){
      print("데이터 저장중 오류 발생: $e");
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final AuthService _authService = AuthService();
    await _authService.signInWithGoogle()
        .then((_) async{
      // 로그인 성공
      await _saveSurveyData();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()), // 예시
      );
    })
        .catchError((error) {
      // 로그인 실패
      print('로그인 실패: $error');
    });
  }
  Future<void> _signInWithKakao(BuildContext context) async {
    if (await isKakaoTalkInstalled()) {
      try {
        // 카카오톡 로그인 시도
        await UserApi.instance.loginWithKakaoTalk().
            then((_) async{
              await _saveSurveyData();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainPage()),
              );
        }).catchError((error){
          print("로그인 실패 $error");
        });
      } catch (error) {
        print('카카오톡 로그인 실패: $error');
        // 실패 시, 웹 로그인 시도
        try {
          await UserApi.instance.loginWithKakaoAccount()
          .then((_) async{
            await _saveSurveyData();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          }).catchError((Error){
            print("로그인 실패 $Error");
          });
        } catch (e) {
        }
      }
    } else {
      // 카카오톡 미설치 시 웹으로 로그인
      try {
        await UserApi.instance.loginWithKakaoAccount();
        User user = await UserApi.instance.me();
        print('카카오 계정 로그인 성공: ${user.kakaoAccount?.profile?.nickname}');
        await _saveSurveyData();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } catch (e) {
        print("카카오 계정 로그인 실패 $e");
      }
    }
  }

  Future<void> _signInWithNaver(BuildContext context) async{
    try{
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      if(res.status == NaverLoginStatus.loggedIn){
        await _saveSurveyData();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }else{
        print("로그인 실패: ${res.errorMessage}");
      }
    }catch(e){
      print("로그인중 오류 발생: $e");
    }
  }

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
                  imagePath: 'assets/img/kakao_icons.png',
                  text: '카카오 계정으로 시작하기',
                  backgroundColor: const Color(0xFFFEE500),
                  textColor: Color(0xDA000000),
                  onPressed: () {
                    _signInWithKakao(context);
                  },
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                  context,
                  imagePath: 'assets/img/naver_logo.png',
                  text: '네이버 계정으로 시작하기',
                  backgroundColor: const Color(0xFF03C75A),
                  textColor: Colors.white,
                  onPressed: () {
                    _signInWithNaver(context);
                  },
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                  context,
                  imagePath: 'assets/img/google_logo.png',
                  text: '구글 계정으로 시작하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black54,
                  borderColor: Colors.grey.shade300,
                  onPressed: () {
                    _signInWithGoogle(context);
                  },
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