import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walky/services/onboarding_flow.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_manager.dart';
import 'services/firebase_db.dart';
import 'services/user_decider.dart';
import 'services/firebase_options.dart';
import 'package:flutter/foundation.dart';

import 'onboarding_1.dart';
import 'main_page.dart';
import 'survey_1.dart';
import 'survey_2.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  if (kDebugMode) {
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      print('앱체크: $token');
    });
  } else {
    print('에러');
  }

  KakaoSdk.init(nativeAppKey: "2f2c5202737e8642eed0968928895634");

  final bool isFirstLaunch = await isFirstRun();

  FlutterNativeSplash.remove();
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
    return ScreenUtilInit(
      // 보통 피그마 기준 (360, 690) 또는 (375, 812)를 많이 씁니다.
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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
      },
    );
  }
}