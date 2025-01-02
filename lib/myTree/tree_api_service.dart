import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

final storage = FlutterSecureStorage();
final apiUrl = dotenv.env['URL'];

// Fetch total points
Future<int> fetchTotalPoints() async {
  final token = await storage.read(key: 'jwt_token');
  if (token == null) throw Exception('JWT token not found');

  final response = await http.get(
    Uri.parse('$URL/total_point'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['totalPoints'];
  } else {
    throw Exception('Failed to load total points');
  }
}

// Fetch available coupons count
Future<int> fetchAvailableCoupons() async {
  final token = await storage.read(key: 'jwt_token');
  if (token == null) throw Exception('JWT token not found');

  final response = await http.get(
    Uri.parse('$URL/user_coupon'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final DateTime now = DateTime.now();

    final availableCoupons = List<Map<String, dynamic>>.from(data['data'])
        .where((coupon) => DateTime.parse(coupon['expirationdate']).isAfter(now))
        .toList();

    return availableCoupons.length;
  } else {
    throw Exception('Failed to load available coupons');
  }
}

// 물주기 API 호출
Future<int> performTreeAction(String action, int cost) async {
  final token = await storage.read(key: 'jwt_token');
  if (token == null) throw Exception('JWT token not found');

  final response = await http.post(
    Uri.parse('$URL/tree_action'), // API 엔드포인트
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'cost': cost, 'action': action}), // action 필드 추가
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['points']; // 차감 후의 포인트 반환
  } else {
    final errorResponse = jsonDecode(response.body);
    throw Exception(errorResponse['message'] ?? 'Failed to perform action');
  }
}