import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final storage = FlutterSecureStorage();
final apiUrl = dotenv.env['URL'];

// Fetch total points
Future<int> fetchTotalPoints() async {
  final token = await storage.read(key: 'jwt_token');
  if (token == null) throw Exception('JWT token not found');

  final response = await http.get(
    Uri.parse('$apiUrl/total_point'),
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
    Uri.parse('$apiUrl/user_coupon'),
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