import 'package:flutter/material.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class CouponPage extends StatelessWidget {
  const CouponPage({Key? key}) : super(key: key); // const 생성자 추가

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TopNavigationSection(
                title: '내 쿠폰함',
              ),
              const TabBar(
                indicatorColor: Color(0xFF67EACA),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: '사용가능 쿠폰'),
                  Tab(text: '지난 쿠폰'),
                ],
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AvailableCoupons(), // 사용가능 쿠폰 화면
            ExpiredCoupons(), // 지난 쿠폰 화면
          ],
        ),
      ),
    );
  }
}

/// 사용 가능한 쿠폰 리스트
class AvailableCoupons extends StatelessWidget {
  const AvailableCoupons({Key? key}) : super(key: key); // const 생성자 추가

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> coupons = [
      {"title": "플라스틱 방앗간 제품 교환권", "expiryDate": "2026.12.01"},
      {"title": "119REO 제품 교환권", "expiryDate": "2026.12.01"},
      {"title": "seedkeeper 제품 교환권", "expiryDate": "2026.12.01"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return Card(
          elevation: 2, // 카드 그림자 추가
          margin: const EdgeInsets.only(bottom: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/recycle_sample_image.png', // 이미지 경로
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, size: 48, color: Colors.grey); // 기본 이미지 표시
                  },
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '${coupon['expiryDate']} 까지',
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 지난 쿠폰 리스트
class ExpiredCoupons extends StatelessWidget {
  const ExpiredCoupons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 지난 쿠폰 데이터 예시
    final List<Map<String, String>> expiredCoupons = [
      {"title": "플라스틱 방앗간 제품 교환권", "expiryDate": "2023.12.01"},
      {"title": "119REO 제품 교환권", "expiryDate": "2023.11.15"},
      {"title": "seedkeeper 제품 교환권", "expiryDate": "2023.10.10"},
    ];

    // 쿠폰 리스트가 없는 경우
    if (expiredCoupons.isEmpty) {
      return const Center(
        child: Text(
          '지난 쿠폰이 없습니다.',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      );
    }

    // 쿠폰 리스트가 있는 경우
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: expiredCoupons.length,
      itemBuilder: (context, index) {
        final coupon = expiredCoupons[index];
        return Card(
          color: Colors.grey.shade200, // 비활성화된 느낌의 배경색
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 쿠폰 이미지
                Image.asset(
                  'assets/images/recycle_sample_image.png', // 이미지 경로 (로컬 파일 추가 필요)
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  color: Colors.grey, // 이미지 비활성화 효과
                  colorBlendMode: BlendMode.saturation, // 색상 블렌딩
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, size: 48, color: Colors.grey); // 기본 이미지
                  },
                ),
                const SizedBox(width: 16.0),
                // 쿠폰 제목과 만료일
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey, // 비활성화 텍스트 색상
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '${coupon['expiryDate']} 까지',
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // 사용불가 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100, // 비활성화 느낌의 배경색
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text(
                    '사용불가',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.red, // 텍스트 색상
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}