// lib/full_doc_2.dart
import 'package:flutter/material.dart';

class FullDoc2 extends StatelessWidget {
  const FullDoc2({super.key});

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
                'Walky 개인정보 처리방침',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Walky(이하 “서비스”)는 이용자의 개인정보를 중요시하며, 「개인정보 보호법」 등 관련 법령을 준수합니다. 본 개인정보 처리방침은 서비스 이용 과정에서 수집되는 개인정보의 항목, 이용 목적, 보관 및 파기, 제3자 제공, 이용자의 권리 등을 명확히 안내하기 위해 마련되었습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '제1조 (처리하는 개인정보의 항목 및 목적)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스는 회원가입, 맞춤형 서비스 제공, 산책 기록 저장 및 통계 제공 등을 위해 다음과 같은 개인정보를 수집·이용합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildListItem('회원가입 및 계정관리 정보: 이메일, 닉네임, 비밀번호, 생년월일, 성별을 수집하며, 이는 회원 식별, 로그인, 계정 관리 목적에 사용됩니다.'),
            _buildListItem('서비스 이용 정보: 산책 시간, 거리, 경로, 통계, 앱 사용 기록을 수집하며, 이는 산책 기록 저장, 운동 통계 제공, 개인 맞춤 추천 제공을 위해 이용됩니다.'),
            _buildListItem('이용자 입력 정보: 설문 응답, 취향 정보, 사진, 일기 등을 수집하며, 이는 개인 맞춤 추천 제공과 다이어리 기능을 위해 이용됩니다.'),
            _buildListItem('위치정보: GPS와 네트워크 기반 위치 좌표를 수집하며, 이는 산책 경로 탐색, 실시간 안내, 기록 저장을 위해 이용됩니다. 산책 종료 후에는 시간, 거리 등 통계 정보로만 변환하여 저장하며, 원본 좌표는 즉시 파기될 수 있습니다.'),
            _buildListItem('고객 문의 및 피드백 정보: 이메일 주소 및 문의 내용을 수집하며, 이는 고객 응대와 서비스 개선을 위해 사용됩니다.'),
            const SizedBox(height: 24),
            const Text(
              '제2조 (개인정보의 보관 및 파기)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 개인정보 수집 목적이 달성된 경우 지체 없이 해당 정보를 파기합니다. 다만, 관련 법령에 따라 일정 기간 보관이 필요한 경우에는 해당 기간 동안 안전하게 보관합니다.'),
            _buildListItem('전자적 파일은 복구가 불가능한 방법으로 삭제하며, 종이 문서는 분쇄 또는 소각을 통해 파기합니다.'),
            const SizedBox(height: 24),
            const Text(
              '제3조 (개인정보의 제3자 제공)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 서비스 제공을 위해 불가피하게 제3자에게 제공될 수 있습니다.'),
            _buildListItem('예를 들어, 네이버·카카오·구글 등 지도 API 제공업체에는 위치 좌표가 제공될 수 있으며, 이는 지도 표시 및 경로 탐색을 위한 목적으로만 사용됩니다.'),
            _buildListItem('또한 Firebase(Google LLC)에는 계정 정보 및 서비스 이용 기록이 저장될 수 있으며, 이는 데이터 저장 및 백엔드 운영 목적에만 사용됩니다. 이 경우, 해당 정보는 회원 탈퇴 시 또는 계약 종료 시 즉시 파기됩니다.'),
            const SizedBox(height: 24),
            const Text(
              '제4조 (개인정보 처리 위탁)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('서비스는 원활한 운영을 위해 일부 업무를 외부 서비스에 위탁할 수 있습니다. 위탁 대상은 Firebase와 같은 데이터베이스 및 인증 서비스, 지도 API 제공업체 등이 있으며, 위탁받은 자는 개인정보를 해당 목적 범위 내에서만 처리합니다.'),
            const SizedBox(height: 24),
            const Text(
              '제5조 (이용자의 권리와 행사 방법)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('이용자는 언제든지 자신의 개인정보에 대해 열람, 정정, 삭제, 처리정지, 동의 철회를 요구할 수 있습니다.'),
            _buildListItem('이러한 요구는 앱 설정 기능을 통해 직접 처리하거나, 서비스 담당자 이메일을 통해 요청할 수 있으며, 서비스는 지체 없이 필요한 조치를 취합니다.'),
            const SizedBox(height: 24),
            const Text(
              '제6조 (개인정보의 안전성 확보 조치)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('비밀번호는 암호화하여 저장합니다.'),
            _buildListItem('개인정보 접근 권한을 최소화하여 관리합니다.'),
            _buildListItem('보안 프로그램을 설치하고 주기적으로 점검합니다.'),
            const SizedBox(height: 24),
            const Text(
              '제7조 (개인정보 보호책임자)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('개인정보 보호책임자: Walky 프로젝트 팀'),
            _buildListItem('이메일: walky.project0@gmail.com'),
            const SizedBox(height: 24),
            const Text(
              '제8조 (개인정보 처리방침의 변경)',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            _buildListItem('본 방침은 법령이나 서비스 정책 변경에 따라 수정될 수 있으며, 개정 시 앱 내 공지사항 또는 별도의 고지를 통해 안내합니다.'),
            const SizedBox(height: 24),
            const Text(
              '부칙',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold), // 기존 18 + 5
            ),
            const SizedBox(height: 8),
            Text(
              '본 개인정보 처리방침은 2025년 9월 1일부터 적용됩니다.',
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