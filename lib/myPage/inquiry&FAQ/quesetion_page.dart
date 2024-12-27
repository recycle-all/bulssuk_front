import 'package:flutter/material.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class QuestionPage extends StatelessWidget {
  const QuestionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48), // AppBar + TabBar 높이
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TopNavigationSection(
                title: '문의하기',
              ),
              const TabBar(
                indicatorColor: Color(0xFF67EACA),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: '문의하기'),
                  Tab(text: '문의내역'),
                ],
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QuestionForm(), // 문의하기 화면
            QuestionHistory(), // 문의내역 확인 화면
          ],
        ),
      ),
    );
  }
}

class QuestionForm extends StatefulWidget {
  const QuestionForm({Key? key}) : super(key: key);

  @override
  _QuestionFormState createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _storage = const FlutterSecureStorage(); // Secure Storage 인스턴스 생성
  bool _isLoading = false;

  Future<void> _submitInquiry() async {
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();

    // 제목 글자 수 및 내용 입력 체크
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    if (title.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목은 20자 이내로 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Secure Storage에서 JWT 토큰 가져오기
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
        );
        return;
      }

      // 서버 API URL
      final url = Uri.parse('http://localhost:8080/inquiry');

      // 요청 데이터
      final Map<String, dynamic> requestData = {
        'question_title': title,
        'question_content': content,
      };

      // POST 요청
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // JWT 토큰 추가
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의가 성공적으로 등록되었습니다.')),
        );

        // 문의내역 탭으로 안전하게 이동
        final tabController = DefaultTabController.of(context);
        if (tabController != null) {
          tabController.animateTo(1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('문의내역으로 이동할 수 없습니다.')),
          );
        }
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? '등록에 실패했습니다.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      print('Error: $error');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 연결할 수 없습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 입력 필드
          TextField(
            controller: _titleController,
            maxLength: 20, // 최대 글자 수 제한
            decoration: InputDecoration(
              labelText: '제목을 입력해주세요. (20자 이내)',
              labelStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF67EACA), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // 내용 입력 필드
          Expanded(
            flex: 3,
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                labelText: '문의 내용을 입력해주세요.',
                labelStyle: const TextStyle(color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF67EACA), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // 등록하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitInquiry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB0F4E6),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                '등록하기',
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 문의내역 확인
class QuestionHistory extends StatelessWidget {
  const QuestionHistory({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchInquiries() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final url = Uri.parse('http://localhost:8080/get-inquiries');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['inquiries']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? '문의 내역을 가져올 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchInquiries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('문의 내역이 없습니다.'));
        }

        final inquiries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: inquiries.length,
          itemBuilder: (context, index) {
            final inquiry = inquiries[index];
            final isAnswered = inquiry['is_answered'] == true;

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inquiry['question_title'] ?? '제목 없음',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '문의 날짜: ${inquiry['created_at']}',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            isAnswered ? '답변 완료' : '답변 대기',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: isAnswered ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '문의 내용:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              inquiry['question_content'] ?? '내용 없음',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                            const SizedBox(height: 16.0),
                            const Text(
                              '관리자 답변:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              inquiry['answer_content'] ?? '답변이 아직 등록되지 않았습니다.',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}