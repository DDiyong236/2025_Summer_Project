import 'dart:async';
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
  // ====== UI 상태 ======
  String tag = 'cafe'; // cafe | river
  int _zoomLevel = 6;       // 초기 줌 레벨
  bool _panelOpen = true;   // 패널 열림/닫힘 상태
  LatLng? _myLatLng;        // 내 위치 저장 (옵션)
  bool _locating = false;
  bool _skipTrailOnce = false;


  // 지도 핸들
  KakaoMapController? _map;
  late final PoiStyle _poiStyle;

  // POI/Route 핸들 컬렉션
  final List<dynamic> _poiHandles = [];
  final List<dynamic> _routeHandles = []; // 기타 경로가 있을 경우 대비

  // 공통 입력
  final startCtrl = TextEditingController(text: '죽전역');
  final destCtrl  = TextEditingController(text: '오리역');

  // cafe 옵션
  String difficulty = 'normal'; // easy | normal | hard
  String targetMode = 'distance'; // distance | time
  String targetKmText = '';   // distance mode
  String targetMinText = '';  // time mode
  String paceText = '';       // time mode (optional)
  int cafeCount = 1;
  int searchRadius = 300;
  double toleranceRatio = 0.08;
  String randomSeedText = '';

  // river 옵션
  int numVias = 3;

  // 뷰 상태
  bool _loading = false;
  String _status = '준비됨. (마커를 탭하면 장소명이 표시됩니다)';
  String? _errorText;
  String _summary = '';
  String _viasSummary = '';

  // 원본 JSON
  RouteResponse? _last;

  // ====== 경로 준비 여부 (경로 시작 버튼 활성화 제어) ======
  bool _routeReady = false;

  // --------------- 네비게이션 -----------------
  // 스트림/상태
  StreamSubscription<Position>? _posSub;
  bool _navRunning = false;        // 경로 시작/일시정지 상태
  bool _followMe = true;           // 카메라 자동 추적 on/off
  bool _drawTrail = true;          // 이동 궤적 라인 표시
  LatLng? _lastLatLng;
  DateTime? _lastFixAt;

  // 지도 오브젝트 핸들
  dynamic _mePoi;                  // 내 위치 마커
  dynamic _trailRoute;             // 지나온 궤적 라인
  dynamic _progressedRoute;        // 진행된 구간 라인
  dynamic _remainingRoute;         // 남은 구간 라인

  // 경로 캐시 (line 분할 위해)
  List<LatLng> _routeCoords = [];

  // 궤적 로컬 캐시(append용)
  List<LatLng>? _trailCache;

  // 트레일 최적화 파라미터
  final int _trailMaxPoints = 1000;     // [OPT] 트레일 최대 보관 점수
  final double _minTrailStepM = 3.0;    // [OPT] 3m 미만 이동 시 업데이트 스킵

  // 이탈 감지
  double _offRouteThresholdM = 40; // 40m 이상 벗어나면 이탈
  bool _rerouting = false;         // 재탐색 중복 방지
  DateTime? _lastRerouteAt;        // [OPT] 재탐색 쿨다운 타임스탬프
  final Duration _rerouteCooldown = const Duration(seconds: 10);

  // [OPT] 콜백 re-entry 방지(프레임 드랍 방지용 라이트 가드)
  bool _tickBusy = false;

  // ---- 시뮬레이션 ----
  bool _simMode = false;           // 지도 위 토글/FAB로 켜고 끔
  Timer? _simTimer;
  int _simIdx = 0;                 // _routeCoords 상의 인덱스
  Duration _simTick = const Duration(milliseconds: 900);


  // 항상 표시용 low 파워 스트림
  StreamSubscription<Position>? _presenceSub;

  //---------------------------------------------

  @override
  void initState() {
    super.initState();
    _poiStyle = PoiStyle(
      icon: KImage.fromAsset('assets/img/location.png', 40, 60),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _simTimer?.cancel();
    startCtrl.dispose();
    destCtrl.dispose();
    super.dispose();
  }

  // ================= 네비게이션 제어 =================

  Future<void> _startPresenceStream() async {
    if (_map == null) return;
    // 권한/서비스 체크 (간단)
    final svcEnabled = await Geolocator.isLocationServiceEnabled();
    if (!svcEnabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

    // 저전력 세팅: 정확도 balanced, 15m 이상 이동 시 갱신
    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 15,
    );

    await _presenceSub?.cancel();
    _presenceSub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) async {
      if (_map == null) return;
      final here = LatLng(pos.latitude, pos.longitude);
      _myLatLng = here;
      // 마커만 갱신 (카메라/트레일/ETA 없음)
      await _updateMyMarker(here);
    });
  }

  Future<void> _stopPresenceStream() async {
    await _presenceSub?.cancel();
    _presenceSub = null;
  }

  Future<void> _startNavigation() async {
    if (_navRunning || !_routeReady) return;
    _navRunning = true;
    _status = _simMode ? '시뮬레이션 시작' : '네비게이션 시작';
    if (mounted) setState(() {});
    await _stopPresenceStream();
    await _startPositionStream();
  }

  void _pauseNavigation() {
    if (!_navRunning) return;
    _posSub?.cancel();
    _posSub = null;
    _stopSimTimer();
    _navRunning = false;
    if (mounted) {
      setState(() {
        _status = '일시정지됨';
      });
    }
    _startPresenceStream();          // ★ 다시 항상-표시 재개

  }

  Future<void> _startPositionStream() async {
    if (_simMode) {
      // 시뮬레이션: 타이머로 경로를 따라 이동
      _resetSimToStart();
      _startSimTimer();
      return;
    }

    // 실제 위치: 권한/서비스 점검
    final svcEnabled = await Geolocator.isLocationServiceEnabled();
    if (!svcEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스가 꺼져 있어요. 켠 뒤 다시 시도하세요.')),
        );
      }
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정에서 위치 권한을 허용해 주세요.')),
        );
      }
      return;
    }

    // 스트림 옵션
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,  // [OPT] 3m 이상 이동 시 콜백
    );

    _posSub?.cancel();
    // [FIX] Position을 함께 전달해서 속도/ETA 계산 정확화
    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) async {
      final here = LatLng(pos.latitude, pos.longitude);
      await _onLocationTick(here, pos);
    }, onError: (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 스트림 오류: $e')),
        );
      }
    });
  }

  // 공통: 위치 갱신시 수행
  // [FIX] Position(속도 포함)을 받아 ETA 안정화
  Future<void> _onLocationTick(LatLng here, [Position? pos]) async {
    if (_map == null || _tickBusy) return;
    _tickBusy = true;
    try {
      final now = DateTime.now();

      // 속도 추정: 센서값 우선, 없으면 이전점/시간으로 근사
      double? speedMps = (pos != null && pos.speed > 0) ? pos.speed : null;
      if (speedMps == null && _lastLatLng != null && _lastFixAt != null) {
        final dt = now.difference(_lastFixAt!).inMilliseconds / 1000.0;
        if (dt > 0.2) {
          final d = _haversineM(
            _lastLatLng!.latitude, _lastLatLng!.longitude,
            here.latitude, here.longitude,
          );
          speedMps = d / dt;
        }
      }

      _lastLatLng = here;
      _lastFixAt = now;

      // 1) 내 위치 마커 갱신 (중복 생성 방지)
      await _updateMyMarker(here);

      // 2) 카메라 추적
      if (_followMe) {
        await _map!.moveCamera(
          CameraUpdate.newCenterPosition(here),
          animation: const CameraAnimation(500),
        );
      }

      // 트레일: 한 번만 스킵
      if (_drawTrail && !_skipTrailOnce) {
        await _updateTrail(here);
      } else {
        _skipTrailOnce = false; // 다음 틱부터 정상
      }

      // 4) 진행/남은 경로, ETA, 이탈감지
      if (_routeCoords.isNotEmpty) {
        await _updateProgressPolylineAndEta(here, speedHintMps: speedMps);
        if (!_simMode) {
          _detectOffRouteAndMaybeReroute(here);
        }
      }
    } finally {
      _tickBusy = false;
    }
  }

  // ================== 시뮬레이션 유틸 ==================
  // [추가] 헬퍼: 트레일만 싹 지우기
  Future<void> _clearTrail() async {
    if (_trailRoute != null) {
      await _map!.routeLayer.removeRoute(_trailRoute);
      _trailRoute = null;
    }
    _trailCache = null;
  }
  void _startSimTimer() {
    _stopSimTimer();
    if (_routeCoords.length < 2) return;
    _simTimer = Timer.periodic(_simTick, (_) {
      if (!_navRunning) return;
      _simIdx = (_simIdx + 1).clamp(0, _routeCoords.length - 1);
      _onLocationTick(_routeCoords[_simIdx]); // pos 없음
      if (_simIdx >= _routeCoords.length - 1) {
        _pauseNavigation();
        if (mounted) setState(() => _status = '도착(시뮬레이션)');
      }
    });
  }

  void _stopSimTimer() {
    _simTimer?.cancel();
    _simTimer = null;
  }

// [수정] 리셋: 트레일 제거 + 다음 틱 1회 스킵
  Future<void> _resetSimToStart() async {
    if (_routeCoords.isEmpty) return;
    _simIdx = 0;

    await _clearTrail();     // ★ 파란 선 제거
    _skipTrailOnce = true;   // ★ 다음 onLocationTick에서 트레일 스킵

    // 시작점으로 상태만 반영 (카메라/마커/진행선 갱신)
    final start = _routeCoords.first;
    await _onLocationTick(start); // 이 틱에서는 파란 선 안 그림
  }

  void _stepSim(int dir) {
    if (_routeCoords.isEmpty) return;
    _simIdx = (_simIdx + dir).clamp(0, _routeCoords.length - 1);
    _onLocationTick(_routeCoords[_simIdx]);
  }

  // ================== 마커/트레일 ==================
  Future<void> _updateMyMarker(LatLng here) async {
    if (_mePoi == null) {
      _mePoi = await _map!.labelLayer.addPoi(
        here,
        style: PoiStyle(icon: KImage.fromAsset('assets/img/me_dot.png', 36, 36)),
        text: '나',
      );
    } else {
      // SDK에 setPosition이 없다면 remove 후 add
      await _map!.labelLayer.removePoi(_mePoi);
      _mePoi = await _map!.labelLayer.addPoi(
        here,
        style: PoiStyle(icon: KImage.fromAsset('assets/img/me_dot.png', 36, 36)),
        text: '나',
      );
    }
  }

  // [OPT] 3m 미만 이동 스킵 + 최대 점수 캡
  Future<void> _updateTrail(LatLng here) async {
    _trailCache ??= <LatLng>[];
    if (_trailCache!.isNotEmpty) {
      final last = _trailCache!.last;
      final moved = _haversineM(last.latitude, last.longitude, here.latitude, here.longitude);
      if (moved < _minTrailStepM) return; // 3m 미만 skip
    }
    _trailCache!.add(here);
    if (_trailCache!.length > _trailMaxPoints) {
      _trailCache!.removeRange(0, _trailCache!.length - _trailMaxPoints);
    }

    if (_trailRoute != null) {
      await _map!.routeLayer.removeRoute(_trailRoute);
    }
    _trailRoute = await _map!.routeLayer.addRoute(
      _trailCache!,
      RouteStyle(const Color(0xFF3B82F6), 4), // 파란 가는 선
    );
  }

  // [FIX] ETA에 외부 속도 힌트 사용(센서 우선)
  Future<void> _updateProgressPolylineAndEta(LatLng here, {double? speedHintMps}) async {
    if (_routeCoords.length < 2) return;

    final idx = _closestPointIndexOnPolyline(_routeCoords, here);
    final progressed = _routeCoords.sublist(0, math.max(1, idx));
    final remaining  = _routeCoords.sublist(math.max(0, idx), _routeCoords.length);

    // 진행(회색): 2개 미만이면 기존 라인 유지
    await _updateRouteSafe(
      getHandle: () => _progressedRoute,
      setHandle: (h) => _progressedRoute = h,
      coords: progressed,
      color: const Color(0xFFCBD5E1),
      width: 6,
    );

    // 남은(진한색): 2개 미만이면 기존 라인 유지 (끝부분에서 깜빡임/소실 방지)
    await _updateRouteSafe(
      getHandle: () => _remainingRoute,
      setHandle: (h) => _remainingRoute = h,
      coords: remaining,
      color: const Color(0xFF111827),
      width: 7,
    );

    // ETA
    final remainMeters = _polylineLengthM(remaining);
    final speedMps = (speedHintMps != null && speedHintMps > 0.4)
        ? speedHintMps
        : await _currentSpeedMpsFallback(); // 백업 근사
    if (speedMps != null && speedMps > 0.4) {
      final etaMin = (remainMeters / speedMps / 60).round();
      if (mounted) {
        setState(() {
          _status = '이동 중 · 남은 ${(remainMeters/1000).toStringAsFixed(2)} km · ETA ${etaMin}분';
        });
      }
    }
  }

  // 라인 핸들 교체: 점이 2개 미만이면 기존 라인을 지우지 않고 유지
  Future<void> _updateRouteSafe({
    required dynamic Function() getHandle,
    required void Function(dynamic) setHandle,
    required List<LatLng> coords,
    required Color color,
    required int width,
  }) async {
    if (coords.length < 2) return; // 2개 미만이면 아무 것도 하지 않음

    final current = getHandle();
    if (current != null) {
      await _map!.routeLayer.removeRoute(current);
    }
    final newHandle = await _map!.routeLayer.addRoute(
      coords,
      RouteStyle(color, width.toDouble()),
    );
    setHandle(newHandle);
  }

  // [OPT] 오프루트 재탐색 쿨다운(10초)
  void _detectOffRouteAndMaybeReroute(LatLng here) {
    if (_rerouting || _routeCoords.length < 2) return;

    final dist = _distancePointToPolylineM(here, _routeCoords);
    if (dist > _offRouteThresholdM) {
      final now = DateTime.now();
      if (_lastRerouteAt != null && now.difference(_lastRerouteAt!) < _rerouteCooldown) {
        return; // 쿨다운 중
      }
      _lastRerouteAt = now;
      _rerouting = true;
      if (mounted) setState(() { _status = '경로 이탈 감지 · 재탐색 중…'; });
      // 현재 위치를 출발지로 반영 후 재요청
      startCtrl.text = "${here.latitude.toStringAsFixed(6)}, ${here.longitude.toStringAsFixed(6)}";
      _requestRoute().whenComplete(() {
        _rerouting = false;
      });
    }
  }

  // ================== 거리/기하 유틸 ==================
  int _closestPointIndexOnPolyline(List<LatLng> line, LatLng p) {
    if (line.isEmpty) return 0;
    double best = double.infinity;
    int bestIdx = 0;
    for (int i = 0; i < line.length; i++) {
      final d = _haversineM(p.latitude, p.longitude, line[i].latitude, line[i].longitude);
      if (d < best) { best = d; bestIdx = i; }
    }
    return bestIdx;
  }

  double _haversineM(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat/2)*math.sin(dLat/2) +
            math.cos(_deg2rad(lat1))*math.cos(_deg2rad(lat2)) *
                math.sin(dLon/2)*math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    return R * c;
  }

  double _distancePointToPolylineM(LatLng p, List<LatLng> poly) {
    double best = double.infinity;
    for (int i=1;i<poly.length;i++) {
      best = math.min(best, _distancePointToSegmentM(p, poly[i-1], poly[i]));
    }
    return best;
  }

  double _distancePointToSegmentM(LatLng p, LatLng a, LatLng b) {
    // 위경도 평면근사(짧은 세그먼트 기준)
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final px = p.longitude, py = p.latitude;

    final vx = bx - ax, vy = by - ay;
    final wx = px - ax, wy = py - ay;
    final c1 = vx*wx + vy*wy;
    final c2 = vx*vx + vy*vy;
    double t = (c2 <= 1e-12) ? 0 : (c1 / c2);
    t = t.clamp(0.0, 1.0);

    final projx = ax + t * vx;
    final projy = ay + t * vy;
    return _haversineM(py, px, projy, projx);
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  double _polylineLengthM(List<LatLng> path) {
    double sum = 0;
    for (int i=1;i<path.length;i++) {
      sum += _haversineM(
        path[i-1].latitude, path[i-1].longitude,
        path[i].latitude,   path[i].longitude,
      );
    }
    return sum;
  }

  // [FIX] getCurrentPosition 남발 대신 트레일 기반 백업 근사만 사용
  Future<double?> _currentSpeedMpsFallback() async {
    if (_trailCache != null && _trailCache!.length >= 2 && _lastFixAt != null) {
      final a = _trailCache![_trailCache!.length-2];
      final b = _trailCache![_trailCache!.length-1];
      final dt = DateTime.now().difference(_lastFixAt!).inMilliseconds / 1000.0;
      if (dt <= 0) return null;
      final d = _haversineM(a.latitude, a.longitude, b.latitude, b.longitude);
      return d / dt;
    }
    return null;
  }

  // ================== 마커/POI ==================
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
                      startCtrl.text = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
                      Navigator.pop(context);
                    },
                    child: const Text('출발지로 설정'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
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

  Future<void> addPoi(double lat, double lon, String? name) async {
    final poi = await _map!.labelLayer.addPoi(
      LatLng(lat, lon),
      style: _poiStyle,
      text: name,
      onClick: () {
        _showPoiInfo(title: name ?? '장소', lat: lat, lon: lon);
      },
    );
    _poiHandles.add(poi);
  }

  // ================== 현재 위치로 카메라 이동 ==================
  Future<void> _goToMyLocation({int zoom = 16}) async {
    if (_map == null || _locating) return;
    _locating = true;
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 서비스가 꺼져 있어요. 켠 뒤 다시 시도하세요.')),
          );
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설정에서 위치 권한을 허용해 주세요.')),
          );
        }
        return;
      }
      if (perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _myLatLng = LatLng(pos.latitude, pos.longitude);
      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(_myLatLng!),
        animation: const CameraAnimation(600),
      );

      await Future.delayed(const Duration(milliseconds: 120));

      _zoomLevel = zoom.clamp(1, 20);
      try {
        await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel));
      } catch (_) {
        await _map!.moveCamera(CameraUpdate.zoomIn());
      }

      await Future.delayed(const Duration(milliseconds: 100));

      await _map!.moveCamera(
        CameraUpdate.newCenterPosition(_myLatLng!),
        animation: const CameraAnimation(600),
      );

      // [FIX] "내 위치" POI 중복 제거를 위해 별도 addPoi 생략
      if (mounted) {
        setState(() {
          debugPrint("Moved camera to ${_myLatLng!.latitude}, ${_myLatLng!.longitude}");
        });
      }
    } catch (e) {
      debugPrint('goToMyLocation error: $e');
    } finally {
      _locating = false;
    }
  }

  // ===== 난이도 프리셋 =====
  void _applyDifficultyPresets() {
    if (difficulty == 'easy') {
      cafeCount = 1; searchRadius = 300; toleranceRatio = 0.08;
    } else if (difficulty == 'normal') {
      cafeCount = 2; searchRadius = 400; toleranceRatio = 0.10;
    } else {
      cafeCount = 3; searchRadius = 600; toleranceRatio = 0.12;
    }
  }

  // ================== 지도 클리어 ==================
  Future<void> _clearMap() async {
    if (_map == null) return;

    _pauseNavigation(); // 진행 중이면 먼저 정지
    _stopSimTimer();    // 안전하게 타이머 중단

    // 경로/궤적 제거
    for (final h in _routeHandles) {
      await _map!.routeLayer.removeRoute(h);
    }
    _routeHandles.clear();
    if (_progressedRoute != null) { await _map!.routeLayer.removeRoute(_progressedRoute); _progressedRoute = null; }
    if (_remainingRoute != null) { await _map!.routeLayer.removeRoute(_remainingRoute); _remainingRoute = null; }
    if (_trailRoute != null)     { await _map!.routeLayer.removeRoute(_trailRoute); _trailRoute = null; }
    _trailCache = null;

    // POI 제거
    for (final h in _poiHandles) {
      await _map!.labelLayer.removePoi(h);
    }
    _poiHandles.clear();
    if (_mePoi != null) {
      await _map!.labelLayer.removePoi(_mePoi);
      _mePoi = null;
    }

    // 상태 초기화
    if (mounted) {
      setState(() {
        _routeReady = false;
        _status = '초기화됨. (마커를 탭하면 장소명이 표시됩니다)';
        _errorText = null;
        _summary = '';
        _viasSummary = '';
        _last = null;
        _routeCoords = [];
        _simIdx = 0;
      });
    }
  }

  // ================== 경로 요청 ==================
  Future<void> _requestRoute() async {
    if (_map == null) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _routeReady = false;
        _status = '요청 중…';
        _errorText = null;
        _summary = '';
        _viasSummary = '';
        _last = null;
      });
    }

    final body = <String, dynamic>{
      'tag': tag,
      'start_text': startCtrl.text.trim(),
      'dest_text': destCtrl.text.trim(),
    };

    if (tag == 'cafe') {
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

      if (mounted) {
        setState(() {
          _routeReady = _routeCoords.length >= 2;
          _status = _routeReady ? '경로 준비 완료' : '경로 없음';
          _summary = '거리: $km km | 예상시간: ${min}분$modeText$diffText\n'
              '출발: ${data.start?['name'] ?? '-'} / 도착: ${data.dest?['name'] ?? '-'}';
          _viasSummary = _buildViasList(data.vias);
          _last = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = '⚠️ ${e.toString()}';
          _status = '실패';
          _routeReady = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
    if (mounted) {
      setState(() {
        startCtrl.text = "${_myLatLng?.latitude}, ${_myLatLng?.longitude}";
      });
    }
    if (_map != null && _myLatLng != null) {
      await _map!.moveCamera(CameraUpdate.newCenterPosition(_myLatLng!));
      await _map!.moveCamera(CameraUpdate.zoomTo(16));
    }
  }

  // ================== 지도에 경로 렌더링 ==================
  Future<void> _renderOnMap(RouteResponse data) async {
    if (_map == null) return;

    // 기존 경로 제거 (진행/남은 라인만 사용)
    for (final h in _routeHandles) {
      await _map!.routeLayer.removeRoute(h);
    }
    _routeHandles.clear();
    if (_progressedRoute != null) { await _map!.routeLayer.removeRoute(_progressedRoute); _progressedRoute = null; }
    if (_remainingRoute != null) { await _map!.routeLayer.removeRoute(_remainingRoute); _remainingRoute = null; }

    // 좌표 캐시
    _routeCoords = data.line.map((e) => LatLng(e[1], e[0])).toList();

    // 남은 라인 먼저 그리기
    if (_routeCoords.length >= 2) {
      _remainingRoute = await _map!.routeLayer.addRoute(
        _routeCoords,
        RouteStyle(const Color(0xFF111827), 7),
      );
    }

    // 카메라 중앙 이동
    if (_routeCoords.isNotEmpty) {
      double minLat = double.infinity, maxLat = -double.infinity,
          minLon = double.infinity, maxLon = -double.infinity;
      for (final p in _routeCoords) {
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

    // POI 렌더
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

    // 경로 준비 플래그
    _routeReady = _routeCoords.length >= 2;

    // 시뮬레이션 모드면 시작 위치 미리 찍어둠(자동 시작 X)
    if (_routeReady && _simMode) {
      _resetSimToStart();
    }

    // 실시간이 이미 돌고 있으면 현재 위치 기준 분할 갱신
    if (_lastLatLng != null) {
      await _updateProgressPolylineAndEta(_lastLatLng!);
    }
  }

  // ================== 지도 위 퀵컨트롤 (FAB들) ==================
  Widget _buildQuickControls(bool isAndroid) {
    return Column(
      children: [
        FloatingActionButton.small(
          heroTag: 'zoomIn',
          onPressed: () async {
            if (_map == null) return;
            _zoomLevel = (_zoomLevel - 1).clamp(1, 20);
            try { await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel)); }
            catch (_) { await _map!.moveCamera(CameraUpdate.zoomOut()); }
            if (mounted) setState(() {});
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),

        FloatingActionButton.small(
          heroTag: 'zoomOut',
          onPressed: () async {
            if (_map == null) return;
            _zoomLevel = (_zoomLevel + 1).clamp(1, 20);
            try { await _map!.moveCamera(CameraUpdate.zoomTo(_zoomLevel)); }
            catch (_) { await _map!.moveCamera(CameraUpdate.zoomIn()); }
            if (mounted) setState(() {});
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),


        FloatingActionButton.small(
          heroTag: 'myLoc',
          onPressed: _locating ? null : () => _goToMyLocation(zoom: 16),
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),

        // 네비 시작/일시정지 (경로 준비 후에만 활성화)
        FloatingActionButton.small(
          heroTag: 'navToggle',
          onPressed: (!_routeReady)
              ? null
              : () => _navRunning ? _pauseNavigation() : _startNavigation(),
          child: Icon(_navRunning ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(height: 8),

        // === 시뮬레이션 토글 ===
        FloatingActionButton.small(
          heroTag: 'simToggle',
          tooltip: '시뮬레이션 모드',
          backgroundColor: _simMode ? const Color(0xFF2563EB) : null,
          onPressed: () {
            setState(() => _simMode = !_simMode);
            // 실행 중 모드 전환 시 안전하게 재시작
            if (_navRunning) {
              _pauseNavigation();
              if (_routeReady && _simMode) _startNavigation();
            }
          },
          child: const Icon(Icons.directions_walk),
        ),

        // 토글 켜졌을 때 스텝 패드
        if (_simMode) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.white.withOpacity(0.92),
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '한 칸 뒤로',
                  onPressed: _routeReady ? () => _stepSim(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: '리셋',
                  onPressed: _routeReady ? _resetSimToStart : null,
                  icon: const Icon(Icons.restart_alt),
                ),
                IconButton(
                  tooltip: '한 칸 앞으로',
                  onPressed: _routeReady ? () => _stepSim(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================== 위젯 빌드 ==================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 600;
    final panelWidth = math.min(360.0, size.width * 0.92);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

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

          // === 액션 버튼들 ===
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () async {
                    await _clearMap();
                    await _requestRoute();
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
          const SizedBox(height: 8),

          // 경로 시작/일시정지 토글 (경로 준비 후에만 활성화)
          FilledButton.tonal(
            onPressed: (!_routeReady)
                ? null
                : () => _navRunning ? _pauseNavigation() : _startNavigation(),
            child: Text(_navRunning ? '일시정지' : '경로 시작'),
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
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.35),
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
      ),
      onMapReady: (c) async {
        _map = c;
        await _goToMyLocation(zoom: 16); // 자동 스트림 시작은 하지 않음 (버튼으로 시작)
        await _startPresenceStream();
      },
    );

    // === 안드로이드: Drawer로 패널 ===
    if (isAndroid) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: mapView),

              // 우측 하단 퀵컨트롤 + 시뮬레이션
              Positioned(
                right: 12,
                bottom: 20,
                child: _buildQuickControls(true),
              ),

              // 좌측 상단 패널 버튼
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

    // === iOS/기타: 오버레이 패널 ===
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: mapView),

            // 우측 하단 퀵컨트롤(iOS) + 시뮬레이션
            Positioned(
              right: 12,
              bottom: 20,
              child: _buildQuickControls(false),
            ),

            // 좌측 패널
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

  // ====== 옵션 위젯 ======
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
