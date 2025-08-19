import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'services/firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_manager.dart';
import 'services/firebase_db.dart'; // walkydb 전용 db
import 'services/UserDecider.dart'; // 판단 로직 가져오기

import 'Onboarding_1.dart';
import 'mainPage.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 앱 이니셜라이저 설정
  // : 기본적으로 Flutter에서 첫 프레임을 그리기 시작할 때 Splash Screen은 제거됨
  // 만약 앱이 초기화되는 동안에 Splash Screen을 유지하려면 preserve() 또는 remove() 메서드를 같이 사용하면 됨


  final bool isExistingUser; // 필드 선언
  isExistingUser = await checkIsFirstRun();

  FlutterNativeSplash.remove(); // Splash 제거
  runApp(MyApp(isExistingUser: isExistingUser));
}

class MyApp extends StatelessWidget {
  final bool isExistingUser;
  const MyApp({
    super.key,
    required this.isExistingUser
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walky',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 214, 212, 182),
        ),
        useMaterial3: true,
      ),
      home: isExistingUser ? const MainPage() : const Onboarding_1(),
    );
  }
}

