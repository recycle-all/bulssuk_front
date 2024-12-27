import 'package:flutter/material.dart';
import '../../widgets/top_nav.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '자주묻는질문 (FAQ)',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 분리수거 섹션
          _buildSectionTitle('분리수거'),
          _buildQuestionItem('Q: 플라스틱 병의 뚜껑은 어떻게 처리하나요?'),
          _buildQuestionItem('Q: 우유팩은 어떻게 분리수거하나요?'),

          // 앱 이용 방법 관련 섹션
          _buildSectionTitle('앱 이용 방법 관련'),
          _buildQuestionItem('Q: 어떻게 분리수거 정보를 검색할 수 있나요?'),
          _buildQuestionItem('Q: 분리수거 알림은 어떻게 설정하나요?'),

          // 재활용 관련 섹션
          _buildSectionTitle('재활용 관련'),
          _buildQuestionItem('Q: 폐가전제품은 분리수거가 가능한가요?'),
        ],
      ),
    );
  }

  // 섹션 제목 빌더
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  // 질문 아이템 빌더
  Widget _buildQuestionItem(String question) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '답변 내용이 여기에 표시됩니다. 필요한 정보를 여기에 추가하세요.',
            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}