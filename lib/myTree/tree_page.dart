import 'package:flutter/material.dart';
import 'tree_api_service.dart';
import 'tree_coupon_page.dart';
import 'tree_modals.dart';
import 'tree_level_manage.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';

class TreePage extends StatefulWidget {
  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  int points = initialPoints;
  int availableCouponCount = 0;
  int currentLevel = 0;
  double progress = 0;
  String treeState = initialTreeState;
  String message = initialMessage;
  String treeImage = initialTreeImage;
  List<String> myCoupons = [];

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


  void handleAction(String action, int cost) {
    print("현재 포인트: $points, 필요한 포인트: $cost"); // 디버깅용
    if (points < cost) {
      // 포인트가 부족한 경우 "포인트가 부족합니다" 모달 호출
      print("포인트 부족!"); // 디버깅용
      showInsufficientPointsModal(context); // 포인트 부족 안내
    } else {
      // 포인트가 충분한 경우 확인 모달 표시
      showActionModal(
        context,
        action: action,
        cost: cost,
        onConfirm: () {
          setState(() {
            points -= cost; // 포인트 차감
            progress += cost / maxPoints; // 진행도 업데이트
            if (progress >= levelPoints[currentLevel] / maxPoints) {
              showLevelUpModal(context, currentLevel, (newLevel) {
                setState(() {
                  currentLevel = newLevel;
                  treeState = getTreeState(newLevel);
                  message = getTreeMessage(newLevel);
                  treeImage = getTreeImage(newLevel);
                  if (currentLevel == 4) {
                    showCompletionModal(context, myCoupons, (coupon) {
                      setState(() => myCoupons.add(coupon));
                    });
                  }
                });
              });
            }
          });
        },
      );
    }
  }



  void usePoints(int cost) {
    if (points >= cost) {
      setState(() {
        points -= cost;
        progress += cost / maxPoints;
        if (progress >= levelPoints[currentLevel] / maxPoints) {
          showLevelUpModal(context, currentLevel, (newLevel) {
            setState(() {
              currentLevel = newLevel;
              treeState = getTreeState(newLevel);
              message = getTreeMessage(newLevel);
              treeImage = getTreeImage(newLevel);
              if (currentLevel == 4) {
                showCompletionModal(context, myCoupons, (coupon) {
                  setState(() => myCoupons.add(coupon));
                });
              }
            });
          });
        }
      });
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreeCouponPage(
                            couponCount: myCoupons.length, // 쿠폰 개수 전달
                            myCoupons: myCoupons,
                          ), // 쿠폰 리스트 전달
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
            ),
            SizedBox(height: 70),
            buildProgressBar(context),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
              decoration: BoxDecoration(
                color: Color(0xFFFCF9EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(message, style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 40),
            Image.asset(treeImage, height: 150),
            buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 2),
    );
  }


  Widget buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상태바
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
              // 채워진 상태
              FractionallySizedBox(
                widthFactor: progress.clamp(0.05, 1.0), // 최소 진행도 5%
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF67EACA), Color(0xFF33CC99)], // 그라데이션 색상
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10), // 상태바와 숫자 간격
          // 상태바 아래 숫자
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0", style: TextStyle(fontSize: 12)),
              Text("80", style: TextStyle(fontSize: 12)),
              Text("240", style: TextStyle(fontSize: 12)),
              Text("720", style: TextStyle(fontSize: 12)),
              Text("2160", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }


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
      onTap: () => showActionModal(
        context,
        action: label, // 액션 이름 (예: "물주기")
        cost: cost, // 비용 (예: 10포인트)
        onConfirm: () => usePoints(cost), // 확인 버튼 클릭 시 포인트 사용
      ),
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
