import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/top_nav.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class ReupcyclingPage extends StatefulWidget {
  final int companyId; // 회사 ID

  const ReupcyclingPage({super.key, required this.companyId});

  @override
  State<ReupcyclingPage> createState() => _ReupcyclingPageState();
}

class _ReupcyclingPageState extends State<ReupcyclingPage> {
  late Future<Map<String, dynamic>> _companyDetailsFuture;

  @override
  void initState() {
    super.initState();
    _companyDetailsFuture = fetchCompanyDetails(widget.companyId);
  }

  // API 호출 함수
  Future<Map<String, dynamic>> fetchCompanyDetails(int companyId) async {
    final url = Uri.parse('$URL/company/$companyId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load company details');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '리사이클링, 업사이클링 기업', // 제목 텍스트
          style: TextStyle(
            fontWeight: FontWeight.normal, // 볼드 제거
            fontSize: 18, // 텍스트 크기 조정
            color: Colors.black, // 텍스트 색상 변경
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _companyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final company = snapshot.data!['company'];
          final products = snapshot.data!['products'] as List;
          final companyImgPath = 'assets${company['company_img'].replaceFirst(
              '/uploads/images', '')}';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 상단 이미지와 제목
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF9EC),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            companyImgPath,
                            fit: BoxFit.cover,
                            width: MediaQuery
                                .of(context)
                                .size
                                .width,
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          company['company_name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          company['company_content'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. '상품 보러가기' 버튼
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/shopping');
                    },
                    child: const Text(
                      '상품 보러가기',
                      style: TextStyle(
                        color: Colors.black, // 글자 색 변경
                        fontWeight: FontWeight.normal, // 글자 굵기 추가 (선택 사항)
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB0F4E6), // 버튼 배경 색
                      minimumSize: const Size(double.infinity, 50), // 너비 전체로
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 제품 리스트
                  const Text(
                    '대표 제품',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true, // SingleChildScrollView 내부에서 사용 시 필요
                    physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductItem(
                        product['product_name'],
                        product['product_img'],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 제품 아이템 위젯
  Widget _buildProductItem(String title, String imageUrl) {
    // 이미지 경로를 assets 경로로 변환
    final imagePath = 'assets/${imageUrl.trim().replaceFirst('/uploads/images/', '')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 50);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
