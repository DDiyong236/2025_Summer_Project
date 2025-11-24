import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// ----------- 환경: 에뮬레이터/실기기에 맞춰 바꾸세요 -----------
const String kApiBase =
//String.fromEnvironment('API_BASE', defaultValue: 'http://172.31.64.116:5123');
//String.fromEnvironment('API_BASE', defaultValue: 'http://192.168.0.16:5123'); // 학교 주소
String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5123'); // 학교 주소

// Android 에뮬레이터: 10.0.2.2, iOS 시뮬레이터: http://127.0.0.1:5123,
// 실기기: http://<PC-LAN-IP>:5123
/// ------------------------------------------------------------

class RouteResponse {
  final bool ok;
  final List<List<double>> line; // [ [lon,lat], ... ]
  final Map<String, dynamic>? start;
  final Map<String, dynamic>? dest;
  final List<dynamic>? vias;
  final num? distanceM;
  final num? durationS;
  final num? durationSEval;
  final String? targetMode;
  final String? error;

  RouteResponse({
    required this.ok,
    required this.line,
    this.start,
    this.dest,
    this.vias,
    this.distanceM,
    this.durationS,
    this.durationSEval,
    this.targetMode,
    this.error,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final rawLine = (json['line'] as List?) ?? const [];
    final line = rawLine
        .map<List<double>>((e) => [(e[0] as num).toDouble(), (e[1] as num).toDouble()])
        .toList();

    return RouteResponse(
      ok: json['ok'] == true,
      line: line,
      start: json['start'] as Map<String, dynamic>?,
      dest: json['dest'] as Map<String, dynamic>?,
      vias: json['vias'] as List?,
      distanceM: json['distance_m'] as num?,
      durationS: json['duration_s'] as num?,
      durationSEval: json['duration_s_eval'] as num?,
      targetMode: json['target_mode'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'line': line,
    'start': start,
    'dest': dest,
    'vias': vias,
    'distance_m': distanceM,
    'duration_s': durationS,
    'duration_s_eval': durationSEval,
    'target_mode': targetMode,
    'error': error,
  };
}

class ApiService{
  static const String apiUrl = kApiBase;

  static Future<RouteResponse> recommend(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$apiUrl/api/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || (json['ok'] != true)) {
      throw Exception(json['error'] ?? 'HTTP ${res.statusCode}');
    }
    return RouteResponse.fromJson(json);
  }
}
