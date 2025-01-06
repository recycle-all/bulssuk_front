import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'shoppingContent_page.dart'; // 상세 페이지 import

class ShoppingPage extends StatefulWidget {
  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  final URL = dotenv.env['URL'];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('$URL/shopping_products');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          products = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "친환경 제품 구매하기",
          style: TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: const Color(0xFFFFFEFD), // 배경색 추가
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () {
                // 상세 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShoppingContentPage(shoppingNo: product["shopping_no"]),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 16.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색 제거
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Color(0xFF12D3CF), // 민트색 테두리
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: product["shopping_img"] != null
                              ? Image.asset(
                            'assets/${product["shopping_img"]!.trim().replaceFirst('/uploads/images/', '')}',
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey),
                        ),
                        SizedBox(width: 16.0),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product["shopping_title"] ?? "No Title",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                "${product["shopping_point"] ?? 0}포인트",
                                style: TextStyle(
                                  color: Color(0xFF12D3CF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600, // 세미볼드 스타일
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                "모든 지역 구매 가능",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Text(
                              "${product["shopping_point"] ?? 0} 포인트 구매",
                              style: TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB0F4E6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.0), // 버튼 높이 조정
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              "상품권 교환",
                              style: TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Color(0xFFB0F4E6), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.0), // 버튼 높이 조정
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
      ),
    );
  }
}
