// lib/route_map_page.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'dart:io' show Platform;

// import 'package:walky/services/firebase_storage_manager.dart'; // 더 이상 필요 없음

/// ----------- 환경: 에뮬레이터/실기기에 맞춰 바꾸세요 -----------
const String kApiBase =
String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5123');
// Android 에뮬레이터: 10.0.2.2, iOS 시뮬레이터: http://127.0.0.1:5123,
// 실기기: http://<PC-LAN-IP>:5123
/// ------------------------------------------------------------

// ⭐️ jsonFileUrl 매개변수 제거
class KakaoRouteFlutterPage extends StatefulWidget {
  const KakaoRouteFlutterPage({super.key});

  @override
  State<KakaoRouteFlutterPage> createState() => _KakaoRouteFlutterPageState();
}

/// 서버 응답 모델 (HTML 스펙에 맞춤)
class RouteResponse {
  final bool ok;
  final List<List<double>> line; // [ [lon,lat], ... ]
  final Map<String, dynamic>? start;
  final Map<String, dynamic>? dest;
  final List<dynamic>? vias;
  final int? distanceM;
  final int? durationS;
  final String? error;
  RouteResponse({
    required this.ok,
    required this.line,
    this.start,
    this.dest,
    this.vias,
    this.distanceM,
    this.durationS,
    this.error,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final rawLine = (json['line'] as List?) ?? const [];
    final line = rawLine
        .map<List<double>>(
          (e) => [(e[0] as num).toDouble(), (e[1] as num).toDouble()],
    )
        .toList();
    return RouteResponse(
      ok: json['ok'] == true,
      line: line,
      start: json['start'] as Map<String, dynamic>?,
      dest: json['dest'] as Map<String, dynamic>?,
      vias: json['vias'] as List?,
      distanceM: (json['distance_m'] as num?)?.toInt(),
      durationS: (json['duration_s'] as num?)?.toInt(),
      error: json['error'] as String?,
    );
  }
}

class _KakaoRouteFlutterPageState extends State<KakaoRouteFlutterPage> {
  // ---------- UI 상태 ----------
  String tag = 'cafe';
  int _zoomLevel = 6;
  bool _panelOpen = true;
  final startCtrl = TextEditingController(text: '죽전역');
  final destCtrl = TextEditingController(text: '오리역');

  // cafe 옵션
  int cafeCount = 1;
  int searchRadius = 400;
  String targetKmText = '';
  double toleranceRatio = 0.1;
  String randomSeedText = '';

  // river 옵션
  int numVias = 3;

  // ---------- 지도 컨트롤러 ----------
  KakaoMapController? _map;

  late final PoiStyle _poiStyle;

  bool _loading = false;
  String? _errorText;
  String _status = '준비됨';
  String _summary = '';

  @override
  void initState() {
    super.initState();
    _poiStyle = PoiStyle(
      icon: KImage.fromAsset('assets/image/location.png', 40, 60),
    );
  }

  @override
  void dispose() {
    startCtrl.dispose();
    destCtrl.dispose();
    super.dispose();
  }

  // ⭐️ API 요청으로 경로를 가져오는 함수로 변경
  Future<void> _requestRoute() async {
    if (_map == null) return;
    setState(() { _loading = true; _errorText = null; _status = '요청 중…'; _summary = ''; });

    final body = <String, dynamic>{
      'tag': tag,
      'start_text': startCtrl.text.trim(),
      'dest_text': destCtrl.text.trim(),
    };
    if (tag == 'cafe') {
      body.addAll({
        'cafe_count': cafeCount,
        'search_radius': searchRadius,
        if (targetKmText.isNotEmpty) 'target_km': double.tryParse(targetKmText),
        'tolerance_ratio': toleranceRatio,
        if (randomSeedText.isNotEmpty) 'random_seed': int.tryParse(randomSeedText),
      });
    } else {
      body['num_vias'] = numVias;
    }

    try {
      final res = await http.post(
        Uri.parse('$kApiBase/api/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = RouteResponse.fromJson(json);

      if (res.statusCode != 200 || !data.ok) {
        throw Exception(data.error ?? 'HTTP ${res.statusCode}');
      }

      await _renderOnMap(data);

      final km = (data.distanceM ?? 0) / 1000.0;
      final min = ((data.durationS ?? 0) / 60).round();
      setState(() {
        _status = '완료';
        _summary =
        '거리: ${km.toStringAsFixed(2)} km | 예상시간: ${min}분\n'
            '출발: ${data.start?['name'] ?? '-'} / 도착: ${data.dest?['name'] ?? '-'}';
      });
    } catch (e) {
      setState(() { _errorText = '⚠️ ${e.toString()}'; _status = '실패'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _renderOnMap(RouteResponse data) async {
    if (_map == null) return;

    await _map!.labelLayer.hideAllPoi();
    await _map!.routeLayer.hideAllRoute();

    final coords = data.line.map((e) => LatLng(e[1], e[0])).toList();

    if (coords.isNotEmpty) {
      await _map!.routeLayer.addRoute(
        coords,
        RouteStyle(Colors.blue, 8),
      );

      double minLat = double.infinity, maxLat = -double.infinity,
          minLon = double.infinity, maxLon = -double.infinity;
      for (final p in coords) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLon = math.min(minLon, p.longitude);
        maxLon = math.max(maxLon, p.longitude);
      }
      final center = LatLng((minLat + maxLat) / 2.0, (minLon + maxLon) / 2.0);
      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(center),
        animation: const CameraAnimation(600),
      );
    }

    Future<void> addPoi(double lat, double lon) async {
      try {
        await _map!.labelLayer.addPoi(
          LatLng(lat, lon),
          style: _poiStyle,
        );
      } catch (e) {
        debugPrint('addPoi failed: $e');
      }
    }

    if (data.start != null) {
      await addPoi(
        (data.start!['lat'] as num).toDouble(),
        (data.start!['lon'] as num).toDouble(),
      );
    }
    if (data.dest != null) {
      await addPoi(
        (data.dest!['lat'] as num).toDouble(),
        (data.dest!['lon'] as num).toDouble(),
      );
    }
    if (data.vias != null) {
      for (final vAny in data.vias!) {
        final v = vAny as Map<String, dynamic>;
        await addPoi(
          (v['lat'] as num).toDouble(),
          (v['lon'] as num).toDouble(),
        );
      }
    }

    await _map!.labelLayer.showAllPoi();
    await _map!.routeLayer.showAllRoute();
  }

  void _clear() async {
    if (_map == null) return;
    await _map!.labelLayer.hideAllPoi();
    await _map!.routeLayer.hideAllRoute();
    setState(() { _status = '초기화됨.'; _errorText = null; _summary = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 600;
    final panelWidth = math.min(360.0, size.width * 0.92);

    final leftPanel = SizedBox(
      width: panelWidth,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              const Text('산책 경로 추천', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Text('Flutter × Kakao Map', style: TextStyle(color: Color(0xFF9A3412), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: tag,
            items: const [
              DropdownMenuItem(value: 'cafe', child: Text('카페 경유')),
              DropdownMenuItem(value: 'river', child: Text('하천(탄천) 경로')),
            ],
            onChanged: (v) => setState(() => tag = v ?? 'cafe'),
            decoration: const InputDecoration(labelText: '태그', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: startCtrl,
            decoration: const InputDecoration(labelText: '출발지', hintText: '예: 죽전역', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: destCtrl,
            decoration: const InputDecoration(labelText: '도착지', hintText: '예: 오리역', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          if (tag == 'cafe') ...[
            Row(children: [
              Expanded(child: _numField('카페 개수', cafeCount.toString(), (v) => setState(() => cafeCount = int.tryParse(v) ?? 1))),
              const SizedBox(width: 8),
              Expanded(child: _numField('검색 반경(m)', searchRadius.toString(), (v) => setState(() => searchRadius = int.tryParse(v) ?? 400))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _numField('목표 거리(km)', targetKmText, (v) => setState(() => targetKmText = v), hint: '비우면 랜덤')),
              const SizedBox(width: 8),
              Expanded(child: _numField('허용 오차', toleranceRatio.toString(), (v) => setState(() => toleranceRatio = double.tryParse(v) ?? 0.1))),
            ]),
            const SizedBox(height: 8),
            _numField('랜덤 시드', randomSeedText, (v) => setState(() => randomSeedText = v), hint: '선택'),
          ] else ...[
            _numField('경유 샘플 수', numVias.toString(), (v) => setState(() => numVias = int.tryParse(v) ?? 3)),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('탄천 폴리라인을 따라 균등 간격으로 경유지 샘플을 잡습니다. (첫/마지막 포함)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _requestRoute,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('경로 요청'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _loading ? null : _clear, child: const Text('지우기')),
            ],
          ),
          const SizedBox(height: 10),

          _tile('상태', _status),
          if (_summary.isNotEmpty) _tile('요약', _summary),
          if (_errorText != null) _tile('에러', _errorText!, error: true),
        ],
      ),
    );

    final mapView = KakaoMap(
      option: KakaoMapOption(
        position: const LatLng(37.4, 127.1),
        zoomLevel: _zoomLevel,
        mapType: MapType.normal,
      ),
      onMapReady: (c) => _map = c,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: mapView),

            Positioned(
              right: 12,
              bottom: 20,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    onPressed: () async {
                      if (_map == null) return;
                      _zoomLevel = (_zoomLevel - 1).clamp(1, 20);
                      try {
                        await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel));
                      } catch (_) {
                        await _map!.moveCamera(CameraUpdate.zoomOut());
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    onPressed: () async {
                      if (_map == null) return;
                      _zoomLevel = (_zoomLevel + 1).clamp(1, 20);
                      try {
                        await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel));
                      } catch (_) {
                        await _map!.moveCamera(CameraUpdate.zoomIn());
                      }
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              left: _panelOpen ? 0 : -panelWidth,
              top: 0,
              bottom: 0,
              width: panelWidth,
              child: IgnorePointer(
                ignoring: !_panelOpen && isNarrow,
                child: Material(
                  elevation: isNarrow ? 10 : 2,
                  color: Colors.white.withOpacity(isNarrow ? 0.97 : 1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: leftPanel,
                ),
              ),
            ),

            Positioned(
              top: 8,
              left: _panelOpen ? (panelWidth + 8) : 8,
              child: FloatingActionButton.small(
                heroTag: 'panelToggle',
                onPressed: () => setState(() => _panelOpen = !_panelOpen),
                child: Icon(_panelOpen ? Icons.chevron_left : Icons.menu),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, String value, ValueChanged<String> onChanged, {String? hint}) {
    return TextFormField(
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }

  Widget _tile(String title, String body, {bool error = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: error ? const Color(0xffFEF2F2) : const Color(0xffF9FAFB),
        border: Border.all(color: error ? const Color(0xffFECACA) : const Color(0xffE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: error ? const Color(0xff991B1B) : Colors.black87)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(color: error ? const Color(0xff991B1B) : Colors.black87)),
      ]),
    );
  }
}