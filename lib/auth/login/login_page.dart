import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'find_id_page.dart'; // 아이디 찾기 페이지 import
import 'find_password_page.dart'; // 비밀번호 찾기 페이지 import
import '../join/agreement_page.dart'; // 회원가입 페이지 import
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = const FlutterSecureStorage(); // Secure Storage 인스턴스 생성
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginFailed = false; // 로그인 실패 상태

  Future<void> login() async {
    final url = Uri.parse('http://localhost:8080/user_login'); // 서버 로그인 엔드포인트

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _emailController.text,
          'user_pw': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 서버 응답에서 필요한 데이터 추출
        final token = data['token'];
        final userId = data['userId'];
        final name = data['name'];
        final email = data['email'];

        if (name == null || email == null || userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("서버로부터 불완전한 데이터를 받았습니다.")),
          );
          return;
        }

        // Secure Storage에 저장
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_id', value: userId);
        await _storage.write(key: 'user_name', value: name);
        await _storage.write(key: 'user_email', value: email);

        // 저장된 데이터 디버깅 출력
        print('Secure Storage 저장 완료:');
        print('User ID: $userId');
        print('Name: $name');
        print('Email: $email');

        // 로그인 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인 성공!")),
        );

        // 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _isLoginFailed = true; // 로그인 실패 상태 설정
        });
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $error")),
        );
      }
    } catch (error) {
      // 네트워크 또는 서버 오류 처리
      setState(() {
        _isLoginFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서버와 연결할 수 없습니다.")),
      );
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '로그인',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 자리
            SizedBox(
              height: 200,
              child: Placeholder(), // 이미지 대신 자리 잡기
            ),
            const SizedBox(height: 40),
            // 아이디 입력 필드
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '아이디 입력',
                labelStyle: const TextStyle(
                  color: Colors.black,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFCCCCCC),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF67EACA),
                    width: 2,
                  ),
                ),
                errorText: _isLoginFailed
                    ? '등록되지 않은 아이디 이거나, 아이디가 올바르지 않습니다.'
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // 비밀번호 입력 필드
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호 입력',
                labelStyle: const TextStyle(
                  color: Colors.black,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFCCCCCC),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF67EACA),
                    width: 2,
                  ),
                ),
                errorText: _isLoginFailed
                    ? '아이디 또는 비밀번호가 일치하지 않습니다.'
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            // 로그인 버튼
            ElevatedButton(
              onPressed: login, // 로그인 요청 함수
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB0F4E6),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '로그인',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 하단 링크 (아이디 찾기 | 비밀번호 찾기 | 회원가입)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 아이디 찾기 및 비밀번호 찾기
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FindIdPage()),
                        );
                      },
                      child: const Text(
                        '아이디 찾기',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const Text('|', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FindPasswordPage()),
                        );
                      },
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                // 회원가입
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AgreementPage()),
                    );
                  },
                  child: const Text(
                    '회원가입',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}