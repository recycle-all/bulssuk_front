import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class ResetPasswordPage extends StatefulWidget {
  final String userId;

  ResetPasswordPage({required this.userId});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordEmpty = false;
  bool _isConfirmPasswordEmpty = false;
  bool _isPasswordMismatch = false;
  bool _isLoading = false;

  // 비밀번호 재설정 요청
  void _resetPassword() async {
    setState(() {
      _isPasswordEmpty = _newPasswordController.text.isEmpty;
      _isConfirmPasswordEmpty = _confirmPasswordController.text.isEmpty;
      _isPasswordMismatch =
          _newPasswordController.text != _confirmPasswordController.text;
    });

    if (_isPasswordEmpty || _isConfirmPasswordEmpty || _isPasswordMismatch) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newPassword = _newPasswordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
        );
        Navigator.popUntil(context, (route) => route.isFirst); // 로그인 화면으로 이동
      } else {
        final responseBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? "비밀번호 변경 실패")),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '비밀번호 재설정',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),

            // 새 비밀번호 입력 필드
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호 입력',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: _isPasswordEmpty ? Colors.red : Color(0xFFCCCCCC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isPasswordEmpty ? Colors.red : Color(0xFF67EACA),
                    width: 2,
                  ),
                ),
                errorText: _isPasswordEmpty ? '비밀번호를 입력해주세요.' : null,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),

            // 비밀번호 확인 입력 필드
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: _isConfirmPasswordEmpty || _isPasswordMismatch
                          ? Colors.red
                          : Color(0xFFCCCCCC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isConfirmPasswordEmpty || _isPasswordMismatch
                        ? Colors.red
                        : Color(0xFF67EACA),
                    width: 2,
                  ),
                ),
                errorText: _isConfirmPasswordEmpty
                    ? '비밀번호 확인을 입력해주세요.'
                    : _isPasswordMismatch
                    ? '비밀번호가 일치하지 않습니다.'
                    : null,
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),

            // 비밀번호 재설정 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0F4E6),
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2.0,
              )
                  : Text(
                '비밀번호 재설정',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}