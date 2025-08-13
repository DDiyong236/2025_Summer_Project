import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

import 'tts_manager.dart';
import 'google_auth_service.dart';

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
    return MaterialApp(
      title: 'Firebase Storage Demo',
      home: ImageUploadPage(),
    );
  }
}

class ImageUploadPage extends StatefulWidget {
  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _image;
  String? _downloadUrl;

  late final TTSManager _tts;
  late final AuthService _auth;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Storage Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Text('No image selected.'),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
            ElevatedButton(onPressed: _uploadImage, child: Text('Upload')),
            ElevatedButton(
              onPressed: () {
                _tts.speak("이동근 바보 "); // 네가 쓰던 문구 그대로 유지
              },
              child: Text('음성 안내'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final cred = await _auth.signInWithGoogle();
                  final user = cred.user;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 성공: ${user?.displayName ?? user?.email}')),
                  );
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 실패: $e')),
                  );
                }
              },
              child: Text('Google 로그인'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('로그아웃 완료')),
                );
                setState(() {});
              },
              child: Text('로그아웃'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_auth.currentUser == null
                  ? '로그인 안 됨'
                  : '환영합니다, ${_auth.currentUser!.displayName ?? _auth.currentUser!.email}'),
            ),
            if (_downloadUrl != null) ...[
              SizedBox(height: 20),
              Text('Uploaded to:'),
              SelectableText(_downloadUrl!),
            ]
          ],
        ),
      ),
    );
  }
}
