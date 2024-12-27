import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart';

class UpdateProfile extends StatefulWidget {
  final String email;
  final String name;
  final String userId;

  const UpdateProfile({
    Key? key,
    required this.email,
    required this.name,
    required this.userId,
  }) : super(key: key);

  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 비밀번호 업데이트 함수
  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = '모든 필드를 입력해주세요.';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '새 비밀번호와 확인이 일치하지 않습니다.';
      });
      return;
    }

    try {
      final url = Uri.parse('http://localhost:8080/update-password'); // 비밀번호 업데이트 API
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId, // 사용자 ID 전달
          'new_password': _newPasswordController.text, // 새 비밀번호 전달
        }),
      );

      if (response.statusCode == 200) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );

        // 대시보드로 이동
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // 서버 응답에서 오류 메시지 처리
        final error = jsonDecode(response.body)['message'];
        setState(() {
          _errorMessage = error ?? '비밀번호 변경에 실패했습니다.';
        });
      }
    } catch (e) {
      // 네트워크 오류 처리
      setState(() {
        _errorMessage = '서버와 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  void _cancelUpdate() {
    Navigator.pushReplacementNamed(context, '/dashboard'); // 대시보드로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드로 인한 레이아웃 깨짐 방지
      appBar: const TopNavigationSection(
        title: '회원정보 수정',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이메일 필드 (비활성화)
              TextField(
                readOnly: true,
                controller: TextEditingController(text: widget.email),
                decoration: InputDecoration(
                  labelText: '이메일',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0), // 비활성화 배경색
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF67EACA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 이름 필드 (비활성화)
              TextField(
                readOnly: true,
                controller: TextEditingController(text: widget.name),
                decoration: InputDecoration(
                  labelText: '이름',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0), // 비활성화 배경색
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF67EACA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 아이디 필드 (비활성화)
              TextField(
                readOnly: true,
                controller: TextEditingController(text: widget.userId),
                decoration: InputDecoration(
                  labelText: '아이디',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE0E0E0), // 비활성화 배경색
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF67EACA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 새 비밀번호 입력 필드
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '새 비밀번호',
                  labelStyle: const TextStyle(color: Colors.black),
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF67EACA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 새 비밀번호 확인 입력 필드
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '새 비밀번호 확인',
                  labelStyle: const TextStyle(color: Colors.black),
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF67EACA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              // 버튼들
              Row(
                children: [
                  // 확인 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB0F4E6),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF67EACA), width: 1),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 취소 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB0F4E6),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF67EACA), width: 1),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}