import 'package:flutter/material.dart';
import 'signUp_input_page.dart'; // 회원가입 입력 페이지 import
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import


class AgreementPage extends StatefulWidget {
  @override
  _AgreementPageState createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _isAllAgreed = false; // 약관 전체 동의 상태
  bool _isTermsAgreed = false; // 이용약관 동의 상태
  bool _isPrivacyAgreed = false; // 개인정보 이용 동의 상태
  bool _isTermsExpanded = false; // 이용약관 펼침 상태
  bool _isPrivacyExpanded = false; // 개인정보 이용 동의 펼침 상태
  bool _showErrorMessage = false; // 에러 메시지 표시 상태

  void _navigateToSignUpInputPage(BuildContext context) {
    if (_isTermsAgreed && _isPrivacyAgreed) {
      // 약관 전체 동의가 체크되어 있으면 회원가입 입력 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUpInputPage()), // 회원가입 입력 페이지로 이동
      );
    } else {
      // 약관 전체 동의가 안 되어 있으면 에러 메시지 표시
      setState(() {
        _showErrorMessage = true;
      });
    }
  }

  void _updateAllAgreedState() {
    setState(() {
      _isAllAgreed = _isTermsAgreed && _isPrivacyAgreed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '약관동의',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 이미지
            SizedBox(
              height: 200,
              child: Placeholder(), // 이미지 자리
            ),
            SizedBox(height: 30),
            // 환영 메시지
            Text(
              '고객님 환영합니다!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            // 약관 전체 동의
            ListTile(
              leading: IconButton(
                icon: Icon(
                  _isAllAgreed
                      ? Icons.radio_button_checked // 체크된 상태
                      : Icons.radio_button_off, // 기본 상태
                  color: _isAllAgreed ? Colors.green : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isAllAgreed = !_isAllAgreed; // 전체 동의 상태 변경
                    _isTermsAgreed = _isAllAgreed; // 전체 동의에 따라 상태 변경
                    _isPrivacyAgreed = _isAllAgreed;
                    _showErrorMessage = false; // 에러 메시지 숨김
                  });
                },
              ),
              title: Text(
                '약관 전체 동의',
                style: TextStyle(fontSize: 18),
              ),
            ),
            Divider(),
            // 이용약관 동의(필수)
            ListTile(
              leading: IconButton(
                icon: Icon(
                  _isTermsAgreed
                      ? Icons.radio_button_checked // 체크된 상태
                      : Icons.radio_button_off, // 기본 상태
                  color: _isTermsAgreed ? Colors.green : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isTermsAgreed = !_isTermsAgreed; // 이용약관 동의 상태 변경
                    _updateAllAgreedState(); // 전체 동의 상태 업데이트
                    _showErrorMessage = false; // 에러 메시지 숨김
                  });
                },
              ),
              title: Text(
                '이용약관 동의(필수)',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Icon(
                _isTermsExpanded ? Icons.expand_less : Icons.chevron_right,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  _isTermsExpanded = !_isTermsExpanded;
                });
              },
            ),
            if (_isTermsExpanded)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '여기에 이용약관 내용을 작성합니다.\n\n예: 본 약관은 ... 등',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Divider(),
            // 개인정보 수집 및 이용 동의 (필수)
            ListTile(
              leading: IconButton(
                icon: Icon(
                  _isPrivacyAgreed
                      ? Icons.radio_button_checked // 체크된 상태
                      : Icons.radio_button_off, // 기본 상태
                  color: _isPrivacyAgreed ? Colors.green : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isPrivacyAgreed = !_isPrivacyAgreed; // 개인정보 동의 상태 변경
                    _updateAllAgreedState(); // 전체 동의 상태 업데이트
                    _showErrorMessage = false; // 에러 메시지 숨김
                  });
                },
              ),
              title: Text(
                '개인정보 수집 및 이용동의(필수)',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Icon(
                _isPrivacyExpanded ? Icons.expand_less : Icons.chevron_right,
                color: Colors.black,
              ),
              onTap: () {
                setState(() {
                  _isPrivacyExpanded = !_isPrivacyExpanded;
                });
              },
            ),
            if (_isPrivacyExpanded)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '여기에 개인정보 수집 및 이용에 대한 내용을 작성합니다.\n\n예: 고객님의 개인정보는 ... 등',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Divider(),
            // 에러 메시지
            if (_showErrorMessage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  '모든 필수 약관에 동의해야 합니다.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 20),
            // 다음 버튼
            ElevatedButton(
              onPressed: () {
                _navigateToSignUpInputPage(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0F4E6), // 버튼 내부 색상
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  color: Colors.black, // 버튼 텍스트 색상
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