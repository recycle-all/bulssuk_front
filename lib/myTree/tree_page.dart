import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import '../../widgets/bottom_nav.dart'; // 하단 네비게이션 가져오기
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../myPage/point/point_page.dart';  // 포인트 페이지 임포트
import '../myPage/myCoupon/coupon_page.dart'; // 쿠폰 페이지 임포트

final URL = dotenv.env['URL'];
final storage = FlutterSecureStorage();
final Map<String, int> levelThresholds = {
  "씨앗": 80,
  "새싹": 240,
  "가지": 720,
  "나무": 2160,
};

double calculateLevelPercent(int points, String status) {
  int maxPoints = levelThresholds[status] ?? 1; // 해당 레벨의 최대 포인트
  int minPoints = 0;

  // 이전 레벨의 최대 포인트 가져오기
  if (status == "새싹") minPoints = levelThresholds["씨앗"]!;
  else if (status == "가지") minPoints = levelThresholds["새싹"]!;
  else if (status == "나무") minPoints = levelThresholds["가지"]!;

  // 퍼센트 계산
  return (points - minPoints) / (maxPoints - minPoints);
}


class TreePage extends StatefulWidget {
  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  int treePoints = 0; // 나무 총 포인트
  String treeStatus = "로딩 중..."; // 나무 현재 상태
  String treeImage = ""; // 나무 이미지 URL
  String treeContent = "잠시만 기다려주세요."; // 나무 상태 멘트
  String? userNo; // 사용자 번호
  String? selectedCoupon; // 사용자가 선택한 쿠폰
  bool hasReceivedCoupon = false; // 쿠폰을 받았는지 여부

  int points = 0;
  int availableCoupons = 0;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadUserData(); // 사용자 데이터 로드
    fetchUserPoints();
    fetchCoupons();
    fetchTreeManageActions();
  }

  // 유저 데이터
  Future<void> loadUserData() async {
    try {
      userNo = await _storage.read(key: 'user_no');
      if (userNo == null) {
        print('Error: user_no not found in SecureStorage.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      print('Loaded user_no: $userNo');

      // fetchTreeState 호출 로그 추가
      print('Calling fetchTreeState...');
      await fetchTreeState();
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // 상단 포인트 조회
  Future<void> fetchUserPoints() async {
    final token = await storage.read(key: "jwt_token");
    final response = await http.get(
      Uri.parse('$URL/total_point'),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        points = data['totalPoints'];
      });
      print("포인트 업데이트 완료: $points"); // 디버깅 로그 추가
    } else {
      print("포인트 조회 실패: ${response.body}");
    }
  }

  // 상단 쿠폰 조회
  Future<void> fetchCoupons() async {
    final token = await storage.read(key: "jwt_token");
    if (token == null) {
      print("JWT 토큰이 없습니다.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요합니다.")),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$URL/user_coupon'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            availableCoupons = data['availableCouponCount'];
            final coupons = data['data'] as List;

            // 이미 쿠폰을 받은 경우 확인
            if (availableCoupons > 0) {
              hasReceivedCoupon = true;
            }

            print("가져온 쿠폰 데이터: $coupons");
          });
        } else {
          availableCoupons = 0; // 쿠폰이 없으면 0으로 설정
          hasReceivedCoupon = false;
          print("쿠폰 조회 실패: ${data['message']}"
          );
        }
      } else {
        print("HTTP 요청 실패: ${response.body}");
        setState(() {
          availableCoupons = 0; // 쿠폰이 없으면 0으로 설정
          hasReceivedCoupon = false;
        });
      }
    } catch (e) {
      print("쿠폰 데이터를 가져오는 중 예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("쿠폰 데이터를 가져오는 중 문제가 발생했습니다.")),
      );
    }
  }

  // 쿠폰 데이터 가져오기
  Future<List<dynamic>> fetchAvailableCoupons() async {
    try {
      final token = await storage.read(key: "jwt_token");
      final response = await http.get(
        Uri.parse('$URL/tree/coupon'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['coupons'] ?? [];
      } else {
        print("쿠폰 데이터 조회 실패: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching coupons: $e");
      return [];
    }
  }

  // 쿠폰 선택 모달 함수
  void showCouponSelectionDialog() async {
    final coupons = await fetchAvailableCoupons();

    if (coupons.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("사용 가능한 쿠폰이 없습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
      return;
    }

    selectedCoupon = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFCF9EC),
              title: const Text(
                "쿠폰 선택",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center, // 제목 중앙 정렬
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: coupons.map<Widget>((coupon) {
                    return RadioListTile<String>(
                      title: Text(coupon['coupon_name']),
                      subtitle: Text(coupon['coupon_type']),
                      value: coupon['coupon_no'].toString(),
                      groupValue: selectedCoupon,
                      onChanged: (value) {
                        setState(() {
                          selectedCoupon = value; // 선택된 쿠폰 업데이트
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 취소 버튼
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          "취소",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 확인 버튼
                    GestureDetector(
                      onTap: () async {
                        if (selectedCoupon != null) {
                          Navigator.pop(context);
                          print("선택된 쿠폰 번호: $selectedCoupon");

                          // 쿠폰 저장 호출
                          if (userNo != null) {
                            await saveSelectedCoupon(userNo!, selectedCoupon!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("사용자 정보를 확인할 수 없습니다.")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("쿠폰을 선택해주세요.")),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          "확인",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 선택한 쿠폰을 사용자 쿠폰함에 저장
  Future<void> saveSelectedCoupon(String userNo, String couponNo) async {
    try {
      final token = await storage.read(key: "jwt_token");
      final response = await http.post(
        Uri.parse('$URL/tree/select_coupon'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "user_no": userNo,
          "coupon_no": couponNo,
        }),
      );

      if (response.statusCode == 200) {
        print("쿠폰이 성공적으로 저장되었습니다.");
        setState(() {
          hasReceivedCoupon = true; // 쿠폰 저장 성공 시 업데이트
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("쿠폰이 성공적으로 저장되었습니다.")),
        );
      } else {
        print("쿠폰 저장 실패: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("쿠폰 저장에 실패했습니다.")),
        );
      }
    } catch (e) {
      print("Error saving selected coupon: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("쿠폰 저장 중 오류가 발생했습니다.")),
      );
    }
  }

  // 나무 상태 데이터베이스에서 가져오기
  Future<void> fetchTreeState() async {
    try {
      String? storedUserNo = await storage.read(key: "user_no");
      String? token = await storage.read(key: "jwt_token");

      if (storedUserNo == null || token == null) {
        print("Error: user_no 또는 jwt_token이 Secure Storage에 저장되어 있지 않습니다.");
        return;
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final uri = Uri.parse('$URL/tree/state/$storedUserNo');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          treeStatus = data['tree_status'] ?? "상태 없음";
          treeContent = data['tree_content'] ?? "내용 없음";
          treeImage = 'assets${data['tree_img'].replaceFirst('/uploads/images', '')}';
          treePoints = data['tree_points_total'] ?? 0;
        });

        // 레벨업 조건 확인
        checkLevelUp();
      } else {
        print("Failed to load tree state: ${response.body}");
      }
    } catch (e) {
      print("Error fetching tree state: $e");
    }
  }

  // 레벨업 로직
  void checkLevelUp() {
    double percent = calculateLevelPercent(treePoints, treeStatus);

    print(
        "레벨 확인: treeStatus=$treeStatus, treePoints=$treePoints, percent=$percent");

    if (percent >= 1.0) {
      if (treeStatus == "씨앗") {
        showLevelUpDialog("새싹");
      } else if (treeStatus == "새싹") {
        showLevelUpDialog("가지");
      } else if (treeStatus == "가지") {
        showLevelUpDialog("나무");
      } else if (treeStatus == "나무") {
        showLevelUpDialog("꽃");
      }
    }
  }

  // 레벨업 모달 함수
  void showLevelUpDialog(String nextLevel) {
    showDialog(
      context: context,
      barrierDismissible: false, // 모달 외부를 누르면 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 모달 둥근 테두리
          ),
          backgroundColor: const Color(0xFFFCF9EC), // 모달 배경색
          title: Column(
            children: [
              Text(
                "레벨업!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF67EACA),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "$nextLevel(으)로 레벨업 하시겠습니까?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // 버튼을 모달 가운데 정렬
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ), // 버튼 크기 설정
                minimumSize: const Size(110, 50), // 버튼 최소 크기 설정
                backgroundColor: Colors.white, // 배경색
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 둥근 버튼
                ),
                foregroundColor: Colors.black, // 텍스트 색상
                textStyle: const TextStyle(
                  fontSize: 16, // 텍스트 크기
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text(
                  "확인"
              ),
              onPressed: () async {
                Navigator.pop(context);
                await levelUp(nextLevel); // 레벨업 API 호출
              },
            ),
          ],
        );
      },
    );
  }

  // 레벨업 기능 함수
  Future<void> levelUp(String nextLevel) async {
    if (userNo == null) {
      print("Error: userNo가 null입니다. 레벨업 요청을 중단합니다.");
      return;
    }

    try {
      final endpoint = nextLevel == "새싹"
          ? "/tree/level_sprout"
          : nextLevel == "가지"
          ? "/tree/level_branch"
          : nextLevel == "나무"
          ? "/tree/level_tree"
          : "/tree/level_flower";

      final response = await http.post(
        Uri.parse('$URL$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_no": int.parse(userNo!)}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        await fetchTreeState(); // 레벨업 후 상태 새로고침
        print("$nextLevel 레벨업 성공");
      } else {
        print("$nextLevel 레벨업 실패: ${response.body}");
      }
    } catch (e) {
      print("Error leveling up to $nextLevel: $e");
    }
  }

  // 물주기, 햇빛쐬기, 비료주기 모달 함수
  void showActionDialog(String actionType) {
    final actionData = treeActions.firstWhere(
          (action) => action['tree_manage'] == actionType,
      orElse: () => null,
    );

    if (actionData == null) {
      print("Error: 해당 작업 데이터를 찾을 수 없습니다.");
      return;
    }

    // 이미지 경로를 생성
    final imagePath = 'assets${actionData['manage_img'].replaceFirst('/uploads/images', '')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 모달 둥근 테두리
          ),
          backgroundColor: const Color(0xFFFCF9EC), // 모달 배경색
          title: Column(
            children: [
              Image.asset(
                imagePath, // 이미지 경로
                height: 80, // 이미지 높이 조정
                fit: BoxFit.contain, // 이미지 비율 유지
              ),
              const SizedBox(height: 16),
              Text(
                "$actionType 하시겠습니까?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(20), // 모달 내부 여백 조정
          actionsAlignment: MainAxisAlignment.center, // 버튼을 모달 가운데 정렬
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼 간격 균등
              children: [
                // 취소 버튼
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ), // 버튼 크기 설정
                    minimumSize: const Size(110, 50), // 버튼 최소 크기 설정
                    backgroundColor: Colors.white, // 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 버튼
                    ),
                    foregroundColor: Colors.black, // 텍스트 색상
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // 텍스트 크기 설정
                    ),
                  ),
                  child: const Text("취소"),
                  onPressed: () => Navigator.pop(context),
                ),

                // 확인 버튼
                TextButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ), // 버튼 크기 설정
                    minimumSize: const Size(110, 50), // 버튼 최소 크기 설정
                    backgroundColor: Colors.white, // 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 둥근 버튼
                    ),
                    foregroundColor: Colors.black, // 텍스트 색상
                    textStyle: const TextStyle(
                      fontSize: 16, // 텍스트 크기
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(
                    "확인"
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    performAction(actionType); // API 호출
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

// 물주기, 햇빛쐬기, 비료주기 기능 함수
  Future<void> performAction(String actionType) async {
    if (userNo == null || userNo!.isEmpty) {
      print("Error: user_no가 null이거나 비어 있습니다.");
      return;
    }

    // 선택한 작업에 필요한 포인트 계산
    final selectedAction = treeActions.firstWhere(
          (action) => action['tree_manage'] == actionType,
      orElse: () => null,
    );

    if (selectedAction == null) {
      print("Error: 선택한 작업을 찾을 수 없습니다.");
      return;
    }

    final requiredPoints = int.parse(selectedAction['manage_points'].toString());
    if (points < requiredPoints) {
      // 포인트 부족 모달 호출
      showInsufficientPointsDialog();
      return;
    }

    try {
      // JWT 토큰 읽기
      print("Performing action: $actionType"); // 디버깅 로그 추가
      String? token = await storage.read(key: "jwt_token");
      if (token == null) {
        print("Error: jwt_token이 없습니다.");
        return;
      }

      String endpoint;
      if (actionType == "물주기") {
        endpoint = "/tree/water";
      } else if (actionType == "햇빛 쐬기") {
        endpoint = "/tree/sunlight";
      } else if (actionType == "비료 주기") {
        endpoint = "/tree/fertilizer";
      } else {
        throw Exception("Unknown action type: $actionType");
      }

      final uri = Uri.parse('$URL$endpoint');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 토큰 추가
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({"user_no": int.parse(userNo!)}),
      );

      if (response.statusCode == 200) {

        print("$actionType 성공");
        // 작업 성공 후 포인트와 나무 상태를 즉시 새로고침
        await fetchUserPoints(); // 상단 포인트 갱신
        await fetchTreeState(); // 나무 상태 갱신

      } else {
        print("$actionType 실패: ${response.body}");
      }
    } catch (e) {
      print("Error performing $actionType: $e");
    }
  }

  // 물주기, 햇빛쐬기, 비료주기 이미지 가져오기
  List<dynamic> treeActions = []; // tree_manage 데이터를 저장할 리스트
  Future<void> fetchTreeManageActions() async {
    final uri = Uri.parse('$URL/tree/manage'); // 백엔드 API URL
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        treeActions = data['data']; // tree_manage 데이터를 저장
      });
    } else {
      print("Failed to fetch tree_manage actions: ${response.body}");
    }
  }

  // 포인트 부족 모달 함수
  void showInsufficientPointsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 모달 외부를 눌러도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 모달 둥근 테두리
          ),
          backgroundColor: const Color(0xFFFCF9EC), // 모달 배경색
          title: const Center(
            child: Text(
              "포인트 부족",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: const Text(
            "포인트가 부족합니다.",
            textAlign: TextAlign.center, // 텍스트 중앙 정렬
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // 버튼을 모달 중앙 정렬
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                elevation: 0, // 그림자 제거
                minimumSize: const Size(110, 50), // 버튼 최소 크기 설정
                backgroundColor: Colors.white, // 버튼 배경색
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 둥근 버튼
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ), // 버튼 크기 설정
              ),
              child: const Text(
                "확인",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // 텍스트 색상
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // 모달 닫기
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(title: '나무 키우기'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 포인트 및 쿠폰 요약
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryTile(
                  title: "현재 내 포인트",
                  value: "$points P",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PointPage()),
                    );
                  },
                ),
                _summaryTile(
                  title: "내 쿠폰함",
                  value: "$availableCoupons 개",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CouponPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 50),

            // 나무 상태 및 게이지 바
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), // 둥근 모서리 반경 설정
                  child: LinearProgressIndicator(
                    value: calculateLevelPercent(treePoints, treeStatus),
                    minHeight: 20,
                    color: const Color(0xFF67EACA), // 게이지 바 색상
                    backgroundColor: Colors.grey[300], // 배경색
                  ),
                ),

                const SizedBox(height: 50),

                // 나무 멘트
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
                  decoration: BoxDecoration(
                    color: Color(0xFFFCF9EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treeContent,
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Image.asset(
                  treeImage,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, size: 150, color: Colors.grey); // 에러 처리
                  },
                ),
              ],
            ),
            const SizedBox(height: 70),

            // 작업 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: treeActions.map((action) {
                final imgPath = 'assets${action['manage_img'].replaceFirst('/uploads/images', '')}';

                return SizedBox(
                  width: 100, // 버튼 너비
                  height: 120, // 버튼 높이
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF67EACA)),
                      ),
                    ),
                    onPressed: () => showActionDialog(action['tree_manage']), // 작업 이름 전달
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // 콘텐츠를 중앙 정렬
                      children: [
                        Image.asset(
                          imgPath, // 이미지 경로
                          height: 40, // 이미지 크기 조정
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 40, color: Colors.grey); // 에러 처리
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['tree_manage'], // 작업 이름
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${action['manage_points']}p", // 포인트 표시
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20,),
            // "쿠폰 받기" 버튼
            if (treeStatus == "꽃" && !hasReceivedCoupon)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  backgroundColor: const Color(0xFF67EACA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showCouponSelectionDialog();
                },
                child: const Text(
                  "쿠폰 받기",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationSection(currentIndex: 2),
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 텍스트 간 간격 조정
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(width: 8), // 제목과 숫자 간격
          Container(
            width: 60, // 박스 너비 설정
            height: 30, // 박스 높이 설정
            alignment: Alignment.center, // 텍스트를 박스 중앙에 배치
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18), // 둥근 모서리
              border: Border.all(
                color: Colors.grey, // 테두리 색상
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}