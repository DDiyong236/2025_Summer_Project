import 'package:flutter/material.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'main_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/google_auth_service.dart';

// services/firebase_db.dart와 services/firestore_manager.dart, services/firebase_storage_manager.dart는
// LoginScreen에서 직접 사용하지 않으므로, 원래 코드의 import 목록에서 사용하지 않는 것들은 제거했습니다.

class LoginScreen extends StatelessWidget {
  final String nickname;
  final int characterIndex;
  final List<int> environmentIndices;
  final List<int> purposeIndices;
  final List<int> timeIndices;
  final List<int> featureIndices;
  const LoginScreen({
    super.key,
    required this.nickname,
    required this.characterIndex,
    required this.environmentIndices,
    required this.purposeIndices,
    required this.timeIndices,
    required this.featureIndices,
  });

  Future<void> _signInWithGoogle(BuildContext context) async {
    final AuthService _authService = AuthService();
    await _authService.signInWithGoogle()
        .then((_) async{
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => MainPage(
              nickname: nickname,
              characterIndex: characterIndex,
              environmentIndices: environmentIndices,
              purposeIndices: purposeIndices,
              timeIndices: timeIndices,
              featureIndices: featureIndices,
            )
        ),
      );
    })
        .catchError((error) {});
  }

  Future<void> _signInWithKakao(BuildContext context) async {
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        await kakao.UserApi.instance.loginWithKakaoTalk().
        then((kakao.OAuthToken token) async{
          final firebaseUser = await _signInWithKakaoToken(token.accessToken);
          if(firebaseUser != null){
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => MainPage(
                    nickname: nickname,
                    characterIndex: characterIndex,
                    environmentIndices: environmentIndices,
                    purposeIndices: purposeIndices,
                    timeIndices: timeIndices,
                    featureIndices: featureIndices,
                  )
              ),
            );
          }
        }).catchError((error){});
      } catch (error) {
        try {
          await kakao.UserApi.instance.loginWithKakaoAccount()
              .then((kakao.OAuthToken token) async{
            final firebaseUser = await _signInWithKakaoToken(token.accessToken);
            if (firebaseUser != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => MainPage(
                      nickname: nickname,
                      characterIndex: characterIndex,
                      environmentIndices: environmentIndices,
                      purposeIndices: purposeIndices,
                      timeIndices: timeIndices,
                      featureIndices: featureIndices,
                    )
                ),
              );
            }
          }).catchError((Error){});
        } catch (e) {}
      }
    } else {
      try {
        kakao.OAuthToken token = await kakao.UserApi.instance.loginWithKakaoAccount();
        final firebaseUser = await _signInWithKakaoToken(token.accessToken);
        if (firebaseUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => MainPage(
                  nickname: nickname,
                  characterIndex: characterIndex,
                  environmentIndices: environmentIndices,
                  purposeIndices: purposeIndices,
                  timeIndices: timeIndices,
                  featureIndices: featureIndices,
                )
            ),
          );
        }
      } catch (e) {}
    }
  }

  Future<User?> _signInWithKakaoToken(String accessToken) async{
    try{
      final callable = FirebaseFunctions.instance.httpsCallable('kakaoLogin');
      final result = await callable.call({'accessToken': accessToken});
      final customToken = result.data['customToken'];
      final credential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return credential.user;
    }catch(e){
      return null;
    }
  }

  Future<void> _signInWithNaver(BuildContext context) async{
    try{
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      if(res.status == NaverLoginStatus.loggedIn){
        final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();

        if (token.accessToken != null) {
          final firebaseUser = await _signInWithNaverToken(token.accessToken);
          if (firebaseUser != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => MainPage(
                    nickname: nickname,
                    characterIndex: characterIndex,
                    environmentIndices: environmentIndices,
                    purposeIndices: purposeIndices,
                    timeIndices: timeIndices,
                    featureIndices: featureIndices,
                  )
              ),
            );
          }
        }
      }
    }catch(e){
    }
  }

  Future<User?> _signInWithNaverToken(String accessToken) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('naverLogin');
      final result = await callable.call({'accessToken': accessToken});

      final customToken = result.data['customToken'];
      final credential = await FirebaseAuth.instance.signInWithCustomToken(customToken);

      return credential.user;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(-1.0,0.3),
            child: Image.asset(
              'assets/img/login_character_2.png',
              height: screenHeight * 0.55,
            ),
          ),
          Align(
            alignment: const Alignment(1.0,-0.25),
            child: Image.asset(
              'assets/img/login_character_1.png',
              height: screenHeight * 0.55,
            ),
          ),
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
                  textColor: const Color(0xDA000000),
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