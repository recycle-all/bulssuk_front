import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'shoppingContent_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ShoppingPage extends StatefulWidget {
  @override
  _ShoppingPageState createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  List<dynamic> products = [];
  List<dynamic> userCoupons = []; // 사용자가 보유한 쿠폰 리스트
  bool isLoading = true;
  final URL = dotenv.env['URL'];
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  int? userNo;
  int? userPoints; // 사용자 포인트 저장

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _loadUserNo();
  }

  Future<void> _loadUserNo() async {
    final userNoString = await _storage.read(key: 'user_no');
    if (userNoString == null) {
      print('Error: user_no not found in SecureStorage.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      userNo = int.parse(userNoString);
      print('Loaded user_no: $userNo');
      await fetchUserPoints(); // 사용자 포인트를 로드
      await fetchUserCoupons(); // 사용자가 보유한 쿠폰 로드
    } catch (e) {
      print('Error parsing user_no: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> fetchUserPoints() async {
    final url = Uri.parse('$URL/shopping_point?user_no=$userNo');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoints = data[0]['point_total']; // 사용자 포인트 설정
        });
      } else {
        throw Exception("Failed to load user points");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        userPoints = 0; // 오류 시 기본값
      });
    }
  }

  Future<void> fetchUserCoupons() async {
    final url = Uri.parse('$URL/shopping_coupon?user_no=$userNo');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          userCoupons = data;
        });
      } else {
        throw Exception("Failed to load user coupons");
      }
    } catch (e) {
      print("Error: $e");
    }
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

  void handlePurchase(int productPoints) {
    if (userPoints == null) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFFe7fbf9), // 모달의 배경색
          title: Text('오류'),
          content: Text('사용자 포인트 정보를 불러올 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    if (userPoints! >= productPoints) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFFe7fbf9), // 모달의 배경색
          title: Text('구매 가능'),
          content: Text('상품을 구매하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 구매 로직 추가
                Navigator.of(context).pop();
              },
              child: Text('구매'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFFe7fbf9), // 모달의 배경색
          title: Text('구매 불가'),
          content: Text('포인트가 부족합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void handleCouponExchange(int productCouponNo, String productName) {
    bool hasCoupon = userCoupons.any((coupon) => coupon['coupon_no'] == productCouponNo);

    if (hasCoupon) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFFe7fbf9), // 모달의 배경색
          title: Text('교환 가능'),
          content: Text('$productName 교환권을 사용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 교환 로직 추가
                Navigator.of(context).pop();
              },
              child: Text('교환'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFFe7fbf9), // 모달의 배경색
          title: Text('교환 불가'),
          content: Text('해당 상품의 교환권을 갖고 있지 않습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        ),
      );
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
        backgroundColor: const Color(0xFFFFFEFD),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ShoppingContentPage(shoppingNo: product["shopping_no"], onPurchase: handlePurchase, // 함수 전달
                            onCouponExchange: handleCouponExchange, // 함수 전달),
                    ),
                  ));
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.0),
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Color(0xFF95f5f3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    fontWeight: FontWeight.w600,
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
                              onPressed: () {
                                handlePurchase(product["shopping_point"]);
                              },
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
                              onPressed: () {
                                handleCouponExchange(
                                  product["coupon_no"],
                                  product["shopping_title"] ?? "상품",
                                );
                              },
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
        ));
  }
}
