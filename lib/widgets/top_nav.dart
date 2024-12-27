import 'package:flutter/material.dart';

class TopNavigationSection extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor; // 색상 속성 추가 (null 허용)

  const TopNavigationSection({
    Key? key,
    required this.title,
    this.backgroundColor, // 선택적으로 색상을 설정
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? const Color(0xFFFFFFFF), // 기본 흰색
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black, // 텍스트 색상 검은색
          fontSize: 20, // 텍스트 크기
          fontWeight: FontWeight.bold, // 텍스트 굵기
        ),
      ),
      centerTitle: true, // 제목 중앙 정렬
      elevation: 0, // 그림자 제거
      iconTheme: const IconThemeData(
        color: Colors.black, // 아이콘 색상 검은색
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40.0); // AppBar 높이
}