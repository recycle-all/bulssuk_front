import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 패키지
import 'home/home.dart';
import 'auth/login/login_page.dart';
import 'myPage/dashboard.dart';
import 'calendar/calendar_page.dart';
import 'quiz/quiz_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'calendar/alarm_page.dart';
final _storage = const FlutterSecureStorage(); // Secure Storage 인스턴스 생성
void main() async {
  // 비동기 작업 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 로드
  await dotenv.load();
  // 시간대 초기화
  await initializeAlarmNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // .env 파일에서 가져온 값 확인 (디버그용)
    final apiUrl = dotenv.env['URL'] ?? 'URL not found';
    print('Loaded URL: $apiUrl');

    return MaterialApp(

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 전체 배경색 설정
      ),

      title: 'Recycling',
      debugShowCheckedModeBanner: false, // 디버그 배너 숨김
      initialRoute: '/login', // 앱 시작 화면을 로그인 페이지로 설정
      routes: {
        '/': (context) => HomePage(), // HomePage 경로
        '/login': (context) => LoginPage(), // 로그인 화면 경로
        '/home': (context) => HomePage(), // 홈 화면 경로
        '/dashboard': (context) => Dashboard(), // Dashboard 경로
        '/calendar': (context) => CalendarPage(), // 캘린더 페이지 경로
        '/quiz': (context) => QuizPage(storage: _storage), // 퀴즈 페이지 경로
      },
    );
  }
}
