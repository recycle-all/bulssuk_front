import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import 'package:flutter_dotenv/flutter_dotenv.dart';



class SignUpInputPage extends StatefulWidget {
  @override
  _SignUpInputPageState createState() => _SignUpInputPageState();
}

class _SignUpInputPageState extends State<SignUpInputPage> {
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _passwordErrorMessage;

  final List<String> years = List.generate(2025 - 1960 + 1, (index) => '${1960 + index}');
  final List<String> months = List.generate(12, (index) => '${index + 1}');
  final List<String> days = List.generate(31, (index) => '${index + 1}');

  String? _selectedEmailDomain;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _customDomainController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final TextEditingController _authCodeController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  String? _idCheckMessage;

  final List<String> emailDomains = ['직접 입력', 'naver.com', 'daum.net'];
  final URL = dotenv.env['URL'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _customDomainController.dispose();
    _authCodeController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  bool _isAuthFieldVisible = false; // 인증번호 입력 필드 표시 여부
  bool _isAuthCodeSent = false; // 인증번호 전송 여부
  bool _isEmailVerified = false; // 이메일 인증 여부
  bool _isIdChecked = false; // 아이디 중복 확인 여부
  String? _serverMessage; // 서버 응답 메시지

  @override
  void initState() {
    super.initState();
    _selectedEmailDomain = emailDomains.first; // 기본값 설정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '회원정보 입력',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 이름 텍스트박스
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름',
                labelStyle: TextStyle(
                  color: Colors.black, // 라벨 텍스트 색상 검은색
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 비활성화 상태 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // 둥근 테두리
                  borderSide: BorderSide(
                    color: Color(0xFF67EACA), // 활성화 상태 테두리 색상
                    width: 2, // 테두리 두께
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // 생년월일 선택
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    items: years.reversed.map((year) { // 내림차순 정렬
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '출생 연도',
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
                    ),
                    isDense: true,
                    menuMaxHeight: 200, // 드롭다운 5개씩 표시
                    style: TextStyle(
                      color: Colors.black, // 활성화 상태 텍스트 색상
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    items: months.map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '월',
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
                    ),
                    isDense: true,
                    menuMaxHeight: 200, // 드롭다운 5개씩 표시
                    style: TextStyle(
                      color: Colors.black, // 활성화 상태 텍스트 색상
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDay,
                    items: days.map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDay = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '일',
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
                    ),
                    isDense: true,
                    menuMaxHeight: 200, // 드롭다운 5개씩 표시
                    style: TextStyle(
                      color: Colors.black, // 활성화 상태 텍스트 색상
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 이메일 입력
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
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
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Text('@'),
                SizedBox(width: 5),
                Expanded(
                  flex: 2,
                  child: _selectedEmailDomain == '직접 입력'
                      ? TextField(
                    controller: _customDomainController,
                    decoration: InputDecoration(
                      labelText: '도메인 입력',
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
                    ),
                  )
                      : DropdownButtonFormField<String>(
                    value: _selectedEmailDomain,
                    items: emailDomains.map((domain) {
                      return DropdownMenuItem(
                        value: domain,
                        child: Text(domain),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmailDomain = value;
                        if (value != '직접 입력') {
                          _customDomainController.clear(); // 직접 입력 초기화
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '도메인 선택',
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
                    ),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text;
                    final domain = _selectedEmailDomain == '직접 입력'
                        ? _customDomainController.text
                        : _selectedEmailDomain;
                    final fullEmail = '$email@$domain';

                    try {
                      final url = Uri.parse('$URL/send_email');
                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'email': fullEmail}),
                      );

                      if (response.statusCode == 200) {
                        setState(() {
                          _isAuthFieldVisible = true;
                          _serverMessage = '인증번호가 발송되었습니다.';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('인증번호가 발송되었습니다.'),
                          ),
                        );
                      } else {
                        setState(() {
                          _serverMessage = '이메일 인증 실패.';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('이메일 인증 실패. 다시 시도해주세요.'),
                          ),
                        );
                      }
                    } catch (error) {
                      setState(() {
                        _serverMessage = '서버 오류: $error';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('서버 오류가 발생했습니다. 다시 시도해주세요.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Color(0xFFB0F4E6),
                  ),
                  child: Text(
                    '인증',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 인증번호 입력 필드
            if (_isAuthFieldVisible) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _authCodeController,
                      decoration: InputDecoration(
                        labelText: '인증번호 입력',
                        labelStyle: TextStyle(
                          color: Colors.black, // 라벨 텍스트 색상 검은색
                        ),
                        hintText: '6자리 인증번호를 입력하세요',
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
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // 인증번호 확인 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text;
                      final domain = _selectedEmailDomain == '직접 입력'
                          ? _customDomainController.text
                          : _selectedEmailDomain;
                      final fullEmail = '$email@$domain';

                      final emailRandomNumber = _authCodeController.text;
                      final url = Uri.parse('$URL/verify_email');
                      try {
                        final response = await http.post(
                          url,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': fullEmail, 'code': emailRandomNumber}),
                        );

                        if (response.statusCode == 200) {
                          setState(() {
                            _isEmailVerified = true;
                            _serverMessage = '인증 성공!';
                            _isAuthFieldVisible = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('이메일 인증에 성공했습니다!'),
                            ),
                          );
                        } else {
                          setState(() {
                            _serverMessage = '인증 실패. 다시 시도하세요.';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('인증번호가 올바르지 않습니다. 다시 시도해주세요.'),
                            ),
                          );
                        }
                      } catch (error) {
                        setState(() {
                          _serverMessage = '통신 실패: $error';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('서버 오류가 발생했습니다.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Color(0xFFB0F4E6),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 20),
            // 아이디 입력
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
              children: [
                // 아이디 입력 필드와 중복 확인 버튼을 나란히 배치
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController, // 아이디 입력 컨트롤러
                        decoration: InputDecoration(
                          labelText: '아이디 입력',
                          labelStyle: TextStyle(color: Colors.black), // 라벨 텍스트 색상 검은색
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // 둥근 테두리
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF67EACA), width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),

                    // 중복 확인 버튼
                    ElevatedButton(
                      onPressed: () async {
                        final userId = _idController.text.trim(); // 공백 제거
                        if (userId.isEmpty) {
                          setState(() {
                            _idCheckMessage = '아이디를 입력하세요.'; // 에러 메시지
                          });
                          return;
                        }

                        final url = Uri.parse('$URL/id_check'); // Node.js 서버 URL
                        try {
                          final response = await http.post(
                            url,
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({'id': userId}),
                          );

                          if (response.statusCode == 200) {
                            final responseData = json.decode(response.body);
                            setState(() {
                              _isIdChecked = true; // 아이디 중복 확인 완료
                              _idCheckMessage = responseData['message']; // 성공 메시지
                              _serverMessage = '사용 가능한 아이디입니다.';
                            });
                          } else {
                            final responseData = json.decode(response.body);
                            setState(() {
                              _isIdChecked = false; // 아이디 중복 확인 실패
                              _idCheckMessage = responseData['message']; // 실패 메시지
                              _serverMessage = '이미 사용 중인 아이디입니다.';
                            });
                          }
                        } catch (error) {
                          setState(() {
                            _idCheckMessage = '서버와 통신할 수 없습니다.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(100, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // 둥근 테두리
                        ),
                        backgroundColor: Color(0xFFB0F4E6), // 버튼 배경색
                      ),
                      child: Text(
                        '중복 확인',
                        style: TextStyle(color: Colors.black), // 버튼 텍스트 색상
                      ),
                    ),
                  ],
                ),

                // 아이디 중복 확인 메시지를 텍스트박스 아래에 표시
                if (_idCheckMessage != null) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0), // 왼쪽 여백 추가
                    child: Text(
                      _idCheckMessage!,
                      style: TextStyle(
                        color: _isIdChecked ? Colors.green : Colors.red, // 성공시 초록, 실패시 빨강
                        fontSize: 14,
                      ),
                    ),
                  ),
                ]
              ],
            ),
            SizedBox(height: 20),

            // 비밀번호 입력 및 확인
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 비밀번호 입력
                TextField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
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
                  ),
                ),
                SizedBox(height: 20),

                // 비밀번호 확인 입력
                TextField(
                  obscureText: true,
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
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
                    errorText: _passwordErrorMessage, // 오류 메시지
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (_passwordController.text != value) {
                        _passwordErrorMessage = '비밀번호가 일치하지 않습니다.';
                      } else {
                        _passwordErrorMessage = null; // 오류 메시지 제거
                      }
                    });
                  },
                ),
                SizedBox(height: 30),
              ],
            ),

            // 회원가입 완료 버튼
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final birthDate = _selectedYear != null && _selectedMonth != null && _selectedDay != null
                    ? '$_selectedYear-$_selectedMonth-$_selectedDay'
                    : '';
                final email = _emailController.text.trim() + '@' +
                    (_selectedEmailDomain == '직접 입력'
                        ? _customDomainController.text.trim()
                        : _selectedEmailDomain ?? '');
                final userId = _idController.text.trim();
                final password = _passwordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();

                // 이메일 및 아이디 중복 확인 검사
                if (!_isEmailVerified) {
                  setState(() {
                    _serverMessage = '이메일 인증을 완료하세요.';
                  });
                  return;
                }

                if (!_isIdChecked) {
                  setState(() {
                    _serverMessage = '아이디 중복 확인을 완료하세요.';
                  });
                  return;
                }

                // 필드 유효성 검사
                if (name.isEmpty) {
                  setState(() {
                    _serverMessage = '이름을 입력하세요.';
                  });
                  return;
                }

                if (birthDate.isEmpty || _selectedYear == null || _selectedMonth == null || _selectedDay == null) {
                  setState(() {
                    _serverMessage = '생년월일을 선택하세요.';
                  });
                  return;
                }

                if (email.isEmpty) {
                  setState(() {
                    _serverMessage = '이메일을 입력하세요.';
                  });
                  return;
                }

                if (userId.isEmpty) {
                  setState(() {
                    _serverMessage = '아이디를 입력하세요.';
                  });
                  return;
                }

                if (password.isEmpty || confirmPassword.isEmpty) {
                  setState(() {
                    _serverMessage = '비밀번호를 입력하세요.';
                  });
                  return;
                }

                if (password != confirmPassword) {
                  setState(() {
                    _serverMessage = '비밀번호가 일치하지 않습니다.';
                  });
                  return;
                }

                final url = Uri.parse('$URL/sign_up');
                try {
                  final response = await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'name': name,
                      'birth_date': birthDate,
                      'email': email,
                      'user_id': userId,
                      'password': password,
                    }),
                  );

                  if (!mounted) return;

                  // 회원가입 성공
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('회원가입을 완료했습니다. 로그인 후 이용해주세요.'),
                      ),
                    );
                    Navigator.pushNamed(context, '/login'); // 로그인 페이지로 이동
                    print('회원가입 완료');
                  } else {
                    setState(() {
                      _serverMessage = '회원가입 실패: ${response.statusCode}';
                    });
                  }
                } catch (error) {
                  setState(() {
                    _serverMessage = '통신 오류: $error';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0F4E6),
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text(
                '회원가입 완료',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}