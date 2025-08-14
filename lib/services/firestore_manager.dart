import 'dart:core';
import 'dart:ffi';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_db.dart'; // ✅ walkydb 전용 db

class UserProfile {
  final String uid;        // 파이어스토어에 저장되는 유저ID
  final String nickname;     // 유저 닉네임
  final Map<String, dynamic> character;        // 캐릭터 정보
  final String profileImageUrl; // 프로필사진 디렉토리
  final String statusMessage; // 상태메시지
  final DateTime updatedAt; //
  final DateTime createdAt; // 계정 생성 시각

  UserProfile({
    required this.uid,
    required this.nickname,
    required this.character,
    required this.profileImageUrl,
    required this.statusMessage,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      character: data['character'] ?? {},
      profileImageUrl: data['profileImageUrl'] ?? '',
      statusMessage: data['statusMessage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    final map = <String, dynamic>{
    'nickname': nickname,
    'character': character,
    'profileImageUrl': profileImageUrl,
    'statusMessage': statusMessage,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
  if(includeCreatedAt){
    map['createdAt'] = createdAt;
  }
  return map;
  }
}

class UserProfileService {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      db.collection('users').doc(uid);

  String get _uid{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null){
      throw StateError('로그인이 필요합니다. (currentUser == null)');
    }
    return user.uid;

  }
  Future<void> createORUpdateProfile({
    required String nickname,
    Map<String, dynamic> character = const{},
    String profileImageUrl = '',
    String statusMessage = '',
    bool isCreate = false, // 최초 생성시 createdAt 세팅
  }) async{
    final now = FieldValue.serverTimestamp();
    final data = {
      'nickname' : nickname,
      'character' : character,
      'profileImageUrl' : profileImageUrl,
      'statusMessage' : statusMessage,
      'updatedAt' : now,
    };
    if(isCreate){
      data['createdAt'] = now;
    }
    await _doc(_uid).set(data, SetOptions(merge: true));
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _doc(uid).get();
    if(!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Stream<UserProfile?> watchProfile(String uid){
    return _doc(uid).snapshots().map(
        (doc) => doc.exists ? UserProfile.fromDoc(doc) : null,
    );
  }
}

class userDiary{
  final String id; // 문서 ID
  final String uid; // 유저 ID
  final String diaryTitle; // 일기 제목
  final int entryNumber; // 당일 일기 순서
  final String photoTitle; // 사진 디렉토리
  final String body; // 일기 내용
  final DateTime? createdAt; // 생성 일자

  userDiary({
    required this.id,
    required this.uid,
    required this.diaryTitle,
    required this.entryNumber,
    required this.photoTitle,
    required this.body,
    required this.createdAt,
  });

  factory userDiary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc){
    final data = doc.data() ?? {};
    return userDiary(
      id : doc.id,
      uid: data['uid'] ?? '',
      diaryTitle: data['diaryTitle'] ?? '',
      entryNumber: (data['entryNumber'] ?? 0) as int,
      photoTitle: data['photoTitle'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  Map<String, dynamic> toMap({bool includeTimestamps = false}){
    final map = <String, dynamic>{
      'uid' : uid,
      'diaryTitle' : diaryTitle,
      'entryNumber' : entryNumber,
      'photoTitle' : photoTitle,
      'body' : body,
      'createdAt' : createdAt,
    };
    if(includeTimestamps){
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}

class DiaryService{
  String get _uid{
    final user = FirebaseAuth.instance.currentUser;
    if(user == null){
      throw StateError('로그인이 필요합니다. (currentUser == null)');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> _diaryCol(String uid) =>
      _userDoc(uid).collection('diary');
  DocumentReference<Map<String, dynamic>> _diaryDoc(String uid, String entryId) =>
      _diaryCol(uid).doc(entryId);

  CollectionReference<Map<String, dynamic>> _counterCol(String uid) =>
      _userDoc(uid).collection('diary_counters');
  DocumentReference<Map<String, dynamic>> _counterDoc(String uid, String dateKey) =>
      _counterCol(uid).doc(dateKey);

  String _todayKey([DateTime? now]){
    now ??= DateTime.now();
    final year = now.year.toString().padLeft(4,'0');
    final month = now.month.toString().padLeft(2,'0');
    final day = now.day.toString().padLeft(2,'0');
    return '$year-$month-$day'; //YYYY-MM--DD
  }

  Future<String> _allocEntryIdForToday() async{
    final dateKey = _todayKey();
    final counterRef = _counterDoc(_uid, dateKey);

    return db.runTransaction<String>((tx) async {
      final snap = await tx.get(counterRef);
      int nextNumber = 1;

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final cur = (data['next'] as num?)?.toInt() ?? 1;
        nextNumber = cur;
        tx.update(counterRef, {'next': cur + 1});
      } else {
        tx.set(counterRef, {
          'date': dateKey,
          'next': 2,
        });
      }
      return '$dateKey-$nextNumber';
    });
  }
  Future<String> addDiary({
    required String diaryTitle,
    required String body,
    String photoTitle = '',
  }) async {
    final entryId = await _allocEntryIdForToday();

    await _diaryDoc(_uid, entryId).set({
      'uid': _uid,
      'diaryTitle': diaryTitle,
      'entryNumber': int.parse(entryId.split('-').last),
      'photoTitle': photoTitle,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return entryId;
  }

  /// [지정 저장] 이미 만든 ID(YYYY-MM-DD-N)로 저장/업데이트
  /// isCreate=true일 때만 createdAt 세팅 (최초 생성 시)
  Future<void> setDiary({
    required String entryId, // "YYYY-MM-DD-N"
    required String diaryTitle,
    required String body,
    String photoTitle = '',
    bool isCreate = false,
  }) async {
    final data = <String, dynamic>{
      'uid': _uid,
      'diaryTitle': diaryTitle,
      'photoTitle': photoTitle,
      'body': body,
    };

    // entryNumber를 ID에서 추출해 보관
    final parts = entryId.split('-');
    final numStr = parts.isNotEmpty ? parts.last : '1';
    data['entryNumber'] = int.tryParse(numStr) ?? 1;

    if (isCreate) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await _diaryDoc(_uid, entryId).set(data, SetOptions(merge: true));
  }

  /// 부분 업데이트 (예: 내용만, 제목만)
  Future<void> updateDiary(String entryId, Map<String, dynamic> patch) async {
    await _diaryDoc(_uid, entryId).set(patch, SetOptions(merge: true));
  }

  /// 단건 조회
  Future<userDiary?> getDiary(String entryId) async {
    final snap = await _diaryDoc(_uid, entryId).get();
    if (!snap.exists) return null;
    return userDiary.fromDoc(snap);
  }

  /// 단건 실시간 구독
  Stream<userDiary?> watchDiary(String entryId) {
    return _diaryDoc(_uid, entryId).snapshots().map(
          (doc) => doc.exists ? userDiary.fromDoc(doc) : null,
    );
  }

  /// 목록 실시간 구독(최신순). 오늘만 보고 싶으면 [dateKey] 넘겨서 prefix 매칭
  Stream<List<userDiary>> watchDiaries({
    int limit = 20,
    String? dateKey, // 'YYYY-MM-DD' 전달 시 해당 날짜만
  }) {
    Query<Map<String, dynamic>> q = _diaryCol(_uid);

    if (dateKey != null) {
      // createdAt 쿼리로 날짜 필터링 (권장)
      final dayStart = DateTime.parse('$dateKey 00:00:00Z').toLocal();
      final start = DateTime(dayStart.year, dayStart.month, dayStart.day);
      final end = start.add(const Duration(days: 1));

      q = q
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);

    return q.snapshots().map((qs) => qs.docs.map(userDiary.fromDoc).toList());
  }

  /// 삭제
  Future<void> deleteDiary(String entryId) =>
      _diaryDoc(_uid, entryId).delete();
}
