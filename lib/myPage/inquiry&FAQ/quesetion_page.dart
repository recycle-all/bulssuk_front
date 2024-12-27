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

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> inquiries = [
      {
        'title': '회원 탈퇴 문의',
        'date': '2024-12-27',
        'content': '회원 탈퇴 절차에 대해 알고 싶습니다. 더 자세한 정보가 필요합니다. 장황한 질문이 들어갈 경우에도 표시가 되어야 합니다.',
        'response': '회원 탈퇴는 설정 메뉴에서 직접 진행 가능합니다. 문제가 발생하면 고객센터에 문의해주세요.',
        'status': '답변 완료'
      },
      {
        'title': '서비스 이용 문의',
        'date': '2024-12-26',
        'content': '앱에서 알림 설정이 안 되는 문제에 대해 문의드립니다. 업데이트 후에도 설정이 적용되지 않는 경우를 설명합니다.',
        'response': '알림 설정은 최신 버전으로 업데이트 후 가능합니다. 지속적인 문제가 발생하면 버그 리포트를 보내주세요.',
        'status': '답변 완료'
      },
      {
        'title': '기타 문의',
        'date': '2024-12-25',
        'content': '기타 문의 사항이 있습니다. 답변 부탁드립니다.',
        'response': '',
        'status': '답변 대기'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: inquiries.length,
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        final status = inquiry['status']!;
        final isAnswered = status == '답변 완료';

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // 선 제거
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
                            inquiry['title']!,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '문의 날짜: ${inquiry['date']}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
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
                            status,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: isAnswered ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                      ],
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
                          inquiry['content']!,
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
                          inquiry['response']!.isNotEmpty
                              ? inquiry['response']!
                              : '답변이 아직 등록되지 않았습니다.',
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
  }
}