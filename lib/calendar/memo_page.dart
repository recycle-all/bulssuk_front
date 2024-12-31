import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MemoPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? alarmId; // 기존 알람 ID (수정 시 사용)

  const MemoPage({Key? key, required this.selectedDate, this.alarmId}) : super(key: key);

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  String _alarmName = '';
  String _alarmFrequency = '매일'; // 초기 선택값
  bool _alarmEnabled = true; // 알림 활성화 상태
  TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.alarmId != null) {
      _loadExistingAlarm(); // 알람 수정 시 기존 데이터 로드
    }
  }

  // 기존 알람 데이터를 로드
  Future<void> _loadExistingAlarm() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8001/alarm/${widget.alarmId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _alarmName = data['user_calendar_name'];
          _alarmFrequency = data['user_calendar_every'];
          _memoController.text = data['user_calendar_memo'];
          _alarmEnabled = data['user_calendar_list']; // 기존 알림 상태 로드
        });
      } else {
        print('Failed to load alarm: ${response.body}');
      }
    } catch (e) {
      print('Error loading alarm: $e');
    }
  }

  // 알람 저장 함수
  Future<void> _saveMemo() async {
    final storage = FlutterSecureStorage();
    String? userId = await storage.read(key: 'user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 날짜를 YYYY-MM-DD 형식으로 변환
    String formattedDate = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

    final alarmData = {
      'user_id': userId,
      'user_calendar_name': _alarmName,
      'user_calendar_every': _alarmFrequency,
      'user_calendar_memo': _memoController.text,
      'user_calendar_date': formattedDate, // 날짜 추가
      'user_calendar_list': _alarmEnabled, // 알림 활성화 상태 전송
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8001/alarm'), // 백엔드의 알람 등록 API 확인
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alarmData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 저장되었습니다.')),
        );
        Navigator.pop(context, true); // 저장 후 이전 화면으로 돌아가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알람 저장 실패: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error saving alarm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 오류로 알람을 저장하지 못했습니다.')),
      );
    }
  }


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
            _buildLabel('알림 이름'),
            const SizedBox(height: 12),
            TextField(
              decoration: _buildInputDecoration('알림 이름을 입력하세요.'),
              onChanged: (value) {
                setState(() {
                  _alarmName = value;
                });
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('알림 설정'),
            CupertinoSwitch(
              value: _alarmEnabled,
              activeTrackColor: CupertinoColors.activeGreen,
              thumbColor: CupertinoColors.white,
              trackColor: CupertinoColors.inactiveGray,
              onChanged: (value) {
                setState(() {
                  _alarmEnabled = value; // 토글 상태 업데이트
                });
              },
            ),
            const SizedBox(height: 20),
            _buildFrequencyOptions(),
            const SizedBox(height: 20),
            _buildLabel('알림 메모'),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLines: 5,
              decoration: _buildInputDecoration('메모를 입력하세요.'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('취소', () => Navigator.pop(context)),
                _buildActionButton('저장', _saveMemo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UI Helper: 라벨 빌더
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }

  // UI Helper: InputDecoration 빌더
  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 2.0),
      ),
      border: OutlineInputBorder(),
    );
  }

  // UI Helper: 반복 주기 옵션 버튼 빌더
  Widget _buildFrequencyOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['매일', '매주', '매월']
          .map((label) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _alarmFrequency == label
                  ? const Color(0xFFB0F4E6)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              setState(() {
                _alarmFrequency = label;
              });
            },
            child: Text(label),
          ),
        ),
      ))
          .toList(),
    );
  }

  // UI Helper: 액션 버튼 빌더
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  String _getWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }
}
