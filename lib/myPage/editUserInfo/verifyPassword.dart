import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart';
import 'updateProfile.dart';

class VerifyPassword extends StatefulWidget {
  const VerifyPassword({Key? key}) : super(key: key);

  @override
  _VerifyPasswordState createState() => _VerifyPasswordState();
}

class _VerifyPasswordState extends State<VerifyPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _errorMessage;
  String? _userId; // 로그인한 사용자 ID
  String? _userName; // 로그인한 사용자 이름
  String? _userEmail; // 로그인한 사용자 이메일

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Secure Storage에서 유저 정보 로드
  }

  @override
  void dispose() {
    _passwordController.dispose(); // TextEditingController 메모리 해제
    super.dispose();
  }

  // Secure Storage에서 user_id, user_name, user_email 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      final userName = await _storage.read(key: 'user_name');
      final userEmail = await _storage.read(key: 'user_email');

      if (userId != null && userName != null && userEmail != null) {
        setState(() {
          _userId = userId;
          _userName = userName;
          _userEmail = userEmail;
        });
      } else {
        setState(() {
          _errorMessage = '로그인 정보가 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '유저 정보를 불러오는데 실패했습니다.';
      });
    }
  }

  // 비밀번호 확인 함수
  Future<void> _validatePassword() async {
    if (_userId == null) {
      setState(() {
        _errorMessage = '로그인 정보가 없습니다.';
      });
      return;
    }

    final url = Uri.parse('http://localhost:8080/verify-password'); // 비밀번호 확인 API
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId, // Secure Storage에서 불러온 user_id
          'current_password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // 비밀번호 확인 성공 -> UpdateProfile로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 확인되었습니다!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateProfile(
              email: _userEmail!, // Secure Storage에서 불러온 이메일 전달
              name: _userName!, // Secure Storage에서 불러온 이름 전달
              userId: _userId!, // Secure Storage에서 불러온 user_id 전달
            ),
          ),
        );
      } else {
        // 서버에서 반환된 에러 메시지 처리
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? '비밀번호가 맞지 않습니다.';
        });
      }
    } catch (error) {
      // 네트워크 또는 서버 오류 처리
      setState(() {
        _errorMessage = '서버와 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null; // 에러 여부

    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드로 인한 레이아웃 깨짐 방지
      appBar: const TopNavigationSection(
        title: '비밀번호 확인',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40), // AppBar와 텍스트박스 간 간격
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 비밀번호 입력 텍스트박스
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '현재 비밀번호',
                    hintText: '비밀번호 입력',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red, // 에러 상태 테두리 빨간색
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red, // 에러 상태 포커스 테두리 빨간색
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 8), // 텍스트박스 아래 여백
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20), // 텍스트박스와 버튼 간 간격
            // 확인 버튼
            ElevatedButton(
              onPressed: _validatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB0F4E6), // 버튼 색상 유지
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF67EACA), width: 1),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Colors.black, // 버튼 텍스트 색상 유지
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