import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bulssuk/quiz/quiz_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ReviewPage extends StatefulWidget {
  final FlutterSecureStorage storage;

  ReviewPage({required this.storage});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Map<String, dynamic>> _reviewData = [];
  bool _dataLoaded = false;
  final URL = dotenv.env['URL'];
  // final String apiUrl = dotenv.env['API_URL'] ?? 'https://default-url.com';
  // SQLite와 MongoDB에서 데이터 가져오기
  Future<void> fetchReviewData() async {
    try {
      final userId = await widget.storage.read(key: 'user_no') ??
          'unknown_user';
      final today = DateTime.now().toIso8601String().split('T')[0];

      // SQLite에서 진행 상황 가져오기
      final progress = await QuizDatabase.instance.getProgress(userId, today);
      print("SQLite 진행 상황: $progress");

      // MongoDB에서 모든 퀴즈 데이터 가져오기
      final response = await http.get(
          Uri.parse('$URL/quiz/review_quiz'));

      if (response.statusCode == 200) {
        final quizzes = json.decode(response.body)['quizzes'] as List;

        // SQLite 진행 상황과 MongoDB 퀴즈 데이터 매칭
        final reviewData = quizzes.map((quiz) {
          // SQLite 진행 상황에서 현재 퀴즈 ID에 해당하는 항목 찾기
          final progressItem = progress.firstWhere(
                (p) => p['quiz_id'] == quiz['id'],
            // SQLite의 quiz_id와 MongoDB의 id 매칭
            orElse: () =>
            {
              'quiz_id': quiz['id'], // 기본값 설정
              'is_correct': 0, // 틀림으로 처리
              'date': '알 수 없음', // 기본 날짜
            },
          );

          // 매칭 결과를 기준으로 데이터 반환
          return {
            'question': quiz['question'],
            'correctAnswer': quiz['answer'],
            'isCorrect': progressItem['is_correct'] == 1 ? '맞춤' : '틀림',
            'date': progressItem['date'],
          };
        }).toList();


        setState(() {
          _reviewData = reviewData;
          _dataLoaded = true;
        });

        print("최종 리뷰 데이터: $_reviewData");
      } else {
        print("퀴즈 데이터 가져오기 실패: 상태 코드 ${response.statusCode}");
        setState(() {
          _dataLoaded = false;
        });
      }
    } catch (e) {
      print("리뷰 데이터 가져오기 중 오류 발생: $e");
      setState(() {
        _dataLoaded = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchReviewData(); // 화면 초기화 시 데이터 가져오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 퀴즈 결과'),
      ),
      body: _dataLoaded
          ? ListView.builder(
        itemCount: _reviewData.length,
        itemBuilder: (context, index) {
          final item = _reviewData[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF9F3E5), // 연한 노란색 배경
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['question']}',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '정답: ${item['correctAnswer']}',
                  style: TextStyle(
                    color: Colors.grey, // 연한 회색
                  ),
                ),
                Text(
                  '결과: ${item['isCorrect']}',
                  style: TextStyle(
                    color: Colors.grey, // 연한 회색
                  ),
                ),
                Text(
                  '날짜: ${item['date']}',
                  style: TextStyle(
                    color: Colors.grey, // 연한 회색
                  ),
                ),
              ],
            ),
          );
        },
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
