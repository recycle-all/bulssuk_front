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

      final response = await http.get(
        Uri.parse('$_url/history_point'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pointHistory = List<Map<String, dynamic>>.from(data['points']);
          _isLoading = false;
        });
      } else {
        throw Exception('포인트 내역 조회 실패');
      }
    } catch (error) {
      print('오류: $error');
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                '보유 포인트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              Text(
                '${widget.totalPoints}p',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 포인트 내역 카드 (정렬 수정 완료)
  Widget _buildPointHistoryList() {
    return ListView.builder(
      itemCount: _pointHistory.length,
      itemBuilder: (context, index) {
        final item = _pointHistory[index];
        final isAdd = item['point_status'] == 'ADD';
        final pointAmount = item['point_amount'];
        final pointReason = item['point_reason'];
        final createdAt = item['created_at'];
        final pointTotal = item['point_total'] ?? '0';

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
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
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      createdAt,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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