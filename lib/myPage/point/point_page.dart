import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PointPage extends StatefulWidget {
  final int totalPoints;

  const PointPage({Key? key, required this.totalPoints}) : super(key: key);

  @override
  _PointPageState createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String? _url = dotenv.env['URL'];
  List<Map<String, dynamic>> _pointHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPointHistory();
  }

  Future<void> _fetchPointHistory() async {
    try {
      if (_url == null) throw Exception('API URL이 설정되지 않았습니다.');

      // JWT 토큰 읽기
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('로그인이 필요합니다.');

      /// JWT 토큰 출력
      // print('JWT 토큰: $token');

      final response = await http.get(
        Uri.parse('$_url/history_point'), // 백엔드 API 경로와 일치하도록 수정
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      /// HTTP 응답 상태 코드와 본문 출력 test
      // print('HTTP 응답 코드: ${response.statusCode}');
      // print('HTTP 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pointHistory = List<Map<String, dynamic>>.from(data['points']);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _pointHistory = [];
          _isLoading = false;
        });
      } else {
        throw Exception('포인트 내역 조회 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('오류: $error'); // 오류 로그 출력
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('포인트 내역 불러오기 실패: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('포인트 내역')),
      body: Column(
        children: [
          _buildTotalPointsCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pointHistory.isEmpty
                ? const Center(
              child: Text(
                '포인트 내역이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : _buildPointHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPointsCard() {
    return Container(
      width: double.infinity, // 전체 화면 너비
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // 카드 모서리 둥글게
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '보유 포인트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              Text(
                '${widget.totalPoints}p', // 총 포인트 표시
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), // 더 큰 텍스트 크기
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 포인트 내역 카드 (위치 정렬 개선 및 null 방지)
  Widget _buildPointHistoryList() {
    return ListView.builder(
      itemCount: _pointHistory.length,
      itemBuilder: (context, index) {
        final item = _pointHistory[index];
        final isAdd = item['point_status'] == 'ADD';
        final pointAmount = item['point_amount'];
        final pointReason = item['point_reason'];
        final createdAt = item['created_at'];
        final pointTotal = item['point_total'] ?? '0'; // ✅ null 방지 적용

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                // ✅ 포인트 사유와 포인트 증감 (한 줄 정렬)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pointReason,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${isAdd ? '+ ' : '- '}${pointAmount.abs()}p',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAdd ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20.0),

                // ✅ 실행 날짜와 당시 보유 포인트 (오른쪽 정렬)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      createdAt,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '$pointTotal p',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}