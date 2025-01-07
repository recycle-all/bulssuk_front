import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class MemoPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? alarmId; // 기존 알람 ID (수정 시 사용)
  final VoidCallback? onSave; // 저장 후 호출할 콜백 함수

  const MemoPage({Key? key, required this.selectedDate, this.alarmId, this.onSave}) : super(key: key);

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  String _alarmName = '';
  String _alarmFrequency = '매일'; // 초기 선택값
  bool _alarmEnabled = true; // 알림 활성화 상태
  TimeOfDay? _selectedTime; // 선택된 시간
  TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.alarmId != null) {
      _loadExistingAlarm(); // 알람 수정 시 기존 데이터 로드
    }
  }

  // 시간 선택 함수
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // 기존 알람 데이터를 로드
  Future<void> _loadExistingAlarm() async {
    try {
      final response = await http.get(
        Uri.parse('$URL/alarm/${widget.alarmId}'),
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

    // 시간을 HH:mm 형식으로 변환
    String formattedTime = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '00:00'; // 기본 시간 (선택하지 않으면 00:00)

    final alarmData = {
      'user_id': userId,
      'user_calendar_name': _alarmName,
      'user_calendar_every': _alarmFrequency,
      'user_calendar_memo': _memoController.text,
      'user_calendar_date': formattedDate, // 날짜 추가
      'user_calendar_time': formattedTime,
      'user_calendar_list': _alarmEnabled, // 알림 활성화 상태 전송
    };

    try {
      final response = await http.post(
        Uri.parse('$URL/alarm'), // 백엔드의 알람 등록 API 확인
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alarmData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 저장되었습니다.')),
        );

        // 저장 후 onSave 콜백 호출
        widget.onSave?.call();

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
    final isButtonEnabled = _alarmName.isNotEmpty; // 버튼 활성화 상태
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 화면 터치 시 키보드 숨기기
        },

    child:Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: Colors.white, // AppBar 배경색 변경 (필요에 따라 수정)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // 오른쪽 여백 추가
            child: SizedBox(
              width: 80, // 원하는 너비 설정
              height: 50, // 원하는 높이 설정
              child: TextButton(
                onPressed: isButtonEnabled ? _saveMemo : null, // 비활성화 상태 처리
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // 모서리 반경 설정
                  ),
                ),
                child: Text(
                  '추가',
                  style: TextStyle(
                    color: isButtonEnabled ? Colors.black : const Color(0xFFCCCCCC), // 활성화 상태에 따라 색상 변경
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // 스크롤 가능하도록 변경
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 좌우 정렬
                children: [
                  Text(
                    '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget.selectedDate.day}일 ${_getWeekday(widget.selectedDate.weekday)}요일',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text(
                        '알림 설정',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
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
                    ],
                  ),
                ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 좌우 정렬
                children: [
                  _buildLabel('알림 시간'),
                  GestureDetector(
                    onTap: () => _selectTime(context), // 클릭 시 시간 선택 창 열기
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D3D3), // 회색 배경
                        borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                      ),
                      child: Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : '11:00', // 기본값으로 "11:00" 표시
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.black, // 텍스트 색상
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
            ],
          ),
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 14.0), // 버튼 내부 패딩 (높이 조정)
              minimumSize: const Size(80, 50), // 최소 크기 설정 (너비, 높이)
            ),
            onPressed: () {
              setState(() {
                _alarmFrequency = label;
              });
            },
            child: Text(label,
              style: const TextStyle(
                color: Colors.black, // 모든 버튼의 텍스트 색상
              ),),
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
