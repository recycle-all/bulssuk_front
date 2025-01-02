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
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _coupons = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        } else {
          throw Exception('쿠폰 데이터가 유효하지 않습니다.');
        }
      } else {
        throw Exception('쿠폰 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('쿠폰 조회 실패: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      color: const Color(0xFFFCF9EC),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '쿠폰 사용 시 유의사항',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Text(
            '• 쿠폰은 유효기간 내에만 사용 가능합니다.\n'
                '• 한 주문당 한 개의 쿠폰만 사용 가능합니다.\n'
                '• 쿠폰은 일부 상품에 적용되지 않을 수 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    coupon['imageUrl'] ?? '',
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