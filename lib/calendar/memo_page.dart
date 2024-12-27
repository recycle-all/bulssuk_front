import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

class MemoPage extends StatefulWidget {
  final DateTime selectedDate;

  const MemoPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  String _alarmName = '';
  String _alarmFrequency = '매일'; // 초기 선택값
  bool _alarmEnabled = true;
  TextEditingController _memoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '알림 설정',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget.selectedDate.day}일 ${_getWeekday(widget.selectedDate.weekday)}요일',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '알림 이름',
              style: TextStyle(
                fontWeight: FontWeight.bold, // 글자 굵게
                fontSize: 16.0, // 글자 크기
              ),
            ),
            SizedBox(height: 12.0), // 텍스트와 텍스트 필드 사이 간격
            TextField(
              decoration: InputDecoration(
                hintText: '알림 이름을 입력하세요.',
                hintStyle: TextStyle(
                  color: Color(0xFFCCCCCC), // 힌트 텍스트 색상
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // 둥근 테두리
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 포커스된 상태의 테두리 색상
                    width: 2.0, // 테두리 두께
                  ),
                ),
                border: OutlineInputBorder(), // 기본 테두리 스타일
              ),
              onChanged: (value) {
                setState(() {
                  _alarmName = value;
                });
              },
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '알림 설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // 글자 굵게
                    fontSize: 16.0, // 글자 크기
                  ),
                ),
                CupertinoSwitch(
                  value: _alarmEnabled,
                  activeTrackColor: CupertinoColors.activeGreen, // 활성 상태 트랙 색상
                  thumbColor: CupertinoColors.white, // 스위치 동그라미(Thumb)의 색상
                  trackColor: CupertinoColors.inactiveGray, // 비활성 상태 트랙 색상
                  onChanged: (value) {
                    setState(() {
                      _alarmEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // 스위치와 설정 요소 간 간격 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0), // 좌우 여백
                    child: _buildFrequencyButton('매일'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0), // 좌우 여백
                    child: _buildFrequencyButton('매주'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0), // 좌우 여백
                    child: _buildFrequencyButton('매월'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              '알림 메모',
              style: TextStyle(
                fontWeight: FontWeight.bold, // 글자 굵게
                fontSize: 16.0, // 글자 크기
              ),
            ),
            SizedBox(height: 12.0), // 텍스트와 텍스트 필드 사이 간격
            TextField(
              controller: _memoController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '메모를 입력하세요.',
                hintStyle: TextStyle(
                  color: Color(0xFFCCCCCC), // 힌트 텍스트 색상
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // 둥근 테두리
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFCCCCCC), // 포커스된 상태의 테두리 색상
                    width: 2.0, // 테두리 두께
                  ),
                ),
                border: OutlineInputBorder(), // 기본 테두리 스타일
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 버튼 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                      side: const BorderSide(color: Color(0xFFCCCCCC)), // 테두리 색상
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0), // 버튼 내부 패딩
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 버튼 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                      side: const BorderSide(color: Color(0xFFCCCCCC)), // 테두리 색상
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0), // 버튼 내부 패딩
                  ),
                  onPressed: () {
                    _saveMemo();
                  },
                  child: const Text('저장', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 알람 설정
  Widget _buildFrequencyButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _alarmFrequency == label ? Color(0xFFB0F4E6) : Colors.white,
        foregroundColor: _alarmFrequency == label ? Colors.black : Colors.black,
        // side: const BorderSide(color: Colors.black), // 테두리 색상
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // 라디우스 설정
        ),
      ),
      onPressed: () {
        setState(() {
          _alarmFrequency = label;
        });
      },
      child: Text(label),
    );
  }

  void _saveMemo() {
    // 메모 저장 로직
    print('날짜: ${widget.selectedDate}');
    print('알림 이름: $_alarmName');
    print('설정: $_alarmEnabled');
    print('반복 주기: $_alarmFrequency');
    print('메모: ${_memoController.text}');
  }

  String _getWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1]; // weekday는 1(월요일)부터 시작
  }
}