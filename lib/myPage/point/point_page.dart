import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PointPage extends StatefulWidget {
  const PointPage({Key? key}) : super(key: key);

  @override
  _PointPageState createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String? _url = dotenv.env['URL'];
  List<Map<String, dynamic>> _pointHistory = [];
  int _totalPoints = 0; // ✅ 보유 포인트 추가
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotalPoints(); // ✅ 보유 포인트 불러오기
    _fetchPointHistory(); // ✅ 포인트 내역 불러오기
  }

  /// ✅ 보유 포인트 불러오는 메서드
  Future<void> _fetchTotalPoints() async {
    try {
      if (_url == null) throw Exception('API URL이 설정되지 않았습니다.');

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('로그인이 필요합니다.');

      final response = await http.get(
        Uri.parse('$_url/total_point'),  // ✅ 백엔드의 보유 포인트 조회 경로
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// ✅ null 값을 방지하기 위한 수정 및 콘솔 출력 추가
        final int totalPoints = (data['totalPoints'] ?? 0).toInt();
        print('✅ 데이터베이스에서 가져온 보유 포인트: $totalPoints'); // ✅ 콘솔 출력 코드 추가

        setState(() {
          _totalPoints = totalPoints;
        });
      } else {
        throw Exception('보유 포인트 조회 실패');
      }
    } catch (error) {
      print('❌ 오류 발생: $error');  // ✅ 오류 로그 추가
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('보유 포인트 불러오기 실패: $error')),
      );
    }
  }

  Future<void> _fetchPointHistory() async {
    try {
      if (_url == null) throw Exception('API URL이 설정되지 않았습니다.');

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
      } else if (response.statusCode == 404) {
        setState(() {
          _pointHistory = [];
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
          _buildTotalPointsCard(), // ✅ 보유 포인트 카드 수정 완료
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

  /// ✅ 보유 포인트 표시 카드 (수정 완료)
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '보유 포인트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                '$_totalPoints p',  // ✅ 보유 포인트를 동적으로 표시
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointHistoryList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        itemCount: _pointHistory.length,
        itemBuilder: (context, index) {
          final item = _pointHistory[index];
          final isAdd = item['point_status'] == 'ADD';
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['point_reason'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15.0),
                              Text(
                                item['created_at'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${isAdd ? '+' : '-'}${item['point_amount']}p',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isAdd ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}