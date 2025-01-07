import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ShoppingContentPage extends StatefulWidget {
  final int shoppingNo; // shopping_no 전달 받음
  final Function(int) onPurchase; // 포인트 구매 함수
  final Function(int, String) onCouponExchange; // 상품권 교환 함수
  ShoppingContentPage({
    required this.shoppingNo,
    required this.onPurchase,
    required this.onCouponExchange,
  });

  @override
  _ShoppingContentPageState createState() => _ShoppingContentPageState();
}

class _ShoppingContentPageState extends State<ShoppingContentPage> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  final URL = dotenv.env['URL'];

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    final url = Uri.parse('$URL/shopping_product?shopping_no=${widget.shoppingNo}');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            product = data[0]; // 첫 번째 상품 정보 가져오기
            isLoading = false;
          });
        } else {
          throw Exception("Empty data");
        }
      } else {
        throw Exception("Failed to fetch product details");
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
          : product == null
          ? Center(child: Text("상품 정보를 불러올 수 없습니다."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                Expanded(
                  flex: 2, // 이미지 비율 증가
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: product != null && product!["shopping_img"] != null
                        ? Image.asset(
                      'assets/${product!["shopping_img"]!.trim().replaceFirst('/uploads/images/', '')}',
                      fit: BoxFit.cover,
                    )
                        : Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 16.0),
                // Product Details
                Expanded(
                  flex: 3, // 텍스트 영역 비율 감소
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product!["shopping_title"] ?? "No Title",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "${product!["shopping_point"] ?? 0}포인트",
                        style: TextStyle(
                          color: Color(0xFF12D3CF),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        "모든 지역 구매 가능",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8.0), // 간격 추가
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onPurchase(product!["shopping_point"]);
                              },
                              child: Text(
                                "${product!["shopping_point"] ?? 0} 포인트 구매",
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFB0F4E6), // 버튼 배경색
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0), // 버튼 모서리 둥글게
                                ),
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.0), // 버튼 간 간격
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onCouponExchange(
                                  product!["coupon_no"],
                                  product!["shopping_title"] ?? "상품",
                                );
                              },
                              child: Text(
                                "상품권 교환",
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Color(0xFFB0F4E6), // 버튼 테두리 색상
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: jsonDecode(product!["shopping_content"]).length,
                itemBuilder: (context, index) {
                  final item = jsonDecode(product!["shopping_content"])[index];

                  if (item is Map && item["type"] == "image") {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        item["src"],
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 50, color: Colors.grey);
                        },
                      ),
                    );
                  } else if (item is Map && item["type"] == "text") {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        item["text"],
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    );
                  } else if (item is String && Uri.tryParse(item)?.hasAbsolutePath == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        item,
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 50, color: Colors.grey);
                        },
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
