import 'package:flutter/material.dart';
import 'updateMemo_page.dart';

class MemoModalPage extends StatelessWidget {
  final DateTime selectedDate;
  final Map<String, dynamic> recentMemo;
  final VoidCallback onViewAll;

  const MemoModalPage({
    Key? key,
    required this.selectedDate,
    required this.recentMemo,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('메모 전체보기', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '알림 이름: ${recentMemo['user_calendar_name']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '알림 설정: ${recentMemo['user_calendar_every']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '알림 메모: ${recentMemo['user_calendar_memo']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
