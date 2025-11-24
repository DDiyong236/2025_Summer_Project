import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ⭐️ ScreenUtil 임포트 필수
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'main_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/google_auth_service.dart';

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

  // ----------------------------------------------------------------------
  // 로그인 로직 (기존 유지)
  // ----------------------------------------------------------------------

  Future<void> _signInWithGoogle(BuildContext context) async {
    final AuthService _authService = AuthService();
    await _authService.signInWithGoogle().then((_) async {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => MainPage(
              nickname: nickname,
              characterIndex: characterIndex,
              environmentIndices: environmentIndices,
              purposeIndices: purposeIndices,
              timeIndices: timeIndices,
              featureIndices: featureIndices,
            )),
      );
    }).catchError((error) {});
  }

  Future<void> _signInWithKakao(BuildContext context) async {
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        await kakao.UserApi.instance
            .loginWithKakaoTalk()
            .then((kakao.OAuthToken token) async {
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
                  )),
            );
          }
        }).catchError((error) {});
      } catch (error) {
        try {
          await kakao.UserApi.instance
              .loginWithKakaoAccount()
              .then((kakao.OAuthToken token) async {
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
                    )),
              );
            }
          }).catchError((Error) {});
        } catch (e) {}
      }
    } else {
      try {
        kakao.OAuthToken token =
        await kakao.UserApi.instance.loginWithKakaoAccount();
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
                )),
          );
        }
      } catch (e) {}
    }
  }

  Future<User?> _signInWithKakaoToken(String accessToken) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('kakaoLogin');
      final result = await callable.call({'accessToken': accessToken});
      final customToken = result.data['customToken'];
      final credential =
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return credential.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _signInWithNaver(BuildContext context) async {
    try {
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      if (res.status == NaverLoginStatus.loggedIn) {
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
                  )),
            );
          }
        }
      }
    } catch (e) {}
  }

  Future<User?> _signInWithNaverToken(String accessToken) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('naverLogin');
      final result = await callable.call({'accessToken': accessToken});

      final customToken = result.data['customToken'];
      final credential =
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      return credential.user;
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // 화면 UI 구성
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ⭐️ [수정 1] 태블릿 호환을 위해 Positioned로 위치 고정 (왼쪽 캐릭터)
          Positioned(
            left: -30.w, // 왼쪽으로 살짝 숨기거나 조절 가능 (필요시 0으로 변경)
            bottom: 0.15.sh, // 바닥에서 15% 위로
            child: Image.asset(
              'assets/img/login_character_2.png',
              height: 0.55.sh, // 화면 높이의 55%
              fit: BoxFit.contain,
            ),
          ),

          // ⭐️ [수정 2] 태블릿 호환을 위해 Positioned로 위치 고정 (오른쪽 캐릭터)
          Positioned(
            right: -20.w, // 오른쪽으로 살짝 붙임
            top: 0.12.sh, // 천장에서 12% 아래로
            child: Image.asset(
              'assets/img/login_character_1.png',
              height: 0.55.sh,
              fit: BoxFit.contain,
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 0.1.sh),
                const Text(
                  '산책 시작을 위해\n로그인이 필요해요!',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // 버튼들
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
                SizedBox(height: 12.h), // 간격 살짝 줄임 (16 -> 12)
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
                SizedBox(height: 12.h),
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
                SizedBox(height: 50.h),
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
          borderRadius: BorderRadius.circular(50.0.r),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        // ⭐️ [수정 3] 버튼 두께를 얇게 조절 (13 -> 10)
        padding: EdgeInsets.symmetric(vertical: 10.0.h),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            // ⭐️ [수정 4] 아이콘 크기 축소 (24 -> 20)
            height: 20.h,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              // ⭐️ [수정 5] 텍스트 크기 축소 (16 -> 14)
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}