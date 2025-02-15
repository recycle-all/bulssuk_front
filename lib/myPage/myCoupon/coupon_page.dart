import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({Key? key}) : super(key: key);

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String? _url = dotenv.env['URL'];
  late TabController _tabController;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      if (_url == null) throw Exception('API URL이 설정되지 않았습니다.');
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('로그인이 필요합니다.');

      final response = await http.get(
        Uri.parse('$_url/user_coupon'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Server response: $data'); // 서버 응답 전체 출력
        if (data['success'] == true && data['data'] != null) {
          final List<Map<String, dynamic>> coupons = List<Map<String, dynamic>>.from(data['data']);
          for (var coupon in coupons) {
            print('Coupon: $coupon'); // 각 쿠폰 데이터를 출력
          }

          setState(() {
            _coupons = coupons
                .map((coupon) => {
              'name': coupon['name'],
              'imageurl': coupon['imageurl'], // 소문자 키로 매핑
              'expirationdate': coupon['expirationdate'],
            })
                .toList();
            _isLoading = false;
          });
        } else {
          throw Exception('쿠폰 데이터가 유효하지 않습니다.');
        }
      } else {
        throw Exception('쿠폰 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('쿠폰 조회 실패: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> availableCoupons = _coupons
        .where((coupon) =>
        DateTime.parse(coupon['expirationdate']).isAfter(now))
        .toList();
    final List<Map<String, dynamic>> expiredCoupons = _coupons
        .where((coupon) =>
        DateTime.parse(coupon['expirationdate']).isBefore(now))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TopNavigationSection(title: '내 쿠폰함'),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF67EACA),
              indicatorWeight: 1.0,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontSize: 16),
              tabs: [
                Tab(text: '사용 가능한 쿠폰 (${availableCoupons.length})'),
                Tab(text: '지난 쿠폰 (${expiredCoupons.length})'),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15), // 탭바와 유의사항 사이 간격 추가
          _buildNoticeSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCouponList(availableCoupons),
                _buildCouponList(expiredCoupons),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      color: const Color(0xFFFCF9EC), // 배경색 추가
      width: double.infinity, // 부모 위젯 크기를 화면 전체로 설정
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
        children: const [
          Text(
            '쿠폰 사용 시 유의사항',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
          ),
          SizedBox(height: 15),
          Text(
            '• 쿠폰은 유효기간 내에만 사용 가능합니다.\n'
                '• 한 주문당 한 개의 쿠폰만 사용 가능합니다.\n'
                '• 쿠폰은 일부 상품에 적용되지 않을 수 있습니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(List<Map<String, dynamic>> coupons) {
    if (coupons.isEmpty) {
      return const Center(
        child: Text(
          '쿠폰이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        final serverPath = coupon['imageurl'] ?? '';
        final localPath = 'assets/${serverPath.split('/').last}';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.only(bottom: 16.0),
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    localPath, // 변환된 경로 사용
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image,
                      size: 70,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 30.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      Text(
                        '만료일: ${coupon['expirationdate'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}