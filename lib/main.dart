import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'services/firebase_options.dart';

import 'services/tts_manager.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_manager.dart';
import 'services/firebase_db.dart'; // ✅ walkydb 전용 db

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ walkydb 인스턴스에 옵션 적용 (오프라인 캐시 등)
    db.settings = const Settings(persistenceEnabled: true);

    return MaterialApp(
      title: 'Firebase: Storage + Firestore (walkydb)',
      home: ImageUploadPage(),
    );
  }
}

class ImageUploadPage extends StatefulWidget {
  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  // --- 기존 업로드/로그인/TTS ---
  File? _image;
  String? _downloadUrl;
  late final TTSManager _tts;
  late final AuthService _auth;
  final TextEditingController _captionController = TextEditingController();

  // --- Todo 전용 ---
  final _todoSvc = TodoService();
  final TextEditingController _todoTextController = TextEditingController();

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
    _todoTextController.dispose();
    super.dispose();
  }

  // ---------- 이미지 업로드 ----------
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

    await _saveUploadMetaToFirestore(downloadUrl: url, caption: _captionController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('업로드 & Firestore 저장 완료 (walkydb)')),
    );
  }

  // ✅ 업로드 메타데이터 저장: walkydb 의 users/{uid}/uploads
  Future<void> _saveUploadMetaToFirestore({
    required String downloadUrl,
    String? caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 후 Firestore에 업로드 기록 저장')),
        );
      }
      return;
    }

    final uid = user.uid;
    final col = db.collection('users').doc(uid).collection('uploads');

    await col.add({
      'url': downloadUrl,
      'caption': caption ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _captionController.clear();
  }

  // ✅ walkydb에서 내 업로드 목록 구독
  Widget _buildUploadsList() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('로그인 후 내 업로드 기록을 볼 수 있어요.'),
      );
    }

    final uid = user.uid;
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

  // ---------- Todo ----------
  Future<void> _addTodo() async {
    final text = _todoTextController.text.trim();
    if (text.isEmpty) return;
    await _todoSvc.add(text);
    _todoTextController.clear();
  }

  Widget _buildTodoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Todos (walkydb)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _todoTextController,
                decoration: const InputDecoration(
                  hintText: '할 일을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addTodo(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addTodo, child: const Text('추가')),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Todo>>(
          stream: _todoSvc.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('등록된 할 일이 없어요'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final t = items[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  background: Container(color: Colors.red.withOpacity(0.2)),
                  onDismissed: (_) => _todoSvc.delete(t.id),
                  child: CheckboxListTile(
                    value: t.done,
                    title: Text(t.title),
                    subtitle: Text(t.createdAt.toLocal().toString()),
                    onChanged: (v) => _todoSvc.setDone(t.id, v ?? false),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _auth.currentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase: Storage + Firestore (walkydb)')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 이미지 업로드 영역 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _uploadImage, child: const Text('Upload')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_image != null)
                  Center(child: Image.file(_image!, height: 180)),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _tts.speak("이동근 바보 "),
                      child: const Text('음성 안내'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final cred = await _auth.signInWithGoogle();
                          final user = cred.user;
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('로그인 성공: ${user?.displayName ?? user?.email}')),
                          );
                          setState(() {});
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('로그인 실패: $e')),
                          );
                        }
                      },
                      child: const Text('Google 로그인'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그아웃 완료')),
                        );
                        setState(() {});
                      },
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loggedIn
                      ? '환영합니다, ${_auth.currentUser!.displayName ?? _auth.currentUser!.email}'
                      : '로그인 안 됨',
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 28),

                // --- Firestore: 내 업로드 목록 ---
                const Text('내 업로드 (users/{uid}/uploads @ walkydb)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildUploadsList(),

                const Divider(height: 28),

                // --- Firestore: Todo 영역 ---
                _buildTodoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}