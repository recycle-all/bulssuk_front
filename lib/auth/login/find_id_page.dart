import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bulssuk/auth/login/find_id_complete_page.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class FindIdPage extends StatefulWidget {
  @override
  _FindIdPageState createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isNameEmpty = false;
  bool _isEmailEmpty = false;
  bool _isLoading = false;

  Future<void> _findId() async {
    setState(() {
      _isNameEmpty = _nameController.text.isEmpty;
      _isEmailEmpty = _emailController.text.isEmpty;
    });

    if (_isNameEmpty || _isEmailEmpty) {
      return; // 입력값이 없으면 요청을 보내지 않음
    }

    try {
      setState(() {
        _isLoading = true; // 로딩 상태 활성화
      });

      final response = await http.post(
        Uri.parse('http://localhost:8080/find-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
        }),
      );

      setState(() {
        _isLoading = false; // 로딩 상태 비활성화
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String userId = responseData['userId'];

        // 아이디의 가운데 2글자 가리기
        String hiddenUserId = userId;
        if (userId.length > 2) {
          int midIndex = userId.length ~/ 2; // 가운데 인덱스 계산
          hiddenUserId = userId.replaceRange(midIndex - 1, midIndex + 1, '**');
        }

        // FindIdCompletePage로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FindIdCompletePage(userId: hiddenUserId),
          ),
        );
      } else {
        // 서버에서 에러 응답을 보낸 경우
        final errorResponse = jsonDecode(response.body);
        String errorMessage = errorResponse['message'];

        // 오류 메시지 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('오류'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // 로딩 상태 비활성화
      });

      // 네트워크 오류 등 처리
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('오류'),
            content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '아이디 찾기',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            // 이름 입력 필드
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름 입력',
                labelStyle: TextStyle(
                  color: Colors.black, // 라벨 텍스트 색상 검은색
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 비활성화 상태 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFF67EACA), // 활성화 상태 테두리 색상
                    width: 2, // 테두리 두께
                  ),
                ),
                errorText: _isNameEmpty ? '이름을 입력해주세요.' : null,
              ),
            ),
            SizedBox(height: 20),

            // 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일 입력',
                labelStyle: TextStyle(
                  color: Colors.black, // 라벨 텍스트 색상 검은색
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 비활성화 상태 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Color(0xFF67EACA), // 활성화 상태 테두리 색상
                    width: 2, // 테두리 두께
                  ),
                ),
                errorText: _isEmailEmpty ? '이메일을 입력해주세요.' : null,
              ),
            ),
            SizedBox(height: 30),

            // 확인 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _findId,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0F4E6), // 버튼 색상
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.black)
                  : Text(
                '확인',
                style: TextStyle(
                  color: Colors.black, // 버튼 텍스트 색상 검은색
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            // 하단으로 돌아가기 버튼
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // 이전 페이지로 돌아가기
                },
                child: Text(
                  '로그인 페이지로 돌아가기',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}