import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/bottom_nav.dart';

class TreePage extends StatelessWidget {
  const TreePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(title: '내 나무'),
      body: Column(
        children: [
          const SizedBox(height: 20), // 상단 여백
          // 현재 내 포인트 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerRight, // 우측 상단에 배치
              child: const Text(
                '현재 내 포인트: 0p',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20), // 간격 추가
          const Text(
            '내 나무',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30), // 간격 추가
          // 상태바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              height: 20, // 상태바 전체 높이
              decoration: BoxDecoration(
                color: Colors.white, // 안 채워진 부분의 색상
                border: Border.all(
                  color: const Color(0xFF67EACA), // 테두리 색상
                  width: 2, // 테두리 두께
                ),
                borderRadius: BorderRadius.circular(10), // 테두리 라운드 처리
              ),
              child: Stack(
                children: [
                  // 채운 부분
                  FractionallySizedBox(
                    widthFactor: 0.5, // 상태바의 반 정도 채움 (50%)
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF67EACA), // 채운 부분의 색상
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(8), // 왼쪽 모서리 라운드 처리
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30), // 간격 추가
          // 텍스트 박스
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '응애 나 씨앗',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 80),
          // 씨앗 이미지
          Image.asset(
            'assets/seed.png', // assets 폴더에 씨앗 이미지를 추가해야 합니다.
            height: 150,
          ),
          // 하단 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionButton(
                  label: '물주기',
                  points: '10p',
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  onPressed: () {
                    print("물주기 클릭");
                  },
                ),
                ActionButton(
                  label: '햇빛쐬기',
                  points: '20p',
                  icon: Icons.wb_sunny,
                  iconColor: Colors.red,
                  onPressed: () {
                    print("햇빛쐬기 클릭");
                  },
                ),
                ActionButton(
                  label: '비료주기',
                  points: '50p',
                  icon: Icons.grass,
                  iconColor: Colors.brown,
                  onPressed: () {
                    print("비료주기 클릭");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationSection(currentIndex: 2),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final String points;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const ActionButton({
    Key? key,
    required this.label,
    required this.points,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100, // 고정된 너비
        height: 120, // 고정된 높이
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF67EACA)), // 테두리 색상
          borderRadius: BorderRadius.circular(10), // 테두리 라운드
        ),
        child: Stack(
          children: [
            // 카드 메인 콘텐츠
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
                children: [
                  Icon(
                    icon,
                    size: 30,
                    color: iconColor, // 아이콘 색상 설정
                  ),
                  const SizedBox(height: 8), // 아이콘과 텍스트 간격
                  Text(
                    label,
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 우측 상단 라운드 박스
            Positioned(
              top: 8, // 위쪽 간격
              right: 8, // 오른쪽 간격
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 내부 여백 추가
                alignment: Alignment.center, // 텍스트를 중앙에 배치
                decoration: BoxDecoration(
                  color: const Color(0xFFB0F4E6), // 배경 색상
                  borderRadius: BorderRadius.circular(10), // 라운드 처리
                ),
                child: Text(
                  points, // "10p" 텍스트
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
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