import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recyclingDetail_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class RecyclingMenuPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const RecyclingMenuPage({required this.categoryId, required this.categoryName, Key? key}) : super(key: key);

  @override
  _RecyclingMenuPageState createState() => _RecyclingMenuPageState();
}

class _RecyclingMenuPageState extends State<RecyclingMenuPage> {
  List<dynamic> subcategories = [];
  bool isLoading = true;
  int? tappedIndex; // 클릭된 항목의 인덱스를 저장

  // 중분류 데이터를 API로 가져오기
  Future<void> fetchSubcategories() async {
    try {
      final response = await http.get(
        Uri.parse('$URL/subcategories/${widget.categoryId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          subcategories = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubcategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.categoryName,
          style: TextStyle(
            fontSize: 18, // 텍스트 크기 조정
          ),
        ), // 전달받은 카테고리 이름을 제목으로 설정
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 줄에 3개의 박스
            crossAxisSpacing: 8.0, // 박스 간 간격
            mainAxisSpacing: 8.0, // 세로 간격
            childAspectRatio: 1.5, // 박스의 가로/세로 비율
          ),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = subcategories[index];
            return GestureDetector(
              onTap: () async {
                // 클릭 시 색상 변경
                setState(() {
                  tappedIndex = index;
                });

                // 딜레이
                await Future.delayed(const Duration(milliseconds: 200));

                // 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecyclingDetailPage(
                        subcategoryId: subcategory['subcategory_no'],
                        subcategoryName: subcategory['subcategory_name']
                    ),
                  ),
                );

                // 색상 초기화
                setState(() {
                  tappedIndex = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: tappedIndex == index
                      ? const Color(0xFFB0F4E6) // 클릭 시 색상 변경
                      : Colors.white, // 기본 배경색
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFF67EACA), // 테두리 색상
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    subcategory['subcategory_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
