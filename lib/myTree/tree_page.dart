import 'package:flutter/material.dart';
import '../myPage/myCoupon/coupon_page.dart'; // 쿠폰 페이지 import
import 'tree_api_service.dart';
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

  // 상태바 진행도 증가
  void increaseProgress(int cost) {
    setState(() {
      int rangeStart = levelPoints[currentLevel];
      int rangeEnd = levelPoints[currentLevel + 1];
      double progressIncrease = cost / (rangeEnd - rangeStart);

      levelProgress += progressIncrease;

      // 초과된 진행도를 처리
      while (levelProgress >= 1.0 && currentLevel < levelPoints.length - 2) {
        double overflowPoints = (levelProgress - 1.0) * (rangeEnd - rangeStart);
        levelProgress = 0.0; // 현재 레벨 진행도 초기화

        // 레벨업 모달 표시
        showLevelUpModal(context, currentLevel, (newLevel) {
          setState(() {
            currentLevel = newLevel; // 레벨 업데이트
            rangeStart = levelPoints[currentLevel];
            rangeEnd = levelPoints[currentLevel + 1];

            // 초과된 포인트를 다음 레벨 진행도로 이어가기
            levelProgress = overflowPoints / (rangeEnd - rangeStart);

            // 나무 상태 업데이트
            treeState = getTreeState(currentLevel);
            message = getTreeMessage(currentLevel);
            treeImage = getTreeImage(currentLevel);
          });
        });
        break; // 한 번에 한 단계씩 레벨업
      }
    });
  }

  // 액션 수행
  void handleAction(String action, int cost) {
    if (points < cost) {
      // 포인트 부족 모달
      showInsufficientPointsModal(context);
    } else {
      // 포인트 충분하면 액션 수행
      showActionModal(
        context,
        action: action,
        cost: cost,
        onConfirm: () {
          setState(() {
            points -= cost; // 포인트 차감
            increaseProgress(cost); // 상태바 진행
          });
        },
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