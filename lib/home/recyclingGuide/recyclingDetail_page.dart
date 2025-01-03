import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class RecyclingDetailPage extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;

  const RecyclingDetailPage({required this.subcategoryId, required this.subcategoryName, Key? key}) : super(key: key);

  @override
  _RecyclingDetailPageState createState() => _RecyclingDetailPageState();
}

class _RecyclingDetailPageState extends State<RecyclingDetailPage> {
  Map<String, dynamic>? detail;
  bool isLoading = true;

  // 상세 데이터를 API로 가져오기
  Future<void> fetchDetail() async {
    try {
      final response = await http.get(
        Uri.parse('$URL/detail/${widget.subcategoryId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          detail = json.decode(response.body).first; // API 응답에서 첫 번째 데이터 사용
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      print('Error fetching details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.subcategoryName), // 전달받은 카테고리 이름을 제목으로 설정
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // 스크롤 가능하도록 수정
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail != null) ...[
                // 데이터베이스 경로를 assets 경로로 변환
                Image.asset(
                  'assets/${detail!['guide_img'].trim().replaceFirst('/uploads/images/', '')}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 50);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  detail!['guide_content'],
                  style: const TextStyle(fontSize: 16),
                ),
              ] else
                const Text('No details available'),
            ],
          ),
        ),
      ),
    );
  }
}