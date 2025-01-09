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

        // 각 상품에 대해 회사 이름을 가져오는 작업 추가
        for (var product in data) {
          final companyName = await fetchCompanyName(product["shopping_title"]);
          product["company_name"] = companyName; // company_name을 각 상품에 추가
        }

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

// 회사 이름 가져오는 함수
  Future<String> fetchCompanyName(String shoppingTitle) async {
    final url = Uri.parse('$URL/company_name?shopping_title=$shoppingTitle');
    print('Fetching company name for URL: $url'); // 요청 URL 출력
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response for $shoppingTitle: $data'); // 응답 데이터 출력
        return data['company_name'] ?? 'Unknown'; // 회사 이름 반환
      } else {
        print('Failed to fetch company name. Status code: ${response.statusCode}');
        throw Exception("Failed to fetch company name");
      }
    } catch (e) {
      print("Error fetching company name: $e");
      return 'Unknown'; // 오류 시 기본값
    }
  }
  void handlePurchase(int productPoints) {
    if (userPoints == null) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) =>
            AlertDialog(
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
        builder: (context) =>
            AlertDialog(
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
        builder: (context) =>
            AlertDialog(
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
    bool hasCoupon = userCoupons.any((coupon) =>
    coupon['coupon_no'] == productCouponNo);

    if (hasCoupon) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경을 투명하게 설정
        builder: (context) =>
            AlertDialog(
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
        builder: (context) =>
            AlertDialog(
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
        title: Text(
          '친환경 제품 구매하기', // 제목 텍스트
          style: TextStyle(
            fontWeight: FontWeight.normal, // 볼드 제거
            fontSize: 18, // 텍스트 크기 조정
            color: Colors.black, // 텍스트 색상 변경
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFEFD),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 좌우 여백 설정
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 한 줄에 2개의 상품
            crossAxisSpacing: 8.0, // 가로 간격
            mainAxisSpacing: 16.0, // 세로 간격
            childAspectRatio: 0.72, // 카드의 가로세로 비율 조정
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingContentPage(
                      shoppingNo: product["shopping_no"],
                      onPurchase: handlePurchase,
                      onCouponExchange: handleCouponExchange,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // 상품 이미지
                  AspectRatio(
                    aspectRatio: 1, // 정사각형 비율 유지
                    child: Container(
                      width:120,
                      height:120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                        image: product["shopping_img"] != null
                            ? DecorationImage(
                          image: AssetImage(
                            'assets/${product["shopping_img"]!.trim().replaceFirst('/uploads/images/', '')}',
                          ),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: product["shopping_img"] == null
                          ? Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  // 상품 이름
                  Text(
                    "[${product["company_name"] ?? "Unknown"}] ${product["shopping_title"] ?? "No Title"}",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0),
                  // 포인트 정보
                  Text(
                    "${product["shopping_point"] ?? 0}포인트",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Color(0xFF12D3CF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

    );
  }
}
