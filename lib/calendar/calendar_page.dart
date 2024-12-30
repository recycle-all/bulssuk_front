import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 초기화 필요
import 'package:http/http.dart' as http; // HTTP 요청을 위해 import
import 'dart:convert'; // JSON 변환을 위해 import
import 'memo_page.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import '../../widgets/bottom_nav.dart'; // 하단 네비게이션 가져오기
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // SecureStorage import

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now(); // 현재 날짜
  DateTime? _selectedDay; // 선택된 날짜
  Set<DateTime> _checkedDays = {}; // 출석 체크된 날짜들
  Set<DateTime> _alarmDays = {}; // 알람 있는 날짜들
  Map<DateTime, dynamic> _alarmDetails = {}; // 알람 날짜별 상세 데이터 저장
  final FlutterSecureStorage _storage = FlutterSecureStorage(); // SecureStorage 초기화
  String? userId; // SecureStorage에서 불러올 user_id

  // 알람 데이터 불러오기 함수
  Future<void> _loadAlarms() async {
    String? userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/alarm/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> alarms = jsonDecode(response.body);

        setState(() {
          _alarmDays = alarms.map((alarm) {
            DateTime alarmDate = DateTime.parse(alarm['created_at']).toLocal();
            _alarmDetails[alarmDate] = alarm; // 날짜별 알람 상세 정보 저장
            return alarmDate;
          }).toSet();
        });
      } else {
        print('Failed to load alarms: ${response.body}');
      }
    } catch (e) {
      print('Error loading alarms: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR'); // 한국어 로케일 초기화
    _selectedDay = DateTime.now(); // 오늘 날짜로 초기화
    _focusedDay = DateTime.now(); // 오늘 날짜로 초기화
    _loadUserId(); // SecureStorage에서 user_id 로드
    _loadAlarms(); // 캘린더 알람 데이터 로드 추가
  }

  // SecureStorage에서 user_id 불러오기
  Future<void> _loadUserId() async {
    userId = await _storage.read(key: 'user_id');
    if (userId == null) {
      print('Error: user_id not found in SecureStorage.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    print('Loaded user_id: $userId');
    _loadAttendance(); // user_id 로드 후 출석 기록 로드
  }

  // 출석 체크 히스토리 불러오기
  Future<void> _loadAttendance() async {
    if (userId == null) return; // userId가 없으면 요청 중지

    try {
      final response = await http.get(Uri.parse('http://localhost:8080/attendance/$userId')); // user_id 사용

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);

        setState(() {
          // 서버로부터 받은 날짜를 로컬 시간대로 변환
          _checkedDays = history
              .map((entry) => DateTime.parse(entry['attendance_date']).toLocal())
              .toSet();
        });
      } else {
        print('Failed to load attendance history: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출석 기록을 불러오지 못했습니다: ${response.body}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error loading attendance history: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버 오류로 출석 기록을 불러오지 못했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 출석 체크 저장
  Future<void> _saveAttendance() async {
    if (userId == null) return; // userId가 없으면 요청 중지

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}), // user_id 사용
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // 서버에서 받은 날짜를 로컬 시간대로 변환 후 추가
          final checkedDate = DateTime.parse(data['attendance_date']).toLocal();
          _checkedDays.add(checkedDate);

          // 선택된 날짜도 강제로 체크 상태로 갱신
          _selectedDay = checkedDate;
          print('Checked days updated: $_checkedDays');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출석 체크를 하셨습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? '출석 체크 실패.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error saving attendance: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버 오류로 출석 체크를 저장하지 못했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 알람 미리보기 모달 함수
  Future<void> _showAlarmPreview(DateTime selectedDate) async {
    if (_alarmDetails.containsKey(selectedDate)) {
      final alarm = _alarmDetails[selectedDate];
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('알람 미리보기'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('알림 이름: ${alarm['user_calendar_name']}'),
                Text('반복 주기: ${alarm['user_calendar_every']}'),
                Text('메모: ${alarm['user_calendar_memo']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoPage(
                        selectedDate: selectedDate,
                        alarmId: alarm['id'], // 알람 ID 전달
                      ),
                    ),
                  );
                },
                child: const Text('수정'),
              ),
            ],
          );
        },
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '캘린더',
      ),
      body: Column(
        children: [
          // 달력
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ko_KR', // 한국어 설정
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              if (_alarmDays.contains(selectedDay)) {
                await _showAlarmPreview(selectedDay);
              }
            },


            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey, // 오늘 날짜 색상
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.black, // 선택된 날짜 색상
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Color(0xFFB0F4E6), // 출석 체크된 날짜 색상
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, focusedDay) {
                if (_alarmDays.contains(day)) {
                  return Positioned(
                    bottom: 4,
                    child: Icon(
                      Icons.notifications,
                      size: 8,
                      color: Colors.red, // 알람 있는 날짜 표시 색상
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                if (_alarmDays.contains(day)) {
                  return Positioned(
                    bottom: 1,
                    child: Icon(
                      Icons.notifications,
                      size: 16,
                      color: Colors.red, // 알람이 있는 날짜의 아이콘 색상
                    ),
                  );
                }
                // 출석 체크된 날짜 우선 처리
                if (_checkedDays.any((checkedDay) =>
                day.year == checkedDay.year &&
                    day.month == checkedDay.month &&
                    day.day == checkedDay.day)) {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0F4E6), // 출석 체크된 날짜 색상 (하늘색)
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                // 기본 스타일
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                // 오늘 날짜 스타일
                return Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey, // 오늘 날짜 색상 (회색)
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                // 선택된 날짜 스타일 (출석 체크된 날짜와 겹치지 않도록 처리)
                if (_checkedDays.any((checkedDay) =>
                day.year == checkedDay.year &&
                    day.month == checkedDay.month &&
                    day.day == checkedDay.day)) {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0F4E6), // 출석 체크된 날짜 색상 유지
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black, // 선택된 날짜 색상 (검은색)
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // 월/주 선택 버튼 숨김
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 20),

          // 출석 체크 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 30),
                const SizedBox(width: 10),
                const Text('출석 체크', style: TextStyle(fontSize: 18)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    if (_selectedDay != null) {
                      if (!isSameDay(_selectedDay, DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('오늘만 출석 체크가 가능합니다.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // 함수 종료
                      }

                      if (_checkedDays.any((checkedDay) =>
                      _selectedDay!.year == checkedDay.year &&
                          _selectedDay!.month == checkedDay.month &&
                          _selectedDay!.day == checkedDay.day)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이미 출석 체크를 하셨습니다.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // 함수 종료
                      }

                      await _saveAttendance(); // 출석 체크 저장 호출
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedDay != null &&
                          _checkedDays.any((checkedDay) =>
                          _selectedDay!.year == checkedDay.year &&
                              _selectedDay!.month == checkedDay.month &&
                              _selectedDay!.day == checkedDay.day)
                          ? const Color(0xFFB0F4E6)
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedDay != null &&
                            _checkedDays.any((checkedDay) =>
                            _selectedDay!.year == checkedDay.year &&
                                _selectedDay!.month == checkedDay.month &&
                                _selectedDay!.day == checkedDay.day)
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.5),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        _selectedDay != null &&
                            _checkedDays.any((checkedDay) =>
                            _selectedDay!.year == checkedDay.year &&
                                _selectedDay!.month == checkedDay.month &&
                                _selectedDay!.day == checkedDay.day)
                            ? Icons.check
                            : null,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationSection(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          final DateTime memoDate = _selectedDay ?? DateTime.now();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoPage(selectedDate: memoDate),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
