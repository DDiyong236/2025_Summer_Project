import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/firebase_options.dart';
import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';

import 'services/firebase_db.dart';           // ✅ walkydb (FirebaseFirestore 인스턴스)
import 'services/firestore_manager.dart';     // ✅ UserProfileService, DiaryService, 모델들

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 오프라인 캐시 등 옵션
  db.settings = const Settings(persistenceEnabled: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Firebase: Auth → Storage + Firestore (walkydb)',
      home: AuthGate(),
    );
  }
}

/// 로그인 상태에 따라 화면 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          // 로그인 필요
          return const LoginPage();
        }
        // 로그인 됨 → 기능 테스트 화면
        return const HomePage();
      },
    );
  }
}

/// 로그인 전용 화면
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TTSManager _tts;
  late final AuthService _auth;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tts = TTSManager();
    _auth = AuthService();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _auth.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공')),
      );
      // authStateChanges()가 HomePage로 자동 전환
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인 필요')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('테스트 전에 먼저 로그인하세요.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _googleSignIn,
                child: Text(_busy ? '로그인 중…' : 'Google 로그인'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _tts.speak('로그인 테스트 화면입니다.'),
                child: const Text('TTS 테스트'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로그인 후 기능 테스트 화면
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ---- 공통 (TTS/인증) ----
  late final TTSManager _tts;
  late final AuthService _auth;

  // ---- 이미지 업로드 ----
  File? _image;
  String? _downloadUrl;
  final TextEditingController _captionController = TextEditingController();

  // ---- 프로필 ----
  final _nicknameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _profileSvc = UserProfileService();

  // ---- 일기 ----
  final _diaryTitleCtrl = TextEditingController();
  final _diaryBodyCtrl = TextEditingController();
  final _diarySvc = DiaryService();

  @override
  void initState() {
    super.initState();
    _tts = TTSManager();
    _auth = AuthService();
  }

  @override
  void dispose() {
    _tts.dispose();
    _captionController.dispose();
    _nicknameCtrl.dispose();
    _statusCtrl.dispose();
    _diaryTitleCtrl.dispose();
    _diaryBodyCtrl.dispose();
    super.dispose();
  }

  // ===================== 이미지 업로드 =====================
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('images/$fileName.jpg');

    await ref.putFile(_image!);
    final url = await ref.getDownloadURL();
    setState(() => _downloadUrl = url);

    await _saveUploadMetaToFirestore(
      downloadUrl: url,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('업로드 & Firestore 저장 완료 (walkydb)')),
    );
  }

  // ✅ 업로드 메타데이터 저장: users/{uid}/uploads
  Future<void> _saveUploadMetaToFirestore({
    required String downloadUrl,
    String? caption,
  }) async {
    final user = _auth.currentUser; // 로그인 보장 (AuthGate)
    final uid = user!.uid;

    final col = db.collection('users').doc(uid).collection('uploads');
    await col.add({
      'url': downloadUrl,
      'caption': caption ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _captionController.clear();
  }

  Widget _buildUploadsList() {
    final uid = _auth.currentUser!.uid;
    final stream = db
        .collection('users')
        .doc(uid)
        .collection('uploads')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('업로드 기록이 없습니다.'),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final url = (data['url'] ?? '') as String;
            final caption = (data['caption'] ?? '') as String;
            final createdAt = data['createdAt'];
            final timeText = (createdAt is Timestamp)
                ? createdAt.toDate().toLocal().toString()
                : '';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: url.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(url, width: 56, height: 56, fit: BoxFit.cover),
              )
                  : const Icon(Icons.image),
              title: Text(caption.isEmpty ? '이미지' : caption),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(url, style: const TextStyle(fontSize: 12)),
                  if (timeText.isNotEmpty)
                    Text(timeText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => docs[i].reference.delete(),
                tooltip: 'Firestore 기록 삭제',
              ),
              onTap: () {
                if (url.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(child: Image.network(url)),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  // ===================== 프로필 =====================
  Future<void> _createOrUpdateProfile({required bool isCreate}) async {
    try {
      await _profileSvc.createORUpdateProfile(
        nickname: _nicknameCtrl.text.trim(),
        character: const {},
        profileImageUrl: '',
        statusMessage: _statusCtrl.text.trim(),
        isCreate: isCreate,
      );
      _snack(isCreate ? '프로필 생성 완료' : '프로필 업데이트 완료');
    } catch (e) {
      _snack('프로필 저장 실패: $e');
    }
  }

  Widget _buildProfileSection() {
    final uid = _auth.currentUser!.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('프로필 (users/{uid})', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameCtrl,
          decoration: const InputDecoration(
            labelText: '닉네임',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _statusCtrl,
          decoration: const InputDecoration(
            labelText: '상태 메시지',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => _createOrUpdateProfile(isCreate: true),
              child: const Text('프로필 생성'),
            ),
            ElevatedButton(
              onPressed: () => _createOrUpdateProfile(isCreate: false),
              child: const Text('프로필 업데이트'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<UserProfile?>(
          stream: _profileSvc.watchProfile(uid),
          builder: (_, snap) {
            final p = snap.data;
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              );
            }
            if (p == null) return const Text('프로필 문서가 없습니다.');
            return Text(
              '현재 프로필 → nickname: ${p.nickname}, status: ${p.statusMessage}\ncreatedAt: ${p.createdAt}, updatedAt: ${p.updatedAt}',
            );
          },
        ),
      ],
    );
  }

  // ===================== 일기 =====================
  Future<void> _addDiary() async {
    try {
      final id = await _diarySvc.addDiary(
        diaryTitle: _diaryTitleCtrl.text.trim(),
        body: _diaryBodyCtrl.text.trim(),
        photoTitle: '',
      );
      _diaryTitleCtrl.clear();
      _diaryBodyCtrl.clear();
      _snack('일기 저장 완료: $id');
    } catch (e) {
      _snack('일기 저장 실패: $e');
    }
  }

  Widget _buildDiarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('일기 (users/{uid}/diary/{YYYY-MM-DD-N})', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _diaryTitleCtrl,
          decoration: const InputDecoration(
            labelText: '일기 제목',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _diaryBodyCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '일기 내용',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _addDiary, child: const Text('일기 추가')),
        const SizedBox(height: 8),
        StreamBuilder<List<userDiary>>(
          stream: _diarySvc.watchDiaries(limit: 50),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Text('작성된 일기가 없습니다.');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i];
                return ListTile(
                  title: Text('${e.diaryTitle}  (#${e.entryNumber})'),
                  subtitle: Text(e.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(e.createdAt?.toLocal().toString() ?? ''),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase: Auth → Storage + Firestore (walkydb)'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () async {
              await _auth.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 완료')),
              );
              // authStateChanges()가 LoginPage로 자동 전환
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 이미지 업로드 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _uploadImage, child: const Text('Upload')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_image != null) Center(child: Image.file(_image!, height: 180)),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    hintText: '업로드 메모(선택)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                if (_downloadUrl != null) ...[
                  const Text('Uploaded to:'),
                  SelectableText(_downloadUrl!),
                ],
                const SizedBox(height: 12),

                // --- 로그인/유저 표시 ---
                Text(
                  '환영합니다, ${user.displayName ?? user.email}',
                  textAlign: TextAlign.center,
                ),

                const Divider(height: 28),

                // --- 업로드 목록 ---
                const Text('내 업로드 (users/{uid}/uploads @ walkydb)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildUploadsList(),

                const Divider(height: 28),

                // --- 프로필 섹션 ---
                _buildProfileSection(),

                const Divider(height: 28),

                // --- 일기 섹션 ---
                _buildDiarySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
