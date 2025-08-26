// lib/full_doc_1.dart
import 'package:flutter/material.dart';

class FullDoc1 extends StatelessWidget {
  const FullDoc1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''), // 제목을 Body로 옮겼으므로 비워둡니다.
        backgroundColor: Colors.white, // 배경색 흰색 설정
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center( // ✅ Center 위젯으로 감싸서 제목을 가운데 정렬
              child: const Text(
                'Walky 서비스 이용 약관',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Walky(이하 "서비스")는 이용자가 본 서비스를 이용함에 있어 필요한 권리, 의무 및 책임 사항을 규정하기 위해 본 약관을 제정합니다. 본 서비스는 대학생 개인 프로젝트 성격으로 운영되며, 무료로 제공됩니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제1조 (목적)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '본 약관은 서비스의 이용 조건, 절차, 이용자와 서비스 제공자 간의 권리와 의무, 책임 사항 등 기본적인 사항을 규정함을 목적으로 합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제2조 (서비스의 내용)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스는 무료로 제공되며, 주요 기능은 다음과 같습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('개인 취향 기반 산책 코스 추천'),
            _buildListItem('위치 기반 경로 안내 및 오디오 알림 제공'),
            _buildListItem('산책 기록 저장 및 운동 통계 제공'),
            _buildListItem('사진·일기 등 다이어리 작성 및 관리'),
            _buildListItem('캘린더·피드 형식의 기록 열람'),
            _buildListItem('알림 및 동기부여 메시지 제공'),
            const SizedBox(height: 12),
            const Text(
              '서비스 제공자는 필요 시 서비스의 일부 또는 전부를 변경하거나 중단할 수 있습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제3조 (회원가입 및 이용 제한)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '이용자는 약관에 동의한 후 회원가입을 신청할 수 있습니다. 다만, 다음과 같은 경우 회원가입 또는 이용이 제한될 수 있습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('타인의 명의를 도용하거나 허위 정보를 기재한 경우'),
            _buildListItem('법령이나 본 약관을 위반하는 경우'),
            _buildListItem('서비스의 정상적인 운영을 방해하거나 악용하는 경우'),
            const SizedBox(height: 24),
            const Text(
              '제4조 (이용자의 의무)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '이용자는 본 서비스 이용 시 다음 사항을 준수해야 합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('관련 법령, 본 약관 및 서비스 운영 정책을 준수해야 합니다.'),
            _buildListItem('타인의 권리를 침해하는 행위를 해서는 안 됩니다.'),
            _buildListItem('불법적·부적절한 사진, 텍스트, 음성 등을 업로드해서는 안 됩니다.'),
            const SizedBox(height: 24),
            const Text(
              '제5조 (콘텐츠 권리와 사용)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('이용자가 작성한 사진, 일기 등 콘텐츠의 저작권은 이용자에게 있습니다.'),
            _buildListItem('서비스 제공자는 서비스 운영, 개선, 신규 기능 개발, 비상업적 홍보 목적으로 콘텐츠를 활용할 수 있습니다.'),
            _buildListItem('서비스 제공자는 법령 위반이나 불법 콘텐츠가 발견될 경우 사전 통보 없이 삭제할 수 있습니다.'),
            const SizedBox(height: 24),
            const Text(
              '제6조 (서비스의 변경 및 종료)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스 제공자는 필요에 따라 서비스의 일부 또는 전부를 변경하거나 종료할 수 있으며, 가능한 경우 사전에 공지합니다. 다만 개인 프로젝트 특성상 사전 고지 없이 종료될 수 있습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제7조 (책임의 제한)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 개인 프로젝트로 제공되며, 안정성·연속성·정확성에 대하여 보증하지 않습니다.'),
            _buildListItem('서비스 이용으로 발생한 손해에 대해 서비스 제공자는 법령에 특별히 정한 경우를 제외하고 책임을 지지 않습니다.'),
            const SizedBox(height: 24),
            const Text(
              '제8조 (분쟁 해결 및 준거법)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '본 약관은 대한민국 법령을 준거법으로 하며, 서비스와 관련하여 분쟁이 발생할 경우 민사소송법 등 관련 법령에 따릅니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '부칙',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '본 서비스 이용약관은 2025년 9월 1일부터 적용됩니다.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}