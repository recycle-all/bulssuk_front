import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for json decoding
import '../../widgets/top_nav.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  List<dynamic> _faqData = []; // FAQ 데이터를 저장할 리스트
  bool _isLoading = true; // 로딩 상태
  String? _errorMessage; // 에러 메시지

  @override
  void initState() {
    super.initState();
    _fetchFAQData(); // 위젯 초기화 시 FAQ 데이터 가져오기
  }

  // FAQ 데이터를 서버에서 가져오는 함수
  Future<void> _fetchFAQData() async {
    try {
      final response = await http.get(
        Uri.parse('http://222.112.27.120:8001/view_faq'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _faqData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load FAQs';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '자주묻는질문 (FAQ)',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!)) // 에러 메시지 표시
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _faqData.length,
        itemBuilder: (context, index) {
          final section = _faqData[index];
          return _buildFAQSection(section);
        },
      ),
    );
  }

  // 섹션 빌더
  Widget _buildFAQSection(dynamic section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(section['title']), // 섹션 제목
        ...section['questions'].map<Widget>((question) {
          return _buildQuestionItem(question);
        }).toList(),
      ],
    );
  }

  // 섹션 제목 빌더
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // 패딩 추가
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
  Widget _buildQuestionItem(dynamic question) {
    return ExpansionTile(
      title: Text(
        'Q: ${question['question']}',
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'A: ${question['answer']}',
            style: const TextStyle(fontSize: 14.0, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
