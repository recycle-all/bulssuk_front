import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bulssuk/auth/login/reset_password_page.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class FindPasswordPage extends StatefulWidget {
  @override
  _FindPasswordPageState createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isIdEmpty = false;
  bool _isEmailEmpty = false;
  bool _isCodeEmpty = false;
  bool _isLoading = false;

  int _remainingTime = 0; // 남은 시간 (초)
  Timer? _timer; // 타이머 객체

  // 이메일 인증 요청
  void _sendVerificationCode() async {
    if (_emailController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _startCountdown(); // 카운트다운 시작
      });

      final email = _emailController.text;

      try {
        final response = await http.post(
          Uri.parse('http://localhost:8080/password-email-auth'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("인증 코드가 이메일로 발송되었습니다.")),
          );
        } else {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? "인증 코드 발송 실패")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("서버와의 통신 중 오류가 발생했습니다.")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isEmailEmpty = true;
      });
    }
  }

  // 카운트다운 타이머 시작
  void _startCountdown() {
    setState(() {
      _remainingTime = 300; // 5분 = 300초
    });

    _timer?.cancel(); // 기존 타이머 정리
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // 시간 형식 변환
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 인증번호 확인 요청
  void _verifyCode() async {
    if (_codeController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final code = _codeController.text;

      try {
        final response = await http.post(
          Uri.parse('http://localhost:8080/password-verify-number'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'code': code,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("인증이 완료되었습니다.")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(userId: _idController.text),
            ),
          );
        } else {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? "인증 실패")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("서버와의 통신 중 오류가 발생했습니다.")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isCodeEmpty = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '비밀번호 찾기',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            // 아이디 입력 필드
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: '아이디 입력',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFF67EACA),
                    width: 2,
                  ),
                ),
                errorText: _isIdEmpty ? '아이디를 입력해주세요.' : null,
              ),
            ),
            SizedBox(height: 20),

            // 이메일 입력 필드 + 인증 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일 입력',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xFF67EACA),
                          width: 2,
                        ),
                      ),
                      errorText: _isEmailEmpty ? '이메일을 입력해주세요.' : null,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0F4E6),
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '인증',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // 타이머 표시
            if (_remainingTime > 0)
              Text(
                "남은 인증 유효 시간: ${_formatTime(_remainingTime)}",
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),

            SizedBox(height: 20),

            // 인증번호 입력 필드 + 확인 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: '인증번호 입력',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xFF67EACA),
                          width: 2,
                        ),
                      ),
                      errorText: _isCodeEmpty ? '인증번호를 입력해주세요.' : null,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0F4E6),
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // 다음 버튼
            ElevatedButton(
              onPressed: () {
                if (_idController.text.isEmpty ||
                    _emailController.text.isEmpty ||
                    _codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("모든 필드를 입력해주세요.")),
                  );
                  return;
                }

                // 비밀번호 재설정 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordPage(userId: _idController.text),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0F4E6),
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}