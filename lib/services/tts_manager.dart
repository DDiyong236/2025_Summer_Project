import 'package:flutter_tts/flutter_tts.dart';
class TTSManager {
  final FlutterTts _tts = FlutterTts();

  TTSManager() {
    // 기본 설정
    _tts.setLanguage("ko-KR");
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);

    _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }

  // 옵션 변경용 헬퍼(원하면 사용)
  Future<void> setLanguage(String lang) => _tts.setLanguage(lang);
  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);
}