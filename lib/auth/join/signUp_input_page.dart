import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import




class SignUpInputPage extends StatefulWidget {
  @override
  _SignUpInputPageState createState() => _SignUpInputPageState();
}

class _SignUpInputPageState extends State<SignUpInputPage> {
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _passwordErrorMessage;

  final List<String> years = List.generate(2024 - 1950 + 1, (index) => '${1950 + index}');
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
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text;
                    final domain = _selectedEmailDomain == '직접 입력'
                        ? _customDomainController.text
                        : _selectedEmailDomain;
                    final fullEmail = '$email@$domain';

                    try {
                      final url = Uri.parse('http://localhost:8080/send_email');
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
                      } else {
                        setState(() {
                          _serverMessage = '이메일 인증 실패.';
                        });
                      }
                    } catch (error) {
                      setState(() {
                        _serverMessage = '서버 오류: $error';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 둥근 테두리
                    ),
                    backgroundColor: Color(0xFFB0F4E6), // 버튼 배경색
                  ),
                  child: Text(
                    '인증',
                    style: TextStyle(color: Colors.black), // 버튼 텍스트 색상
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
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text;
                      final domain = _selectedEmailDomain == '직접 입력'
                          ? _customDomainController.text
                          : _selectedEmailDomain;
                      final fullEmail = '$email@$domain';

                      final emailRandomNumber = _authCodeController.text;
                      final url = Uri.parse('http://localhost:8080/verify_email');
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
                        } else {
                          setState(() {
                            _serverMessage = '인증 실패. 다시 시도하세요.';
                          });
                        }
                      } catch (error) {
                        setState(() {
                          _serverMessage = '통신 실패: $error';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, 48), // 버튼 크기
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // 둥근 테두리
                      ),
                      backgroundColor: Color(0xFFB0F4E6), // 버튼 배경색
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(color: Colors.black), // 버튼 텍스트 색상
                    ),
                  ),
                ],
              ),
            ],

            // 서버 응답 메시지 표시
            if (_serverMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _serverMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],


            // 아이디 입력
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController, // 아이디 입력 컨트롤러
                    decoration: InputDecoration(
                      labelText: '아이디 입력',
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
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final userId = _idController.text; // 아이디 값
                    if (userId.isEmpty) {
                      setState(() {
                        _idCheckMessage = '아이디를 입력하세요.'; // 에러 메시지
                      });
                      return;
                    }
                    print('아이디 중복 확인 요청: $userId');
                    final url = Uri.parse('http://localhost:8080/id_check'); // Node.js 서버 URL
                    try {
                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({'id': userId}),
                      );

                      if (response.statusCode == 200) {
                        final responseData = json.decode(response.body);
                        print('서버 응답: ${responseData['message']}');
                        setState(() {
                          _isIdChecked = true; // 아이디 중복 확인 완료
                          _idCheckMessage = responseData['message']; // 성공 메시지 표시
                          _serverMessage = '사용 가능한 아이디 입니다.';
                        });
                      } else {
                        final responseData = json.decode(response.body);
                        print('에러 발생: ${responseData['message']}');
                        setState(() {
                          _isIdChecked = false; // 아이디 중복 확인 실패
                          _idCheckMessage = responseData['message']; // 실패 메시지 표시
                          _serverMessage = '이미 사용 중인 아이디 입니다.';
                        });
                      }
                    } catch (error) {
                      print('통신 실패: $error');
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
                    style: TextStyle(color: Colors.black), // 버튼 텍스트 색상 검은색
                  ),
                ),
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
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim(); // 공백 제거
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

                  final url = Uri.parse('http://localhost:8080/sign_up');
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
                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.pushNamed(context, '/'); // 경로 설정
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
                  backgroundColor: Color(0xFFB0F4E6), // 버튼 색상
                  padding: EdgeInsets.symmetric(vertical: 16.0), // 사용자 선호 패딩
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 둥근 테두리
                  ),
                  minimumSize: Size(double.infinity, 48), // 버튼 크기 설정
                ),
                child: Text(
                  '회원가입 완료',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}