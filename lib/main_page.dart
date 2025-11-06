import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_manager.dart'; // UserProfileService import

class MainPage extends StatefulWidget {
  // LoginScreen에서 넘겨받은 초기 데이터
  final String nickname;
  final int characterIndex;
  final List<int> environmentIndices;
  final List<int> purposeIndices;
  final List<int> timeIndices;
  final List<int> featureIndices;

  const MainPage({
    super.key,
    required this.nickname,
    required this.characterIndex,
    required this.environmentIndices,
    required this.purposeIndices,
    required this.timeIndices,
    required this.featureIndices,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final UserProfileService _userProfileService = UserProfileService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // ⭐️ MainPage 진입 시 UID로 프로필 확인 및 저장 시도 ⭐️
    if (currentUser != null) {
      _checkAndSaveInitialProfile(currentUser!.uid);
    }
  }

  Future<void> _checkAndSaveInitialProfile(String uid) async {
    try {
      final existingProfile = await _userProfileService.fetchProfile(uid);

      if (existingProfile == null) {
        // 프로필이 없다면, 즉 최초 로그인이라면 설문 데이터를 저장합니다.
        final surveyResults = {
          'environmentIndex': widget.environmentIndices,
          'purposeIndex': widget.purposeIndices,
          'timeIndex': widget.timeIndices,
          'featureIndex': widget.featureIndices,
        };

        await _userProfileService.createORUpdateProfile(
          nickname: widget.nickname,
          character: widget.characterIndex,
          survey: surveyResults,
          isCreate: true,
        );
        // print("최초 프로필 및 설문 데이터 저장 완료");
      } else {
        // 이미 프로필이 있다면 별도 처리 없이 넘어갑니다.
        // print("기존 프로필 확인 완료");
      }
    } catch (e) {
      // print("프로필 확인/저장 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("로그인 정보가 없습니다. (Auth 에러)")),
      );
    }

    // ⭐️ StreamBuilder를 사용하여 데이터 불러오기 ⭐️
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _userProfileService.watchProfile(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('데이터 로딩 오류: ${snapshot.error}'));
          }

          final UserProfile? profile = snapshot.data;

          if (profile == null) {
            return const Center(child: Text("프로필 데이터를 불러오는 중..."));
          }

          // 데이터가 성공적으로 불러와졌다면 표시
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("이곳은 기존 사용자 메인 페이지입니다.", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                Text("환영합니다, ${profile.nickname}님!"),
                Text("사용자 UID: ${profile.uid}"),
                Text("캐릭터 번호: ${profile.character}"),
                Text("설문 인덱스 (목적): ${profile.survey['purposeIndex']}"),
                // 필요한 다른 프로필 정보나 위젯을 여기에 추가
              ],
            ),
          );
        },
      ),
    );
  }
}