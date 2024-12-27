import 'package:flutter/material.dart'; // Flutter 기본 위젯 및 머티리얼 디자인

class FindIdCompletePage extends StatelessWidget {
  final String userId;

  const FindIdCompletePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('아이디 찾기 완료'),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(
          color: Colors.white, // 뒤로가기 버튼 색상 흰색
        ),
        titleTextStyle: TextStyle(
          color: Colors.white, // 제목 텍스트 색상 흰색
          fontSize: 18, // 제목 텍스트 크기
        ),
      ),
      body: Column(
        children: [
          // AppBar와 이미지 간격 조절
          SizedBox(height: 80), // 원하는 간격 높이로 설정
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 세로축 가운데 정렬
              crossAxisAlignment: CrossAxisAlignment.center, // 가로축 가운데 정렬
              children: [
                // 상단 이미지 공간
                Container(
                  margin: EdgeInsets.only(bottom: 20), // 이미지 아래 간격
                  child: Image.asset(
                    'assets/user_icon.png', // 로컬 이미지 경로
                    width: 200, // 이미지 너비
                    height: 200, // 이미지 높이
                    fit: BoxFit.cover, // 이미지 크기 조정
                  ),
                ),
                Text(
                  '아이디 찾기 완료',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  userId, // 가려진 아이디
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 이전 화면으로 돌아가기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0F4E6),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '로그인 페이지로 이동',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}