import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import "package:kakao_map_sdk/kakao_map_sdk.dart";
import 'serverResponse.dart';
import 'package:geolocator/geolocator.dart';

class KMap extends StatefulWidget {
  const KMap({super.key});

  @override
  State<KMap> createState() => _KMapState();
}

class _KMapState extends State<KMap> {
  // ====== UI 상태 (웹과 동일) ======
  String tag = 'cafe'; // cafe | river
  int _zoomLevel = 6;       // 초기 줌 레벨
  bool _panelOpen = true;   // 패널 열림/닫힘 상태
  LatLng? _myLatLng;  // 내 위치 저장 (옵션)
  bool _locating = false;

  // 현재 파일의 _KMapState 안
  final List<dynamic> _poiHandles = [];
  final List<dynamic> _routeHandles = []; // 경로 여러 개 대비. 한 개면 하나만 써도 OK

  // 공통
  final startCtrl = TextEditingController(text: '죽전역');
  final destCtrl  = TextEditingController(text: '오리역');

  // cafe
  String difficulty = 'normal'; // easy | normal | hard
  String targetMode = 'distance'; // distance | time
  String targetKmText = ''; // distance mode
  String targetMinText = ''; // time mode
  String paceText = '';      // time mode (optional)
  int cafeCount = 1;
  int searchRadius = 300;
  double toleranceRatio = 0.08;
  String randomSeedText = '';

  // river
  int numVias = 3;

  // 뷰 상태
  bool _loading = false;
  String _status = '준비됨. (마커를 탭하면 장소명이 표시됩니다)';
  String? _errorText;
  String _summary = '';
  String _viasSummary = '';

  // 지도
  KakaoMapController? _map;
  late final PoiStyle _poiStyle;

  // 원본 JSON
  RouteResponse? _last;

  @override
  void initState() {
    super.initState();
    _poiStyle = PoiStyle(
      icon: KImage.fromAsset('assets/img/location.png', 40, 60),
    );
  }

  @override
  void dispose() {
    startCtrl.dispose();
    destCtrl.dispose();
    super.dispose();
  }

  // 마커 관련 함수
  void _showPoiInfo({required String title, required double lat, required double lon}) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('위도: ${lat.toStringAsFixed(6)}'),
              Text('경도: ${lon.toStringAsFixed(6)}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      // 출발지에 채우기
                      startCtrl.text = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
                      Navigator.pop(context);
                    },
                    child: const Text('출발지로 설정'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // 도착지에 채우기
                      destCtrl.text = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
                      Navigator.pop(context);
                    },
                    child: const Text('도착지로 설정'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 마커(스타트/도착/경유지)
  // Future<void> addPoi(double lat, double lon, String? name) async {
  //   await _map!.labelLayer.addPoi(
  //     LatLng(lat, lon),
  //     style: _poiStyle,
  //     text: name, // 지도 위에 라벨을 같이 보이고 싶으면
  //     onClick: () {
  //       _showPoiInfo(
  //         title: name ?? '장소',
  //         lat: lat,
  //         lon: lon,
  //       );
  //     },
  //   );
  // }
  Future<void> addPoi(double lat, double lon, String? name) async {
    final poi = await _map!.labelLayer.addPoi(
      LatLng(lat, lon),
      style: _poiStyle,
      text: name,
      onClick: () {
          _showPoiInfo(
            title: name ?? '장소',
            lat: lat,
            lon: lon,
          );
      },
    );
    _poiHandles.add(poi);      // ✅ 핸들 저장
  }


  // 내 위치 가져오기
  Future<void> _goToMyLocation({int zoom = 16}) async {
    if (_map == null || _locating) return;
    _locating = true;
    try {
      // (A) 위치 서비스 켜져 있는지
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        // 서비스 꺼져 있으면 그냥 리턴하거나 스낵바 안내
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스가 꺼져 있어요. 켠 뒤 다시 시도하세요.')),
        );
        return;
      }

      // (B) 권한 체크/요청
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정에서 위치 권한을 허용해 주세요.')),
        );
        return;
      }
      if (perm == LocationPermission.denied) return;

      // (C) 현재 위치
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // (D) 카메라 이동 + 줌
      _myLatLng = LatLng(pos.latitude, pos.longitude);
      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(_myLatLng!),
        animation: const CameraAnimation(600),
      );

      // 4) 살짝 텀(맵이 센터 적용을 끝내도록)
      await Future.delayed(const Duration(milliseconds: 120));

      _zoomLevel = zoom.clamp(1, 20);
      try {
        await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel));
      } catch (_) {
        await _map!.moveCamera(CameraUpdate.zoomIn());
      }

      // 잠깐 텀을 주고
      await Future.delayed(const Duration(milliseconds: 100));

      // 이후에 센터 이동
      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(_myLatLng!),
        animation: const CameraAnimation(600),
      );
      // 잠깐 텀을 주고
      await Future.delayed(const Duration(milliseconds: 100));

      // (선택) 내 위치 마커
      await addPoi(_myLatLng!.latitude, _myLatLng!.longitude, "내 위치");

      setState((){
        debugPrint("Moved camera to ${_myLatLng!.latitude}, ${_myLatLng!.longitude}");
      });
    } catch (e) {
      debugPrint('goToMyLocation error: $e');
    } finally {
      _locating = false;
    }
  }

  // ===== 난이도 프리셋 (웹과 동일 로직) =====
  void _applyDifficultyPresets() {
    // 주석된 웹 프리셋 대신 현재 값으로 고정하는 버전 사용 중이었음
    // 여기서는 웹 주석값 그대로 참고할 수 있도록 분기만 둠.
    if (difficulty == 'easy') {
      cafeCount = 1;
      searchRadius = 300;
      toleranceRatio = 0.08;
    } else if (difficulty == 'normal') {
      cafeCount = 2;
      searchRadius = 400;
      toleranceRatio = 0.10;
    } else {
      cafeCount = 3;
      searchRadius = 600;
      toleranceRatio = 0.12;
    }
  }

  Future<void> _clearMap() async {
    if (_map == null) return;
    // await _map!.labelLayer.hideAllPoi();
    // await _map!.routeLayer.hideAllRoute();

    // 1) 경로 전부 삭제
    for (final h in _routeHandles) {
      await _map!.routeLayer.removeRoute(h);
    }
    _routeHandles.clear();
    // 2) POI 전부 삭제
    for (final h in _poiHandles) {
      await _map!.labelLayer.removePoi(h);
    }
    _poiHandles.clear();
    setState(() {
      _status = '초기화됨. (마커를 탭하면 장소명이 표시됩니다)';
      _errorText = null;
      _summary = '';
      _viasSummary = '';
      _last = null;
    });
  }

  Future<void> _requestRoute() async {
    if (_map == null) return;
    setState(() {
      _loading = true;
      _status = '요청 중…';
      _errorText = null;
      _summary = '';
      _viasSummary = '';
      _last = null;
    });

    // 요청 바디 구성 (웹과 동일한 키)
    final body = <String, dynamic>{
      'tag': tag,
      'start_text': startCtrl.text.trim(),
      'dest_text': destCtrl.text.trim(),
    };

    if (tag == 'cafe') {
      // 프리셋 적용 (사용자가 값 수정 가능)
      _applyDifficultyPresets();

      body.addAll({
        'difficulty': difficulty,
        'cafe_count': cafeCount,
        'search_radius': searchRadius,
        'tolerance_ratio': toleranceRatio,
      });

      if (targetMode == 'distance') {
        if (targetKmText.isNotEmpty) body['target_km'] = double.tryParse(targetKmText);
      } else {
        if (targetMinText.isNotEmpty) body['target_min'] = double.tryParse(targetMinText);
        if (paceText.isNotEmpty) body['pace_min_per_km'] = double.tryParse(paceText);
      }
      if (randomSeedText.isNotEmpty) {
        body['random_seed'] = int.tryParse(randomSeedText);
      }
      body['target_mode'] = targetMode;
    } else {
      body['num_vias'] = numVias;
    }

    try {
      final data = await ApiService.recommend(body);
      await _renderOnMap(data);

      final km = ((data.distanceM ?? 0) / 1000.0).toStringAsFixed(2);
      final durationSec = (data.durationSEval ?? data.durationS ?? 0).toInt();
      final min = (durationSec / 60).round();

      final modeText = data.targetMode != null ? ' / 모드: ${data.targetMode}' : '';
      final diffText = (tag == 'cafe') ? ' / 난이도: $difficulty' : '';

      setState(() {
        _status = '완료';
        _summary = '거리: $km km | 예상시간: ${min}분$modeText$diffText\n'
            '출발: ${data.start?['name'] ?? '-'} / 도착: ${data.dest?['name'] ?? '-'}';
        _viasSummary = _buildViasList(data.vias);
        _last = data;
      });
    } catch (e) {
      setState(() {
        _errorText = '⚠️ ${e.toString()}';
        _status = '실패';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _buildViasList(List<dynamic>? vias) {
    if (vias == null || vias.isEmpty) return '';
    final sb = StringBuffer();
    for (int i = 0; i < vias.length; i++) {
      final v = vias[i] as Map<String, dynamic>;
      final lat = (v['lat'] as num?)?.toDouble();
      final lon = (v['lon'] as num?)?.toDouble();
      final name = (v['name'] as String?) ?? '경유지';
      sb.writeln('${i + 1}. $name (${lat?.toStringAsFixed(5)}, ${lon?.toStringAsFixed(5)})');
    }
    return sb.toString().trimRight();
  }

  Future<void> _setStartToMyLocation() async {


    // (선택) 역지오코딩 → 주소 변환 (카카오 API 사용 가능)
    // 지금은 그냥 위도,경도 텍스트로 넣기
    setState(() {
      startCtrl.text = "${_myLatLng?.latitude}, ${_myLatLng?.longitude}";
    });

    // 지도도 이동시켜주기
    if (_map != null) {
      await _map!.moveCamera(CameraUpdate.newCenterPosition(_myLatLng!));
      await _map!.moveCamera(CameraUpdate.zoomTo(16));
    }
  }

  Future<void> _renderOnMap(RouteResponse data) async {
    if (_map == null) return;

    // // 기존 제거
    // await _map!.labelLayer.hideAllPoi();
    // await _map!.routeLayer.hideAllRoute();

    // 경로 추가
    final coords = data.line.map((e) => LatLng(e[1], e[0])).toList();
    if (coords.isNotEmpty) {
      final route = await _map!.routeLayer.addRoute(
        coords,
        RouteStyle(const Color(0xFF111827), 6),
      );
      _routeHandles.add(route);  // ✅ 핸들 저장
      // bounds 대체: center 계산 후 카메라 이동
      double minLat = double.infinity, maxLat = -double.infinity,
          minLon = double.infinity, maxLon = -double.infinity;
      for (final p in coords) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLon = math.min(minLon, p.longitude);
        maxLon = math.max(maxLon, p.longitude);
      }
      final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(center),
        animation: const CameraAnimation(600),
      );
    }


    if (data.start != null) {
      await addPoi(
        (data.start!['lat'] as num).toDouble(),
        (data.start!['lon'] as num).toDouble(),
        data.start!['name'] as String?,
      );
    }
    if (data.dest != null) {
      await addPoi(
        (data.dest!['lat'] as num).toDouble(),
        (data.dest!['lon'] as num).toDouble(),
        data.dest!['name'] as String?,
      );
    }
    if (data.vias != null) {
      for (final any in data.vias!) {
        final v = any as Map<String, dynamic>;
        await addPoi(
          (v['lat'] as num).toDouble(),
          (v['lon'] as num).toDouble(),
          v['name'] as String?,
        );
      }
    }

    await _map!.labelLayer.showAllPoi();
    await _map!.routeLayer.showAllRoute();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 600; // 폰/좁은 화면
    final panelWidth = math.min(360.0, size.width * 0.92);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // === 패널 내용: 네가 만든 leftPanel 그대로 사용 ===
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
                child: const Text('Flutter × Kakao Map',
                    style: TextStyle(color: Color(0xFF9A3412), fontSize: 11)),
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


          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: '출발지',
                    hintText: '예: 죽전역',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.my_location, color: Colors.blue),
                tooltip: "내 위치로 설정",
                onPressed: () async {
                  await _setStartToMyLocation();
                },
              ),
            ],
          ),

          const SizedBox(height: 8),
          TextFormField(
            controller: destCtrl,
            decoration: const InputDecoration(
                labelText: '도착지', hintText: '예: 오리역', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          if (tag == 'cafe') _cafeOptions() else _riverOptions(),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () async {
                    await _clearMap();      // 먼저 깔끔히 지우고
                    await _requestRoute();  // 새로 그리기
                  },
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('경로 요청'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _loading ? null : _clearMap, child: const Text('지우기')),
            ],
          ),

          const SizedBox(height: 10),
          _tile('상태', _status),
          if (_summary.isNotEmpty) _tile('요약', _summary),
          if (_viasSummary.isNotEmpty) _tile('경유지', _viasSummary),
          if (_errorText != null) _tile('에러', _errorText!, error: true),

          if (_last != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('원본 응답 보기 (line 포함)'),
              children: [
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_last!.toJson()),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.35),
                ),
              ],
            ),
          const SizedBox(height: 8),
          const Text('* line은 [lon, lat] 순서입니다. (Tmap 포맷)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );

    // 지도
    final mapView = KakaoMap(
      option: KakaoMapOption(
        position: const LatLng(37.4, 127.1),
        zoomLevel: _zoomLevel,
        mapType: MapType.normal,
        // 플러그인이 지원한다면 하이브리드 컴포지션/서피스 모드 옵션을 켜주세요.
        // compositionMode: CompositionMode.hybrid, // (지원 시)
      ),
      onMapReady: (c) async {
        _map = c;
        //await _map!.labelLayer.setClickable(true); // ← 클릭 활성화(혹시 기본값이 false인 경우 대비)
        // 맵 준비되면 바로 내 위치로 이동 시도
        await _goToMyLocation(zoom: 16); // 15~17 사이가 동네 보기 좋음
      },
    );

    // === 안드로이드: Drawer로 패널 표시 (겹침 이슈 회피, UX는 동일) ===
    if (isAndroid) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: mapView),

              // 우측 하단 줌 버튼들 (그대로 유지)
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
                        setState(() {});
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
                        setState(() {});
                      },
                      child: const Icon(Icons.remove),
                    ),
                    FloatingActionButton.small(
                      heroTag: 'myLoc',
                      onPressed: _locating ? null : () => _goToMyLocation(zoom: 16),
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),

                  ],
                ),
              ),

              // 좌측 상단 패널 토글 버튼 → Drawer 열기
              Positioned(
                top: 8,
                left: 8,
                child: Builder(
                  builder: (ctx) => FloatingActionButton.small(
                    heroTag: 'panelToggle',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    child: const Icon(Icons.menu),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ← 패널을 Drawer로 (시각/구성 동일하게 유지)
        drawer: SafeArea(
          child: SizedBox(
            width: panelWidth,
            child: Material(
              color: Colors.white,
              elevation: 8,
              child: leftPanel,
            ),
          ),
        ),
      );
    }

    // === iOS/기타: 기존 오버레이 UI 유지 ===
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: mapView),

            // 우측 하단 줌 버튼들
            Positioned(
              right: 12,
              bottom: 20,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    onPressed: () async { /* 네 기존 코드 그대로 */ },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    onPressed: () async { /* 네 기존 코드 그대로 */ },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),

            // ← 네가 쓰던 AnimatedPositioned 패널 그대로
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

            // 패널 토글 버튼
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

  // ====== 위젯 조각들 ======
  Widget _cafeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: difficulty,
          items: const [
            DropdownMenuItem(value: 'easy', child: Text('하')),
            DropdownMenuItem(value: 'normal', child: Text('중')),
            DropdownMenuItem(value: 'hard', child: Text('상')),
          ],
          onChanged: (v) => setState(() => difficulty = v ?? 'normal'),
          decoration: const InputDecoration(labelText: '난이도', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: targetMode,
          items: const [
            DropdownMenuItem(value: 'distance', child: Text('거리')),
            DropdownMenuItem(value: 'time', child: Text('시간')),
          ],
          onChanged: (v) => setState(() => targetMode = v ?? 'distance'),
          decoration: const InputDecoration(labelText: '목표 유형', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),

        if (targetMode == 'distance') ...[
          _numField('목표 거리(km)', targetKmText, (v) => setState(() => targetKmText = v),
              hint: '비우면 랜덤 카페'),
        ] else ...[
          _numField('목표 시간(분)', targetMinText, (v) => setState(() => targetMinText = v)),
          const SizedBox(height: 8),
          _numField('페이스(분/km)', paceText, (v) => setState(() => paceText = v),
              hint: '선택(없으면 OSRM 시간)'),
        ],

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _intField('카페 개수', cafeCount, (v) => setState(() => cafeCount = v), min: 1, max: 3)),
            const SizedBox(width: 8),
            Expanded(child: _intField('검색 반경(m)', searchRadius, (v) => setState(() => searchRadius = v), min: 150, max: 800)),
          ],
        ),
        const SizedBox(height: 8),
        _doubleField('허용 오차', toleranceRatio, (v) => setState(() => toleranceRatio = v)),
        const SizedBox(height: 8),
        _numField('랜덤 시드', randomSeedText, (v) => setState(() => randomSeedText = v), hint: '선택'),

        const SizedBox(height: 8),
        const Text('• 난이도는 기본값을 자동 설정합니다(카페 개수/반경/오차). 필요시 수정 가능',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        const Text('• 목표 유형을 시간으로 선택하면 목표 시간/선택적 페이스를 사용합니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _riverOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intField('경유 샘플 수', numVias, (v) => setState(() => numVias = v), min: 0, max: 5),
        const SizedBox(height: 6),
        const Text('하천 폴리라인을 따라 균등 간격으로 경유지 샘플을 잡습니다. (첫/마지막 포함)',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ====== 입력 유틸 ======
  Widget _numField(String label, String value, ValueChanged<String> onChanged, {String? hint}) {
    return TextFormField(
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }

  Widget _intField(String label, int value, ValueChanged<int> onParsed, {int? min, int? max}) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: (v) {
        final p = int.tryParse(v);
        if (p == null) return;
        var nv = p;
        if (min != null) nv = math.max(min, nv);
        if (max != null) nv = math.min(max, nv);
        onParsed(nv);
      },
    );
  }

  Widget _doubleField(String label, double value, ValueChanged<double> onParsed) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: (v) {
        final p = double.tryParse(v);
        if (p == null) return;
        onParsed(p);
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w600,
                  color: error ? const Color(0xff991B1B) : Colors.black87)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: error ? const Color(0xff991B1B) : Colors.black87)),
        ],
      ),
    );
  }
}
