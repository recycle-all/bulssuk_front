import 'package:flutter/material.dart';
import 'signUp_input_page.dart'; // 회원가입 입력 페이지 import
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class AgreementPage extends StatefulWidget {
  @override
  _AgreementPageState createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _isAllAgreed = false;
  bool _isTermsAgreed = false;
  bool _isPrivacyAgreed = false;
  bool _isIdentificationAgreed = false;
  bool _isMarketingAgreed = false;
  bool _isTermsExpanded = false;
  bool _isPrivacyExpanded = false;
  bool _isIdentificationExpanded = false;
  bool _isMarketingExpanded = false;
  bool _showErrorMessage = false;

  // ✅ 전체 동의 상태 업데이트
  void _updateAllAgreedState() {
    setState(() {
      _isAllAgreed = _isTermsAgreed &&
          _isPrivacyAgreed &&
          _isIdentificationAgreed &&
          _isMarketingAgreed;
    });
  }

  // ✅ 다음 페이지로 이동 (필수 약관 체크 여부)
  void _navigateToSignUpInputPage(BuildContext context) {
    if (_isTermsAgreed && _isPrivacyAgreed && _isIdentificationAgreed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUpInputPage()),
      );
    } else {
      setState(() {
        _showErrorMessage = true;
      });
    }
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
            // ✅ 상단 이미지
            SizedBox(
              height: 150,
              child: Image.asset(
                'assets/bulssuk_white_logo.jpeg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),

            // ✅ 환영 메시지 복구
            const Text(
              '고객님 환영합니다!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // ✅ 약관 전체 동의 (체크박스 색상 적용)
            ListTile(
              leading: Checkbox(
                value: _isAllAgreed,
                activeColor: const Color(0xFF12D3CF), // ✅ 색상 적용
                onChanged: (value) {
                  setState(() {
                    _isAllAgreed = value ?? false;
                    _isTermsAgreed = _isAllAgreed;
                    _isPrivacyAgreed = _isAllAgreed;
                    _isIdentificationAgreed = _isAllAgreed;
                    _isMarketingAgreed = _isAllAgreed;
                    _showErrorMessage = false;
                  });
                },
              ),
              title: const Text('약관 전체 동의 (선택 포함)', style: TextStyle(fontSize: 18)),
            ),
            const Divider(),

            // ✅ 이용약관 동의(필수)
            _buildAgreementTile(
              title: '이용약관 동의(필수)',
              isExpanded: _isTermsExpanded,
              isAgreed: _isTermsAgreed,
              onTap: () => setState(() => _isTermsExpanded = !_isTermsExpanded),
              onChanged: (value) => setState(() {
                _isTermsAgreed = value!;
                _updateAllAgreedState();
              }),
              content: '제1조 목적\n'
                  '본 약관은 사용자가 "불쑥"(이하 "서비스")을 이용함에 있어 필요한 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'

                  '제2조 서비스 제공 및 변경\n'
                  '1. 본 서비스는 사용자가 카메라를 이용해 AI가 분리수거 종류를 판별하고, 나무 키우기 기능을 제공하는 서비스입니다.\n'
                  '2. 서비스 제공자는 필요 시 운영상 이유로 서비스 내용을 변경할 수 있습니다.\n\n'

                  '제3조 이용자의 의무\n'
                  '1. 사용자는 본 약관 및 관련 법령을 준수해야 합니다.\n'
                  '2. 타인의 계정을 도용하거나 부정 사용해서는 안 됩니다.\n\n'

                  '제4조 서비스 이용의 제한 및 중지\n'
                  '1. 사용자가 약관을 위반할 경우 서비스 이용이 제한될 수 있습니다.\n'
                  '2. 천재지변, 시스템 장애 등의 사유로 서비스가 일시적으로 중단될 수 있습니다.',
            ),
            const Divider(),

            // ✅ 개인정보 수집 및 이용 동의(필수)
            _buildAgreementTile(
              title: '개인정보 수집 및 이용 동의(필수)',
              isExpanded: _isPrivacyExpanded,
              isAgreed: _isPrivacyAgreed,
              onTap: () => setState(() => _isPrivacyExpanded = !_isPrivacyExpanded),
              onChanged: (value) => setState(() {
                _isPrivacyAgreed = value!;
                _updateAllAgreedState();
              }),
              content:  '제1조 수집하는 개인정보 항목\n'
                  '본 서비스는 다음의 개인정보를 수집합니다.\n'
                  '- 성명, 이메일 주소, 비밀번호, 프로필 사진, 서비스 이용 기록, 기기 정보\n\n'

                  '제2조 개인정보의 수집 및 이용 목적\n'
                  '1. 서비스 제공 및 회원 관리\n'
                  '2. AI 기반 분리수거 정보 제공\n'
                  '3. 나무 키우기 서비스 운영 및 포인트 적립\n'
                  '4. 고객 문의 및 불만 처리\n\n'

                  '제3조 개인정보의 보유 및 이용 기간\n'
                  '1. 회원 탈퇴 시 즉시 파기합니다.\n'
                  '2. 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관됩니다.\n\n'

                  '제4조 개인정보의 제3자 제공\n'
                  '1. 법적 의무 이행을 위해 필요한 경우를 제외하고, 사용자의 동의 없이 제공되지 않습니다.\n\n'

                  '제5조 개인정보 보호\n'
                  '본 서비스는 사용자의 개인정보를 안전하게 보호하기 위해 최선을 다하고 있습니다.',
            ),
            const Divider(),

            // ✅ 고유식별정보 처리 동의(필수)
            _buildAgreementTile(
              title: '고유식별정보 처리 동의(필수)',
              isExpanded: _isIdentificationExpanded,
              isAgreed: _isIdentificationAgreed,
              onTap: () => setState(() => _isIdentificationExpanded = !_isIdentificationExpanded),
              onChanged: (value) => setState(() {
                _isIdentificationAgreed = value!;
                _isTermsExpanded = value;
                _updateAllAgreedState();
              }),
              content: '제1조 고유식별정보 수집 목적\n'
                  '회원 계정의 고유성을 확인하고, 서비스의 보안 강화를 위해 고유식별정보를 수집합니다.\n\n'

                  '제2조 수집하는 고유식별정보 항목\n'
                  '- 사용자 고유 번호(user_no)\n\n'

                  '제3조 고유식별정보의 수집 및 이용 목적\n'
                  '1. 회원 식별 및 계정 관리\n'
                  '2. AI 분리수거 판별 서비스 제공\n'
                  '3. 나무 키우기 서비스 제공 및 포인트 적립\n\n'

                  '제4조 고유식별정보의 보유 및 이용 기간\n'
                  '- 회원 탈퇴 시 즉시 파기됩니다.\n'
                  '- 단, 법령에 따라 보관이 필요한 경우 해당 법령에서 정한 기간 동안 보관합니다.\n\n'

                  '제5조 고유식별정보 보호\n'
                  '본 서비스는 사용자의 고유식별정보를 안전하게 보호하기 위해 최선을 다하고 있습니다.',
            ),
            const Divider(),

            // ✅ 마케팅 수신 동의(선택)
            _buildAgreementTile(
              title: '마케팅 수신 동의(선택)',
              isExpanded: _isMarketingExpanded,
              isAgreed: _isMarketingAgreed,
              onTap: () => setState(() => _isMarketingExpanded = !_isMarketingExpanded),
              onChanged: (value) => setState(() {
                _isMarketingAgreed = value!;
                _updateAllAgreedState();
              }),
              content: '''
              제1조 마케팅 수신 동의 목적
              본 약관은 사용자가 "불쑥" 서비스 이용 중 마케팅 수신 동의에 대한 사항을 규정함을 목적으로 합니다.

              제2조 수집 항목 및 방법
               본 서비스는 사용자의 마케팅 정보를 다음과 같은 방법으로 수집할 수 있습니다:
              1. 이메일 주소
              2. 휴대전화 번호 (문자 메시지 발송)

              제3조 수집 목적
수집한 정보는 다음의 목적으로 사용됩니다:
1. 새로운 기능 및 서비스 안내
2. 이벤트 및 프로모션 정보 제공
3. 서비스 관련 공지사항 전달

제4조 동의 거부 및 철회
1. 사용자는 언제든지 마케팅 수신 동의를 철회할 수 있습니다.
2. 동의 철회는 [설정 > 개인정보 관리] 메뉴에서 진행할 수 있습니다.

제5조 유의사항
마케팅 수신에 동의하지 않더라도 서비스 이용에는 제한이 없습니다.
''',
            ),
            const Divider(),

            // ✅ 에러 메시지
            if (_showErrorMessage)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  '모든 필수 약관에 동의해야 합니다.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),

            // ✅ 다음 버튼
            ElevatedButton(
              onPressed: () => _navigateToSignUpInputPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB0F4E6),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 체크박스 색상 적용한 공통 약관 위젯 빌더 메서드
  Widget _buildAgreementTile({
    required String title,
    required bool isExpanded,
    required bool isAgreed,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTap,
    required String content,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Checkbox(
            value: isAgreed,
            activeColor: const Color(0xFF12D3CF), // ✅ 색상 적용
            onChanged: onChanged,
          ),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.chevron_right,
            color: Colors.black,
          ),
          onTap: onTap,
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(content, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}