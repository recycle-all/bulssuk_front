import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/login/login_page.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';
import 'editUserInfo/verifyPassword.dart';
import 'inquiry&FAQ/FAQ_page.dart';
import 'inquiry&FAQ/quesetion_page.dart';
import 'myCoupon/coupon_page.dart';
import 'point/point_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String? _url = dotenv.env['URL'];
  String _userName = 'Guest';
  int _totalPoints = 0;
  bool _isLoading = true;
  String _treeStatus = 'Loading...'; // 나무 상태 텍스트
  String _treeImage = ''; // 나무 이미지 URL

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchTotalPoints();
    _fetchTreeStatus();
  }

  // ✅ Secure Storage에서 사용자 이름 로드
  Future<void> _loadUserName() async {
    try {
      final userName = await _storage.read(key: 'user_name');
      setState(() {
        _userName = userName ?? 'Guest';
      });
    } catch (e) {
      print('user_name을 로드하는 중 오류 발생: $e');
    }
  }

  // ✅ 보유 포인트 불러오는 메서드
  Future<void> _fetchTotalPoints() async {
    try {
      if (_url == null) throw Exception('API URL이 설정되지 않았습니다.');

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('로그인이 필요합니다.');

      final response = await http.get(
        Uri.parse('$_url/total_point'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int totalPoints = (data['totalPoints'] ?? 0).toInt();
        setState(() {
          _totalPoints = totalPoints;
          _isLoading = false;
        });
      } else {
        throw Exception('보유 포인트 조회 실패');
      }
    } catch (error) {
      print('❌ 오류 발생: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ 나무 상태 및 이미지 불러오는 메서드 추가
  Future<void> _fetchTreeStatus() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        print('JWT 토큰이 없습니다.');
        throw Exception('로그인이 필요합니다.');
      }

      print('📩 API 호출 시작 - 토큰 포함');
      final response = await http.get(
        Uri.parse('$_url/dashboard_tree'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔄 API 응답 코드: ${response.statusCode}');
      print('🔄 API 응답 데이터: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _treeStatus = data['dashboard_tree_content'] ?? '정보 없음';
          _treeImage = 'assets${data['dashboard_tree_img'].replaceFirst('/uploads/images', '')}';
          _isLoading = false;
        });
        print('✅ 나무 상태 데이터 반영 완료: $_treeStatus');
      } else {
        throw Exception('서버에서 나무 상태를 찾을 수 없습니다.');
      }
    } catch (error) {
      print('❌ 나무 상태 불러오기 실패: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ 로그아웃 기능
  Future<void> logout(BuildContext context) async {
    try {
      await _storage.deleteAll();
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
                children: [
                  Text(
                    '$_userName님',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // ✅나무 이미지 표시
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ClipOval(
                    child: _treeImage.isNotEmpty
                        ? Image.asset(
                      _treeImage, // ✅ 로컬 이미지 경로로 수정
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 150),
                    )
                        : const Center(child: Text('이미지 없음')),
                  ),
                  const SizedBox(height: 25),

                  // ✅ 나무 상태 텍스트 (나무 멘트 디자인 적용)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF9EC), // 연한 배경색
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _treeStatus, // 나무 상태 텍스트
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ✅ 포인트 카드 (서버에서 가져온 값으로 표시)
            Card(
              color: const Color(0xFFB0F4E6),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: const Text('내 포인트'),
                trailing: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  '$_totalPoints p',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PointPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 10.0),
              children: [
                _buildMenuItem(context, '회원정보수정', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VerifyPassword()),
                  );
                }),
                _buildMenuItem(context, '내 쿠폰함', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CouponPage()),
                  );
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
                _buildMenuItem(context, '로그아웃', () => logout(context)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 3),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}