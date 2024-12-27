import 'package:flutter/material.dart';
import 'home/home.dart';
import 'auth/login/login_page.dart';
import 'myPage/dashboard.dart';
import 'calendar/calendar_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycling',
      debugShowCheckedModeBanner: false, // 디버그 배너 숨김
      initialRoute: '/login', // 앱 시작 화면을 로그인 페이지로 설정
      routes: {
        '/': (context) => HomePage(), // HomePage 경로
        '/login': (context) => LoginPage(), // 로그인 화면 경로
        '/home': (context) => HomePage(),   // 홈 화면 경로
        '/dashboard': (context) => Dashboard(), // Dashboard 경로
        '/calendar': (context) => CalendarPage(), // 캘린더 페이지 경로
      },
    );
  }
}