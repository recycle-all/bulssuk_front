import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'tree_coupon_page.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';

class TreePage extends StatefulWidget {
  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  int points = 5000; // 초기 포인트
  final int maxPoints = 2160; // 상태바의 최대 값
  String treeState = "씨앗"; // 나무 상태
  String message = "응애 나 씨앗"; // 상태 메시지
  String treeImage = 'assets/seed.png'; // 기본 이미지
  double progress = 0; // 상태바 게이지 (0.0 ~ 1.0)
  final List<int> levelPoints = [80, 240, 720, 2160]; // 레벨업 기준점
  int currentLevel = 0; // 현재 레벨 (0: 씨앗, 1: 새싹, 2: 나뭇가지, 3: 나무, 4: 꽃)
  String selectedCoupon = "플라스틱 방앗간 제품 교환권"; // 기본 선택 값
  List<String> myCoupons = []; // 쿠폰 목록 저장

  // 쿠폰 개수를 동적으로 계산
  int get couponCount => myCoupons.length;

  void showLevelUpModal() {
    showDialog(
      context: context,
      barrierDismissible: false, // 모달 외부 클릭 시 닫히지 않음
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // 제목과 내용 간격 추가
            child: Text("레벨업"),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10.0), // 내용과 버튼 간격 추가
            child: Text("레벨업 하시겠습니까?"),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                levelUp();
              },
              child: Text(
                "레벨업하기",
                style: TextStyle(color: CupertinoColors.activeBlue), // 텍스트 색상 파란색
              ),
            ),
          ],
        );
      },
    );
  }



  // 레벨업 처리
  void levelUp() {
    setState(() {
      if (currentLevel < levelPoints.length) {
        currentLevel++; // 다음 레벨로 증가
        switch (currentLevel) {
          case 1:
            treeState = "새싹";
            message = "응애 나 새싹";
            treeImage = 'assets/sprout.png';
            break;
          case 2:
            treeState = "나뭇가지";
            message = "ㅎㅇ 난 나뭇가지";
            treeImage = 'assets/branch.png';
            break;
          case 3:
            treeState = "나무";
            message = "후훗 난 나무";
            treeImage = 'assets/tree.png';
            break;
          case 4:
            treeState = "꽃";
            message = "짜잔 난 꽃";
            treeImage = 'assets/flower.png';

            // 꽃 레벨로 변경된 경우 완료 모달 표시
            Future.delayed(Duration(milliseconds: 500), () {
              // 레벨업 UI 업데이트 후 모달 표시
              showCompletionModal();
            });
            break;
        }
      }
    });
  }

  // 액션 버튼을 눌렀을 때 호출되는 함수
  void handleAction(String action, int cost) {
    if (points >= cost) {
      // 포인트가 충분한 경우 확인 모달 표시
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 위치를 중앙으로
              children: [
                Image.asset(
                  action == '물주기'
                      ? 'assets/water.png'
                      : action == '햇빛쐬기'
                      ? 'assets/sun.png'
                      : 'assets/fertilizer.png',
                  height: 30,
                  width: 30,
                ),
                SizedBox(height: 10), // 이미지와 텍스트 사이 간격
                Text('$action'),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0), // 텍스트와 위아래 간격
              child: Text(
                "$cost 포인트를 사용해서\n$action 하시겠어요?", // 텍스트 개행
                softWrap: true, // 자동 줄바꿈 허용
                overflow: TextOverflow.visible, // 텍스트 잘림 방지
                textAlign: TextAlign.center, // 텍스트 중앙 정렬
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "아니요",
                  style: TextStyle(color: CupertinoColors.activeBlue), // 텍스트 색상 파란색
                ),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  usePoints(cost); // 포인트 사용
                },
                child: Text(
                  "네",
                  style: TextStyle(color: CupertinoColors.activeBlue), // 텍스트 색상 파란색
                ),
              ),
            ],
          );
        },
      );
    } else {
      // 포인트가 부족한 경우
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed),
                SizedBox(width: 10),
                Text("포인트 부족"),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0), // 텍스트와 위아래 간격
              child: Text(
                "포인트가 부족해요.\n포인트를 쌓으러 가시겠어요?", // 텍스트 개행
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "아니요",
                  style: TextStyle(color: CupertinoColors.activeBlue), // 텍스트 색상 파란색
                ),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  // 포인트 충전 화면으로 이동 로직 추가 가능
                },
                child: Text(
                  "네",
                  style: TextStyle(color: CupertinoColors.activeBlue), // 텍스트 색상 파란색
                ),
              ),
            ],
          );
        },
      );
    }
  }



  // "내 쿠폰함" 모달
  void showMyCouponsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("내 쿠폰함"),
          content: myCoupons.isEmpty
              ? Text("저장된 쿠폰이 없습니다.")
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: myCoupons.map((coupon) => Text("- $coupon")).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 모달 닫기
              },
              child: Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  // 2160점 채웠을 때 보여주는 완료 모달
  void showCompletionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "🎉✨ 나무가 다 자랐어요!",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "선물로 쿠폰을 드릴게요!",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 15),
                  // 선택 가능한 텍스트 리스트
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCoupon = "플라스틱 방앗간 제품 교환권";
                          });
                        },
                        child: Container(
                          color: selectedCoupon == "플라스틱 방앗간 제품 교환권"
                              ? Colors.blue[100]
                              : Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                selectedCoupon == "플라스틱 방앗간 제품 교환권"
                                    ? CupertinoIcons.check_mark
                                    : CupertinoIcons.circle,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text("플라스틱 방앗간 제품 교환권"),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCoupon = "119REO 제품 교환권";
                          });
                        },
                        child: Container(
                          color: selectedCoupon == "119REO 제품 교환권"
                              ? Colors.blue[100]
                              : Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                selectedCoupon == "119REO 제품 교환권"
                                    ? CupertinoIcons.check_mark
                                    : CupertinoIcons.circle,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text("119REO 제품 교환권"),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCoupon = "seedkeeper 제품 교환권";
                          });
                        },
                        child: Container(
                          color: selectedCoupon == "seedkeeper 제품 교환권"
                              ? Colors.blue[100]
                              : Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                selectedCoupon == "seedkeeper 제품 교환권"
                                    ? CupertinoIcons.check_mark
                                    : CupertinoIcons.circle,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text("seedkeeper 제품 교환권"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("취소", style: TextStyle(color: Colors.blue)),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    setState(() {
                      myCoupons.add(selectedCoupon); // 쿠폰 추가
                    });
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeCouponPage(
                          couponCount: couponCount,
                          myCoupons: myCoupons,
                        ),
                      ),
                    );
                  },
                  child: Text("확인", style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }




// 포인트 사용 및 상태바 증가
  void usePoints(int cost) {
    if (points >= cost) {
      setState(() {
        points -= cost; // 포인트 차감
        progress += cost / maxPoints; // 사용된 포인트 비율만큼 게이지 증가
        if (progress > 1.0) progress = 1.0; // 상태바 최대값 제한

        // 특정 지점에서만 레벨업 모달 표시
        if (currentLevel < levelPoints.length &&
            progress >= levelPoints[currentLevel] / maxPoints) {
          showLevelUpModal();
        }
      });
    }
  }

  void resetTree() {
    setState(() {
      currentLevel = 0; // 레벨 초기화
      progress = 0; // 상태바 게이지 초기화
      treeState = "씨앗"; // 초기 상태
      message = "응애 나 씨앗"; // 초기 메시지
      treeImage = 'assets/seed.png'; // 초기 이미지
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const TopNavigationSection(
        title: '나무키우기',
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          // 내 쿠폰함과 현재 내 포인트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 내 쿠폰함 버튼
                GestureDetector(
                  onTap: () {
                    // 쿠폰 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeCouponPage(
                          couponCount: myCoupons.length,
                          myCoupons: myCoupons, // 쿠폰 리스트 전달
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 20, color: Colors.black),
                      SizedBox(width: 5),
                      Text(
                        "내 쿠폰함",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "$couponCount개",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                // 현재 내 포인트 텍스트
                Row(
                  children: [
                    Text(
                      "현재 내 포인트",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "$points p",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            '내 나무',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          // 상태바
          // 상태바
          Padding(
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
                        color: Colors.white,
                        border: Border.all(
                          color: Color(0xFF67EACA),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 채워진 부분
                    FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFF67EACA),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10), // 상태바와 숫자 간격
                // 상태바 아래 숫자
                Container(
                  height: 30, // 숫자 영역 높이
                  child: Stack(
                    children: [
                      // 숫자 0
                      Positioned(
                        left: 0, // 상태바의 시작점
                        child: Text("0", style: TextStyle(fontSize: 12)),
                      ),
                      // 숫자 80
                      Positioned(
                        left: MediaQuery.of(context).size.width * (80 / maxPoints)-6,
                        child: Text("80", style: TextStyle(fontSize: 12)),
                      ),
                      // 숫자 240
                      Positioned(
                        left: MediaQuery.of(context).size.width * (240 / maxPoints)-15,
                        child: Text("240", style: TextStyle(fontSize: 12)),
                      ),
                      // 숫자 720
                      Positioned(
                        left: MediaQuery.of(context).size.width * (720 / maxPoints)-30,
                        child: Text("720", style: TextStyle(fontSize: 12)),
                      ),
                      // 숫자 2160
                      Positioned(
                        right: 0, // 상태바의 끝점
                        child: Text("2,160", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // 텍스트 박스
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
            decoration: BoxDecoration(
              color: Color(0xFFFCF9EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: TextStyle(fontSize: 18),
            ),
          ),
          SizedBox(height: 40),
          // 나무 이미지
          Image.asset(
            treeImage, // 상태에 따라 이미지 변경
            height: 150,
          ),

          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: currentLevel == 4
                ? Center(
              child: ElevatedButton(
                onPressed: resetTree,
                child: Text("다시 키우기"),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionButton(
                  label: '물주기',
                  points: '10p',
                  imagePath: 'assets/water.png',
                  onPressed: () => handleAction('물주기', 10),
                  isDisabled: currentLevel == 4, // 꽃 상태에서는 비활성화
                ),
                ActionButton(
                  label: '햇빛쐬기',
                  points: '20p',
                  imagePath: 'assets/sun.png',
                  onPressed: () => handleAction('햇빛쐬기', 20),
                  isDisabled: currentLevel == 4, // 꽃 상태에서는 비활성화
                ),
                ActionButton(
                  label: '비료주기',
                  points: '50p',
                  imagePath: 'assets/fertilizer.png',
                  onPressed: () => handleAction('비료주기', 50),
                  isDisabled: currentLevel == 4, // 꽃 상태에서는 비활성화
                ),
              ],
            ),
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 2),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final String points;
  final String imagePath; // 이미지 경로 전달받기
  final VoidCallback onPressed;
  final bool isDisabled; // 버튼 비활성화 여부

  const ActionButton({
    Key? key,
    required this.label,
    required this.points,
    required this.imagePath, // 이미지 경로
    required this.onPressed,
    this.isDisabled = false, // 기본값: 활성화 상태
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed, // 비활성화 시 onTap 비활성화
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[300] : Colors.white, // 비활성화 시 회색 처리
          border: Border.all(color: Color(0xFF67EACA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이미지 추가
                  Image.asset(
                    imagePath,
                    height: 40,
                    width: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDisabled ? Colors.grey : Colors.black, // 비활성화 시 텍스트 색상 변경
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                width: 40,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFB0F4E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  points,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled ? Colors.grey : Colors.black, // 비활성화 시 텍스트 색상 변경
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}