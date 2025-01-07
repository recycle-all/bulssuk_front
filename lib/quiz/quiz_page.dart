import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bulssuk/quiz/review_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// SQLite Database 클래스
class QuizDatabase {
static final QuizDatabase instance = QuizDatabase._init();
static Database? _database;
QuizDatabase._init();

Future<Database> get database async {
if (_database != null) return _database!;
_database = await _initDB('quiz.db');
return _database!;
}

Future<Database> _initDB(String filePath) async {
final dbPath = await getDatabasesPath();
final path = join(dbPath, filePath);

return await openDatabase(
path,
version: 1,
onCreate: _createDB,
);
}

Future _createDB(Database db, int version) async {
await db.execute('''
      CREATE TABLE quiz_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        quiz_id INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        date TEXT NOT NULL
      );
    ''');
}

Future<void> saveProgress(String userId, int quizId, bool isCorrect) async {
final db = await instance.database;

try {
await db.insert('quiz_progress', {
'user_id': userId,
'quiz_id': quizId,
'is_correct': isCorrect ? 1 : 0,
'date': DateTime.now().toIso8601String().split('T')[0],
});
print("SQLite 저장 성공: user_id=$userId, quiz_id=$quizId, is_correct=$isCorrect");
} catch (e) {
print("SQLite 저장 실패: $e");
}
}

Future<List<Map<String, dynamic>>> getProgress(String userId, String date) async {
final db = await instance.database;

return await db.query(
'quiz_progress',
where: 'user_id = ? AND date = ?',
whereArgs: [userId, date],
);
}
}

// Flutter UI 및 기능 구현
class QuizPage extends StatefulWidget {
final FlutterSecureStorage storage;

QuizPage({required this.storage});

@override
_QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<dynamic> _quizzes = [];
  int _currentQuizIndex = 0;
  String _resultMessage = "";
  bool _quizLoaded = false;
  bool _isAnswered = false; // 답변 여부 상태 추가
  bool _allQuizzesCompleted = false; // 모든 퀴즈 완료 여부
  final URL = dotenv.env['URL'];

  Future<void> checkQuizCompletion() async {
    final userNo = await widget.storage.read(key: 'user_no') ?? '0';
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final progress = await QuizDatabase.instance.getProgress(userNo, today);
      final completedIds = progress.map((p) => p['quiz_id']).toSet();

      if (_quizzes.isNotEmpty &&
          _quizzes.every((quiz) => completedIds.contains(quiz['id']))) {
        setState(() {
          _allQuizzesCompleted = true; // 모든 퀴즈 완료 상태
        });
      }
    } catch (e) {
      print("퀴즈 진행 상태 확인 중 오류 발생: $e");
    }
  }

// 퀴즈 가져오기
  Future<void> fetchQuiz() async {
    try {
      final userNo = int.parse(
          await widget.storage.read(key: 'user_no') ?? '0');

      if (userNo == 0) {
        setState(() {
          _resultMessage = "사용자 No가 없습니다.";
        });
        return;
      }

// 서버에서 퀴즈 데이터 가져오기
      final response = await http.get(
          Uri.parse('$URL/quiz/daily_quiz/$userNo'));

      if (response.statusCode == 200) {
        final quizzes = json.decode(response.body)['quizzes'];

// SQLite에서 진행 상황 가져오기
        final progress = await QuizDatabase.instance.getProgress(
          userNo.toString(),
          DateTime.now().toIso8601String().split('T')[0],
        );
        final completedIds = progress.map((p) => p['quiz_id']).toSet();

// 완료되지 않은 퀴즈만 필터링
        final remainingQuizzes = quizzes.where((quiz) =>
        !completedIds.contains(quiz['id'])).toList();

        setState(() {
          _quizzes = remainingQuizzes;
          _currentQuizIndex = 0; // 퀴즈 인덱스 초기화
          _quizLoaded = _quizzes.isNotEmpty;
          _allQuizzesCompleted = _quizzes.isEmpty; // 퀴즈가 없으면 완료 상태로 설정

          if (!_quizLoaded) {
            _resultMessage = "오늘의 퀴즈를 모두 풀었습니다! 내일 다시 도전하세요 🤩";
          }
        });

        print("가져온 퀴즈: $_quizzes");
      } else {
        print(
            "HTTP 요청 실패: 상태 코드: ${response.statusCode}, 응답: ${response.body}");
        setState(() {
          _quizLoaded = false;
          _resultMessage = "퀴즈를 불러오는 데 실패했습니다. (상태 코드: ${response.statusCode})";
        });
      }
    } catch (e) {
      print("퀴즈 가져오기 중 에러 발생: $e");
      print("에러 타입: ${e.runtimeType}");
      print("에러 상세: $e");
      setState(() {
        _quizLoaded = false;
        _resultMessage = "퀴즈를 불러오는 중 오류가 발생했습니다. ($e)";
      });
    }
  }

// 정답 확인 및 진행 상황 저장
  void checkAnswer(String userAnswer) async {
    final currentQuiz = _quizzes[_currentQuizIndex];
    final isCorrect = userAnswer == currentQuiz['answer'];

    // SQLite에 진행 상황 저장
    final userNo = await widget.storage.read(key: 'user_no') ?? 'unknown_user';
    await QuizDatabase.instance.saveProgress(
      userNo,
      currentQuiz['id'],
      isCorrect,
    );

    // 서버로 진행 상황 전송
    final url = Uri.parse('$URL/quiz/submit_quiz');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userNo,
          'quizId': currentQuiz['id'],
          'isCorrect': isCorrect,
        }),
      );

      if (response.statusCode == 200) {
        print("퀴즈 진행 상황 서버 저장 성공: ${response.body}");
      } else {
        print("퀴즈 진행 상황 서버 저장 실패: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("퀴즈 진행 상황 서버 전송 중 오류 발생: $e");
    }

    // 포인트 추가: 정답일 경우만
    if (isCorrect) {
      await addPoint(userNo); // 추가된 함수 호출
    }

    // UI 업데이트
    setState(() {
      _isAnswered = true; // 답변 여부 상태 변경
      _resultMessage = isCorrect
          ? "정답입니다! 🎉"
          : "틀렸습니다! 정답은 ${currentQuiz['answer']} 입니다. ❌";
    });
  }

// 다음 퀴즈로 이동
  void moveToNextQuiz() {
    setState(() {
      if (_currentQuizIndex < _quizzes.length - 1) {
        _currentQuizIndex++; // 다음 퀴즈로 이동
        _isAnswered = false; // 답변 여부 초기화
        _resultMessage = ""; // 결과 메시지 초기화
      } else {
        _quizLoaded = false; // 모든 퀴즈 완료
        _allQuizzesCompleted = true; // 완료 상태로 설정
        _resultMessage = "모든 퀴즈를 완료했습니다!";
      }
    });
  }

  // 정답시 포인트 지급
  Future<void> addPoint(String userNo) async {
    final url = Uri.parse('$URL/quiz/addPoint'); // 백엔드의 addPoint API 경로

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_no': userNo, // 사용자 번호
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("포인트 추가 성공: ${responseBody['message']}, 총 포인트: ${responseBody['newTotal']}");
      } else {
        print("포인트 추가 실패: 상태 코드 ${response.statusCode}, 응답: ${response.body}");
      }
    } catch (e) {
      print("포인트 추가 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('환경 OX 퀴즈',
          style: TextStyle(
          fontSize: 18, // 텍스트 크기 조정
          color: Colors.black, // 텍스트 색상 변경
        ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 제목 및 설명
            Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '친환경 퀴즈 맞히고 포인트 받자!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '오늘의 친환경 퀴즈 🌱',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // 중앙 정렬 -> 상단 정렬로 변경
                  children: [
                    SizedBox(height: 190), // 상단 간격을 조절
                    if (!_quizLoaded && !_allQuizzesCompleted)
                      Column(
                        children: [
                          Text(
                            "퀴즈 가져오기 📘📗📕",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10), // 간격을 더 줄이면 텍스트와 버튼이 가까워짐
                          GestureDetector(
                            onTap: fetchQuiz,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.8),
                              ),
                              child: Center(
                                child: Icon(Icons.recycling_rounded,
                                    color: Colors.white, size: 40),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_quizLoaded)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0),
                            child: Text(
                              _quizzes[_currentQuizIndex]['question'],
                              style: TextStyle(fontSize: 20, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE08989),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 50.0,
                                  ),
                                ),
                                onPressed: _isAnswered ? null : () =>
                                    checkAnswer('X'),
                                child: Text(
                                  'X',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB0F4E6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 50.0,
                                  ),
                                ),
                                onPressed: _isAnswered ? null : () =>
                                    checkAnswer('O'),
                                child: Text(
                                  'O',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          if (_isAnswered && _resultMessage.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  _resultMessage,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFF9F3E5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 13.0,
                                      horizontal: 40.0,
                                    ),
                                  ),
                                  onPressed: moveToNextQuiz,
                                  child: Text(
                                    '다음 문제 풀기',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    if (_allQuizzesCompleted)
                      Column(
                        children: [
                          Text(
                            "완료!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "오늘의 퀴즈를 모두 풀었습니다.\n내일 다시 도전하세요🤩",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF9F3E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: 40.0,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewPage(storage: widget.storage),
                                ),
                              );
                            },
                            child: Text(
                              '오늘의 퀴즈 다시보기',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
