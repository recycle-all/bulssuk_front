import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final URL = dotenv.env['URL'];
// 사용자 알림 데이터 가져오기
Future<List<dynamic>> fetchUserAlarms(int userNo) async {
  print(userNo);

  final DateTime now = DateTime.now();
  final String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'; // '년-월-일' 형식으로 포맷

  // 쿼리 파라미터를 URL에 추가
  final url = Uri.parse('$URL/alarms/$userNo').replace(queryParameters: {
    'user_calendar_date': formattedDate,
  });

  print('API 요청 URL: $url'); // 디버깅: 요청 URL 확인

  final response = await http.get(url);

  print(response);
  print('Response body: ${response.body}'); // 응답 데이터 출력

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load alarms');
  }
}
