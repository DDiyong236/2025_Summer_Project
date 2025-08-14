import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'services/firebase_options.dart';

import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_manager.dart';
import 'services/firebase_db.dart'; // ✅ walkydb 전용 db
import 'services/UserDecider.dart'; // 판단 로직 가져오기

import 'Onboarding_1.dart';
import 'mainPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // is ExistingUser : 어떤 유저인지를 판단하는 bool 변수
  // -> true =
  // checkUserStatus() 함수는 UserDecider.dart 파일에서 정의해야 하는 함수
  // -> 현재 사용자가 이미 앱을 사용하고 있던 유저인지, 앱을 처음 설치한 다운로더인지 반단하는 함수
  bool isExistingUser = await checkUserStatus();

  runApp(MyApp(isExistingUser: isExistingUser));
}

class MyApp extends StatelessWidget {
  final bool isExistingUser; // 필드 선언

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

