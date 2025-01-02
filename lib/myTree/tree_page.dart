import 'package:flutter/material.dart';
import '../myPage/myCoupon/coupon_page.dart'; // 쿠폰 페이지 import
import 'tree_api_service.dart'; // API 서비스 import
import 'tree_modals.dart';
import 'tree_level_manage.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';

class TreePage extends StatefulWidget {
  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  int points = 100; // 현재 보유 포인트
  int availableCouponCount = 0; // 사용 가능한 쿠폰 수
  int currentLevel = 0; // 현재 레벨
  double levelProgress = 0.0; // 상태바 진행도 (0 ~ 1)
  String treeState = initialTreeState; // 나무 상태
  String message = initialMessage; // 상태 메시지
  String treeImage = initialTreeImage; // 나무 이미지
  List<String> myCoupons = []; // 쿠폰 목록

  final List<int> levelPoints = [0, 80, 240, 720, 2160]; // 레벨별 포인트 범위

  @override
  void initState() {
    super.initState();

    // 총 포인트 가져오기
    fetchTotalPoints().then((value) {
      setState(() {
        points = value;
      });
    });

    // 사용 가능한 쿠폰 수 가져오기
    fetchAvailableCoupons().then((value) {
      setState(() {
        availableCouponCount = value;
      });
    });
  }

  // 포인트 차감 액션 수행
  void handleAction(String action, int cost) async {
    if (points < cost) {
      // 포인트 부족 모달
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('알림'),
          content: Text('포인트가 부족합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    } else {
      // 포인트 충분하면 API 호출
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$action'),
          content: Text('$cost p를 사용해서 $action를 하시겠어요?'), // 동적 문구
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // 모달 닫기
                try {
                  // API 호출
                  final newPoints = await performTreeAction(action, cost);

                  setState(() {
                    points = newPoints; // 서버에서 반환된 포인트로 업데이트
                  });

                  // 성공 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$action 성공! 현재 포인트: $points')),
                  );
                } catch (e) {
                  // 실패 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('작업 실패: $e')),
                  );
                }
              },
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
      resizeToAvoidBottomInset: true,
      appBar: const TopNavigationSection(title: '나무키우기'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            buildTopInfoRow(),
            SizedBox(height: 70),
            buildProgressBar(context),
            SizedBox(height: 10),
            buildMessageBox(),
            SizedBox(height: 40),
            Image.asset(treeImage, height: 150),
            buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 2),
    );
  }

  // 상단 정보
  Widget buildTopInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CouponPage(), // CouponPage로 이동
                ),
              );
            },
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 20, color: Colors.black),
                SizedBox(width: 5),
                Text("내 쿠폰함", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text("${availableCouponCount}개", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text("현재 내 포인트", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text("$points p", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 상태바
  Widget buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              // 상태바 배경
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // 현재 레벨 진행도
              FractionallySizedBox(
                widthFactor: levelProgress.clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF67EACA), Color(0xFF33CC99)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${levelPoints[currentLevel]}", style: TextStyle(fontSize: 12)),
              Text("${levelPoints[currentLevel + 1]}", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // 메시지 박스
  Widget buildMessageBox() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
      decoration: BoxDecoration(
        color: Color(0xFFFCF9EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: TextStyle(fontSize: 18)),
    );
  }

  // 액션 버튼들
  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildActionButton('물주기', 'assets/water.png', 10),
          buildActionButton('햇빛쐬기', 'assets/sun.png', 20),
          buildActionButton('비료주기', 'assets/fertilizer.png', 50),
        ],
      ),
    );
  }

  Widget buildActionButton(String label, String imagePath, int cost) {
    return GestureDetector(
      onTap: () => handleAction(label, cost),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFF67EACA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 40, width: 40),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('$cost p', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}