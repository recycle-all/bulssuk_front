import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/login/login_page.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';
import 'editUserInfo/verifyPassword.dart';
import 'inquiry&FAQ/FAQ_page.dart';
import 'inquiry&FAQ/quesetion_page.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _userName = 'Guest'; // 기본값 설정

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Secure Storage에서 사용자 이름 로드
  }

  // Secure Storage에서 사용자 이름 로드
  Future<void> _loadUserName() async {
    try {
      final userName = await _storage.read(key: 'user_name'); // user_name 키로 데이터 읽기

      setState(() {
        _userName = userName ?? 'Guest'; // user_name이 없으면 기본값으로 설정
      });

      print('읽어온 user_name: $_userName'); // 디버깅 로그
    } catch (e) {
      print('user_name을 로드하는 중 오류 발생: $e');
    }
  }

  // 로그아웃 기능
  Future<void> logout(BuildContext context) async {
    try {
      await _storage.deleteAll(); // 모든 Secure Storage 데이터 삭제
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그아웃 성공!")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(title: '마이페이지'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // user_name 표시
                  Text(
                    '$_userName님',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/tree2.png', // 나무 이미지 경로
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white, // 배경색
                      border: Border.all(
                        color: const Color(0xFF67EACA), // 테두리 색상
                        width: 1.5, // 테두리 두께
                      ),
                      borderRadius: BorderRadius.circular(12.0), // 테두리 둥글게
                    ),
                    child: const Text(
                      '현재 나무 상태',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // 포인트 정보 카드
            Card(
              color: const Color(0xFFB0F4E6), // 카드 배경색 변경
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: const Text('내 포인트'),
                trailing: const Text(
                  '710 p',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () {
                  print("포인트 상세보기 클릭");
                },
              ),
            ),
            const SizedBox(height: 20),
            // 메뉴 리스트
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 10.0),
              children: [
                _buildMenuItem(context, '오늘의 퀴즈', () {
                  print("오늘의 퀴즈 클릭");
                }),
                _buildMenuItem(context, '출석체크', () {
                  print("출석체크 클릭");
                }),
                _buildMenuItem(context, '1:1 문의하기', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuestionPage()),
                  );
                }),
                _buildMenuItem(context, '자주묻는질문(FAQ)', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FAQPage()),
                  );
                }),
                _buildMenuItem(context, '회원정보수정', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VerifyPassword()),
                  );
                }),
                _buildMenuItem(context, '로그아웃', () => logout(context)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 3),
    );
  }

  // 메뉴 아이템 빌더
  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}