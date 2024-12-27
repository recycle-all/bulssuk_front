import 'package:flutter/material.dart';
import '../../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import


class RecyclingDetailPage extends StatelessWidget {
  final String category;

  const RecyclingDetailPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationSection(
        title: '분리수거 가이드 - $category', // 동적으로 제목 설정
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'This is the detail page for $category.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}