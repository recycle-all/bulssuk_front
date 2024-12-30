import 'package:flutter/material.dart';

class PointPage extends StatelessWidget {
  final int totalPoints; // 보유 포인트
  final List<Map<String, dynamic>> pointHistory; // 포인트 내역 데이터
  final TextStyle titleStyle; // 타이틀 텍스트 스타일
  final TextStyle pointsStyle; // 포인트 숫자 텍스트 스타일
  final TextStyle itemTitleStyle; // 리스트 항목 제목 텍스트 스타일
  final TextStyle itemDateStyle; // 리스트 항목 날짜 텍스트 스타일
  final TextStyle itemPointsStyle; // 리스트 항목 포인트 텍스트 스타일
  final Color cardBackgroundColor; // 카드 배경색

  const PointPage({
    Key? key,
    this.totalPoints = 0, // 기본값: 0 포인트
    this.pointHistory = const [], // 기본값: 빈 내역
    this.titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    this.pointsStyle = const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
    this.itemTitleStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    this.itemDateStyle = const TextStyle(fontSize: 12, color: Colors.grey),
    this.itemPointsStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
    this.cardBackgroundColor = Colors.white, // 기본 배경색
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 내역'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: Column(
        children: [
          // 보유 포인트 카드
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('보유 포인트', style: titleStyle),
                  const SizedBox(height: 8.0),
                  Text('$totalPoints p', style: pointsStyle),
                ],
              ),
            ),
          ),

          // 포인트 내역 리스트
          Expanded(
            child: ListView.builder(
              itemCount: pointHistory.length,
              itemBuilder: (context, index) {
                final item = pointHistory[index];
                return Card(
                  color: cardBackgroundColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 왼쪽: 제목과 날짜
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'], style: itemTitleStyle),
                            const SizedBox(height: 4.0),
                            Text(item['date'], style: itemDateStyle),
                          ],
                        ),
                        // 오른쪽: 포인트
                        Text(
                          '+${item['points']}p',
                          style: itemPointsStyle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';

class PointPage extends StatelessWidget {
  final int totalPoints; // 보유 포인트
  final List<Map<String, dynamic>> pointHistory; // 포인트 내역 데이터
  final TextStyle titleStyle; // 타이틀 텍스트 스타일
  final TextStyle pointsStyle; // 포인트 숫자 텍스트 스타일
  final TextStyle itemTitleStyle; // 리스트 항목 제목 텍스트 스타일
  final TextStyle itemDateStyle; // 리스트 항목 날짜 텍스트 스타일
  final TextStyle itemPointsStyle; // 리스트 항목 포인트 텍스트 스타일
  final Color cardBackgroundColor; // 카드 배경색

  const PointPage({
    Key? key,
    this.totalPoints = 0, // 기본값: 0 포인트
    this.pointHistory = const [], // 기본값: 빈 내역
    this.titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    this.pointsStyle = const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
    this.itemTitleStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    this.itemDateStyle = const TextStyle(fontSize: 12, color: Colors.grey),
    this.itemPointsStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
    this.cardBackgroundColor = Colors.white, // 기본 배경색
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 내역'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: Column(
        children: [
          // 보유 포인트 카드
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('보유 포인트', style: titleStyle),
                  const SizedBox(height: 8.0),
                  Text('$totalPoints p', style: pointsStyle),
                ],
              ),
            ),
          ),

          // 포인트 내역 리스트
          Expanded(
            child: ListView.builder(
              itemCount: pointHistory.length,
              itemBuilder: (context, index) {
                final item = pointHistory[index];
                return Card(
                  color: cardBackgroundColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 왼쪽: 제목과 날짜
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'], style: itemTitleStyle),
                            const SizedBox(height: 4.0),
                            Text(item['date'], style: itemDateStyle),
                          ],
                        ),
                        // 오른쪽: 포인트
                        Text(
                          '+${item['points']}p',
                          style: itemPointsStyle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}