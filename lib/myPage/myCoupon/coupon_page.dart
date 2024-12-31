import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({Key? key}) : super(key: key);

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String? _url = dotenv.env['URL'];
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      // API URL 확인
      if (_url == null) {
        print('API URL is not set in .env file');
        throw Exception('API URL이 설정되지 않았습니다.');
      }

      // JWT 토큰 읽기
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        print('JWT Token is missing');
        throw Exception('로그인이 필요합니다.');
      }

      // API 호출
      final response = await http.get(
        Uri.parse('$_url/user_coupon'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 응답 데이터 디버깅
        // print('Parsed Data: $data');

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _coupons = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });

          // 쿠폰 데이터 디버깅
          for (var coupon in _coupons) {
            // print('Coupon: ${coupon['name']}, Expiration Date: ${coupon['expirationdate']}');
          }
        } else {
          print('Invalid response structure: $data');
          throw Exception('쿠폰 데이터가 유효하지 않습니다.');
        }
      } else {
        print('Failed to fetch coupons. Status code: ${response.statusCode}');
        throw Exception('쿠폰 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('Error occurred: $error');
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
    return Scaffold(
      appBar: AppBar(title: const Text('내 쿠폰함')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
          ? const Center(
        child: Text(
          '사용 가능한 쿠폰이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : _buildCouponList(),
    );
  }

  Widget _buildCouponList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        // print('Rendering coupon: ${coupon['name']}, Expiration Date: ${coupon['expirationdate']}');
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 8.0),
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
        );
      },
    );
  }
}