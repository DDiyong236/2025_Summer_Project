import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walky/services/firestore_manager.dart';
import 'package:walky/services/google_auth_service.dart';
import 'package:walky/services/firebase_storage_manager.dart';
import 'package:walky/route_map_page.dart'; // ⭐️ 카카오맵 페이지 import
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final DiaryService _diaryService = DiaryService();

  // 텍스트 필드용 컨트롤러
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _statusMessageController = TextEditingController();
  final TextEditingController _diaryTitleController = TextEditingController();
  final TextEditingController _diaryContentController = TextEditingController();
  final TextEditingController _courseIdController = TextEditingController();

  String _statusMessage = '로그인 상태: 로그아웃됨';
  String? _jsonFileUrl;
  String _downloadedJson = '';

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        setState(() {
          _statusMessage = '로그인됨: ${user.displayName}';
        });
      } else {
        setState(() {
          _statusMessage = '로그아웃됨';
        });
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusMessageController.dispose();
    _diaryTitleController.dispose();
    _diaryContentController.dispose();
    _courseIdController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      setState(() {
        _statusMessage = '로그인 성공!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '로그인 실패: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _statusMessage = '로그아웃 성공!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '로그아웃 실패: $e';
      });
    }
  }

  Future<void> _addFirestoreProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'Firestore에 추가하려면 먼저 로그인하세요.';
      });
      return;
    }

    try {
      await _userProfileService.createORUpdateProfile(
        nickname: _nicknameController.text,
        statusMessage: _statusMessageController.text,
        isCreate: true,
      );
      setState(() {
        _statusMessage = 'Firestore 프로필 추가 성공!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Firestore 프로필 추가 실패: $e';
      });
    }
  }

  Future<void> _addDiary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = '다이어리에 추가하려면 먼저 로그인하세요.';
      });
      return;
    }

    try {
      await _diaryService.addDiary(
        diaryTitle: _diaryTitleController.text,
        body: _diaryContentController.text,
      );
      setState(() {
        _statusMessage = '다이어리 추가 성공!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '다이어리 추가 실패: $e';
      });
    }
  }

  Future<void> _uploadJson() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'Cloud Storage에 업로드하려면 먼저 로그인하세요.';
      });
      return;
    }

    final String courseId = _courseIdController.text.trim();
    if (courseId.isEmpty) {
      setState(() {
        _statusMessage = 'Course ID를 입력해주세요.';
      });
      return;
    }

    try {
      const apiUrl = 'http://172.31.64.223:5123/api/recommend';
      final body = {
        "tag": "river",
        "start_text": "죽전역",
        "dest_text": "오리역",
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final String jsonData = response.body;
        final String fileName = 'api_course_$courseId';
        final fileUrl = await uploadJsonToFirebaseStroage(
          userId: user.uid,
          fileName: fileName,
          jsonData: jsonData,
        );

        if (fileUrl != null) {
          setState(() {
            _jsonFileUrl = fileUrl;
            _statusMessage = 'API로부터 JSON 가져와서 업로드 성공!';
          });
        } else {
          setState(() {
            _statusMessage = '파일 업로드 실패';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'API 호출 실패: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'API 연결 오류: $e';
      });
    }
  }

  Future<void> _showDownloadDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = '다운로드하려면 먼저 로그인하세요.';
      });
      return;
    }

    final String userCourseId = _courseIdController.text.trim();

    setState(() {
      _statusMessage = '파일 목록을 가져오는 중...';
    });

    final fileUrls = await listJsonFiles(user.uid);

    if (!mounted) return;

    final filteredUrls = userCourseId.isEmpty
        ? fileUrls
        : fileUrls.where((url) {
      final decodedUrl = Uri.decodeComponent(url);
      final decodedFileName = decodedUrl.split('/').last.split('?').first;
      return decodedFileName.contains(userCourseId);
    }).toList();

    if (filteredUrls.isEmpty) {
      setState(() {
        _statusMessage = '입력한 이름의 코스가 없거나 다운로드할 코스가 없습니다.';
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('코스 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredUrls.length,
              itemBuilder: (context, index) {
                final url = filteredUrls[index];
                final decodedUrl = Uri.decodeComponent(url);
                final decodedFileNameWithExtension = decodedUrl.split('/').last.split('?').first;

                String courseName = decodedFileNameWithExtension;
                if (courseName.startsWith('api_course_') && courseName.endsWith('.json')) {
                  courseName = courseName.substring('api_course_'.length, courseName.length - '.json'.length);
                }

                return ListTile(
                  title: Text(courseName),
                  onTap: () async {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KakaoRouteFlutterPage(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기능 테스트 페이지'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_statusMessage, style: const TextStyle(fontSize: 16)),
            const Divider(),
            _buildSection(
              title: '구글 로그인/로그아웃',
              buttons: [
                _buildButton(text: '구글 로그인', onPressed: _signInWithGoogle),
                const SizedBox(height: 10.0),
                _buildButton(text: '로그아웃', onPressed: _signOut),
              ],
            ),
            _buildSection(
              title: 'Firestore 테스트: 유저 프로필',
              buttons: [
                _buildTextField(controller: _nicknameController, label: '닉네임'),
                _buildTextField(controller: _statusMessageController, label: '상태 메시지'),
                _buildButton(text: '프로필 추가/수정', onPressed: _addFirestoreProfile),
              ],
            ),
            _buildSection(
              title: 'Firestore 테스트: 다이어리',
              buttons: [
                _buildTextField(controller: _diaryTitleController, label: '다이어리 제목'),
                _buildTextField(controller: _diaryContentController, label: '다이어리 내용', maxLines: 5),
                _buildButton(text: '다이어리 추가', onPressed: _addDiary),
              ],
            ),
            _buildSection(
              title: 'Cloud Storage 테스트',
              buttons: [
                _buildTextField(controller: _courseIdController, label: '코스 ID (파일 이름)'),
                _buildButton(text: 'JSON 파일 업로드', onPressed: _uploadJson),
                const SizedBox(height: 10.0),
                _buildButton(text: 'JSON 파일 다운로드', onPressed: _showDownloadDialog),
              ],
            ),
            if (_downloadedJson.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('다운로드된 JSON 데이터:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _downloadedJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> buttons}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: buttons.length,
          itemBuilder: (context, index) => buttons[index],
          separatorBuilder: (context, index) => const SizedBox(height: 10.0),
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text),
    );
  }
}