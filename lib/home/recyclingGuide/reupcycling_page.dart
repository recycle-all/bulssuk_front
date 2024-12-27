import 'package:flutter/material.dart';
import '../../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import


class ReupcyclingPage extends StatelessWidget {
  const ReupcyclingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationSection(
        title: '업사이클링 기업', // 동적으로 제목 설정
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 이미지와 제목 (베이지 카드 안에 포함)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF9EC),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/plastic_bag.png', // 테스트용 이미지
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width, // 화면 가로 꽉 채우기
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '플라스틱 방앗간',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '플라스틱 방앗간은 플라스틱의 일방으로 재활용되지 않아서\n'
                          '버려지는 쓰레기를 새롭게 활용하는 공간입니다.\n\n'
                          '매일 쓰레기장에서 소각, 매립되는\n'
                          '플라스틱 쓰레기를 재활용하여 새로운 자원으로 탈바꿈합니다.\n\n'
                          '페트병, 플라스틱 뚜껑, 비닐 등 다양한 플라스틱을\n'
                          '활용하여 새로운 가능성을 제시합니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. 제품 리스트 (사진-텍스트 디자인)
              const Text(
                '플라스틱 방앗간의 대표 제품',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildProductItem('비누 받침', 'assets/soap_holder.jpg'),
              _buildProductItem('튜브 짜개', 'assets/tube_squeezer.jpg'),
            ],
          ),
        ),
      ),

    );
  }

  // 제품 아이템 위젯 (사진-텍스트 디자인)
  Widget _buildProductItem(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
