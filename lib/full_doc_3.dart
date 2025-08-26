// lib/full_doc_3.dart
import 'package:flutter/material.dart';

class FullDoc3 extends StatelessWidget {
  const FullDoc3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''), // 제목을 Body로 옮겼으므로 비워둠
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
                'Walky 위치정보 이용 동의',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Walky(이하 “서비스”)는 「위치정보의 보호 및 이용 등에 관한 법률」 등 관련 법령을 준수하며, 서비스 제공을 위하여 이용자의 위치정보를 수집·이용합니다. 본 위치정보 이용 동의서는 위치정보 처리 목적, 보관 및 파기, 제3자 제공 등 주요 사항을 안내합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제1조 (위치정보의 수집 항목과 목적)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스는 다음과 같은 위치정보를 수집합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('GPS 기반 위치 좌표'),
            _buildListItem('네트워크(Wi-Fi, 기지국 등) 기반 위치 좌표'),
            const SizedBox(height: 12),
            const Text(
              '수집된 위치정보는 다음 목적에 사용됩니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('실시간 산책 경로 탐색 및 안내 제공'),
            _buildListItem('개인 맞춤 산책 코스 추천'),
            _buildListItem('이동 거리 및 시간 계산 등 산책 기록 저장'),
            const SizedBox(height: 24),
            const Text(
              '제2조 (위치정보의 보관 및 파기)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 산책 종료 후 위치정보를 즉시 통계 데이터(거리, 시간 등)로 변환하여 보관하며, 원본 위치 좌표는 지체 없이 파기합니다.'),
            _buildListItem('이용자가 회원 탈퇴를 요청할 경우, 모든 위치정보 기록은 즉시 파기됩니다.'),
            const SizedBox(height: 24),
            const Text(
              '제3조 (위치정보의 제3자 제공)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 원칙적으로 위치정보를 제3자에게 제공하지 않습니다.'),
            _buildListItem('다만, 지도 표시 및 경로 탐색 기능을 위해 네이버, 카카오, 구글 등 지도 API 제공업체에 위치 좌표가 전달될 수 있습니다. 이 경우 제공된 정보는 해당 목적 외에는 사용되지 않습니다.'),
            const SizedBox(height: 24),
            const Text(
              '제4조 (이용자의 권리)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildListItem('이용자는 언제든지 단말기 설정을 통해 위치정보 수집·이용에 대한 동의를 철회할 수 있습니다.'),
            _buildListItem('동의를 철회할 경우 산책 코스 추천, 경로 안내 등의 서비스 일부가 제한될 수 있습니다.'),
            const SizedBox(height: 24),
            const Text(
              '제5조 (책임의 제한)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 위치정보의 정확성과 연속성을 보장하지 않으며, 위치정보 오류로 인한 불이익에 대해서는 책임을 지지 않습니다.'),
            const SizedBox(height: 24),
            const Text(
              '부칙',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            Text(
              '본 위치정보 이용 동의서는 2025년 9월 1일부터 적용됩니다.',
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