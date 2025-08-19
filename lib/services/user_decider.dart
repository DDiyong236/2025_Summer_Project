import 'package:shared_preferences/shared_preferences.dart';

const _kFirstRunKey = 'isFirstRun';

/// returns true if this is the very first launch after install.
/// sets the flag to false immediately after detecting first run.
Future<bool> isFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  final first = prefs.getBool(_kFirstRunKey) ?? true;
  if (first) {
    await prefs.setBool(_kFirstRunKey, false);
  }
  return first;
}