import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walky/services/onboarding_flow.dart';
import 'services/firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_manager.dart';
import 'services/firebase_db.dart'; // walkydb 전용 db
import 'services/user_decider.dart'; // 판단 로직 가져오기

import 'onboarding_1.dart';
import 'main_page.dart';
import 'survey_1.dart';
import 'survey_2.dart';

// dart run flutter_native_splash:remove
// dart run flutter_native_splash:create

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // 앱이 준비될 때까지 스플래시 화면을 계속 유지하겠다고 선언

  // firebase 관련 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 앱 이니셜라이저 설정
  // : 기본적으로 Flutter에서 첫 프레임을 그리기 시작할 때 Splash Screen은 제거됨
  // 만약 앱이 초기화되는 동안에 Splash Screen을 유지하려면 preserve() 또는 remove() 메서드를 같이 사용하면 됨

  final bool isFirstLaunch = await isFirstRun();

  FlutterNativeSplash.remove(); // Splash 제거
  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}



class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({
    super.key,
    required this.isFirstLaunch
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WALKY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 214, 212, 182),
        ),
        useMaterial3: true,
      ),
      home: const Survey1(),
    );
  }
}