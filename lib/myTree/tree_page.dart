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
  int points = 0;
  int availableCoupons = 0;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadUserData(); // 사용자 데이터 로드
    fetchUserPoints();
    fetchCoupons();
  }

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
    } else {
      print("포인트 조회 실패: ${response.body}");
    }
  }

  Future<void> fetchCoupons() async {
    final token = await storage.read(key: "jwt_token");
    final response = await http.get(
      Uri.parse('$URL/user_coupon'),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        availableCoupons = data['coupons'].length;
      });
    } else {
      print("쿠폰 조회 실패: ${response.body}");
    }
  }

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
          treeImage = "$URL${data['tree_img']}" ?? "";
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

  void checkLevelUp() {
    double percent = calculateLevelPercent(treePoints, treeStatus);

    print("레벨 확인: treeStatus=$treeStatus, treePoints=$treePoints, percent=$percent");

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


  void showLevelUpDialog(String nextLevel) {
    showDialog(
      context: context,
      barrierDismissible: false, // 모달 외부를 누르면 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$nextLevel으로 레벨업 하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('확인'),
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

  void showActionDialog(String actionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$actionType 하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                performAction(actionType); // API 호출
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> performAction(String actionType) async {
    if (userNo == null || userNo!.isEmpty) {
      print("Error: user_no가 null이거나 비어 있습니다.");
      return;
    }

    try {
      // JWT 토큰 읽기
      String? token = await storage.read(key: "jwt_token");
      if (token == null) {
        print("Error: jwt_token이 없습니다.");
        return;
      }

      final endpoint = actionType == "물주기"
          ? "/tree/water"
          : actionType == "햇빛쐬기"
          ? "/tree/sunlight"
          : "/tree/fertilizer";

      final uri = Uri.parse('$URL$endpoint');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 토큰 추가
      };

      // Request 디버깅
      print("Request URL: $uri");
      print("Request Headers: $headers");
      print("Request Body: ${jsonEncode({"user_no": int.parse(userNo!)})}");

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({"user_no": int.parse(userNo!)}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        await fetchTreeState(); // 상태 새로고침
        print("$actionType 성공");
      } else {
        print("$actionType 실패: ${response.body}");
      }
    } catch (e) {
      print("Error performing $actionType: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '나무 키우기',
      ),
      body: treeStatus == "로딩 중..."
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    treeStatus,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Image.network(
                    treeImage,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, size: 200);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    treeContent,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: calculateLevelPercent(treePoints, treeStatus),
                    minHeight: 10,
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => showActionDialog("물주기"),
                        child: Text('물주기'),
                      ),
                      ElevatedButton(
                        onPressed: () => showActionDialog("햇빛쐬기"),
                        child: Text('햇빛쐬기'),
                      ),
                      ElevatedButton(
                        onPressed: () => showActionDialog("비료주기"),
                        child: Text('비료주기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationSection(currentIndex: 2),
    );
  }

}