import 'package:shared_preferences/shared_preferences.dart';

Future<bool> checkIsFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  bool? firstRun = prefs.getBool('isFirstRun');

  if (firstRun == null || firstRun == true) {
    await prefs.setBool('isFirstRun', false); // 최초 실행 이후 false로 저장
    return true; // 최초 실행
  } else {
    return false; // 최초 실행 아님
  }
}
