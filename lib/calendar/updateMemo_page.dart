import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/top_nav.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class UpdateMemoPage extends StatefulWidget {
  final DateTime selectedDate;
  final dynamic memo;

  const UpdateMemoPage({
    Key? key,
    required this.selectedDate,
    required this.memo,
  }) : super(key: key);

  @override
  State<UpdateMemoPage> createState() => _UpdateMemoPageState();
}

class _UpdateMemoPageState extends State<UpdateMemoPage> {
  late TextEditingController _nameController;
  late String _alarmFrequency;
  late TextEditingController _memoController;
  late bool _alarmEnabled; // 알림 활성화 상태
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  TimeOfDay? _selectedTime; // 선택된 시간
  String? _userId;

  @override
  void initState() {
    super.initState();


    if (widget.memo['user_calendar_no'] == null) {
      print('Error: user_calendar_no is null in UpdateMemoPage');
    }

    // 등록 시의 알림 상태와 데이터를 초기화
    _nameController = TextEditingController(text: widget.memo['user_calendar_name']);
    _alarmFrequency = widget.memo['user_calendar_every'];
    _memoController = TextEditingController(text: widget.memo['user_calendar_memo']);
    _alarmEnabled = widget.memo['user_calendar_list'] ?? false;

    // 기존 시간 초기화
    if (widget.memo['user_calendar_time'] != null) {
      final timeParts = widget.memo['user_calendar_time'].split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    _loadUserId();
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

  // 사용자 ID 로드
  Future<void> _loadUserId() async {
    _userId = await _storage.read(key: 'user_id');
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
      );
      Navigator.pop(context);
    }
  }


  // 메모 수정 함수
  Future<void> _updateMemo() async {
    final userId = await _storage.read(key: 'user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    // 날짜를 ISO8601에서 YYYY-MM-DD 형식으로 변환
    String formattedDate = widget.selectedDate.toIso8601String().split('T')[0];

    // 시간을 HH:MM 형식으로 변환
    String? formattedTime = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final alarmData = {
      'user_id': userId,
      'user_calendar_no': widget.memo['user_calendar_no'], // 고유 식별자
      'user_calendar_name': _nameController.text,
      'user_calendar_every': _alarmFrequency,
      'user_calendar_memo': _memoController.text,
      'user_calendar_date': formattedDate, // 날짜 전달
      'user_calendar_time': formattedTime,
      'user_calendar_list': _alarmEnabled, // 토글 상태 전달
    };


    try {
      final response = await http.put(
        Uri.parse('$URL/update_alarm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alarmData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 성공적으로 수정되었습니다.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알람 수정 실패: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error updating memo: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 오류가 발생했습니다.')),
      );
    }
  }


  // 메모 삭제 함수
  Future<void> _deleteMemo() async {
    if (widget.memo['user_calendar_no'] == null) {
      print('Error: user_calendar_no is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모 식별자가 없습니다. 삭제를 취소합니다.')),
      );
      return;
    }

    final userId = await _storage.read(key: 'user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final deleteData = {
      'user_id': userId,
      'user_calendar_no': widget.memo['user_calendar_no'], // 고유 메모 번호 추가
    };

    try {
      final response = await http.put(
        Uri.parse('$URL/deactivate_alarm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(deleteData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 삭제되었습니다.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알람 삭제 실패: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting memo: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 화면 터치 시 키보드 숨기기
      },
      child: Scaffold(
        appBar: const TopNavigationSection(
          title: '알람 수정',
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget.selectedDate.day}일',
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
                              _alarmEnabled = value;
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
                  controller: _nameController,
                  decoration: _buildInputDecoration('알림 이름을 입력하세요.'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('알림 시간'),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3D3D3),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                              : '11:00',
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton('삭제', _deleteMemo),
                    _buildActionButton('수정', _updateMemo),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }

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

  Widget _buildActionButton(String label, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0), // 버튼 내부 패딩 (높이 조정)
        fixedSize: const Size(150, 50), // 버튼 크기 고정
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }
}
