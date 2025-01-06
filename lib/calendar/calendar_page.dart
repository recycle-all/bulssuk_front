import 'package:bulssuk/calendar/savedMemo_page.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 초기화 필요
import 'package:http/http.dart' as http; // HTTP 요청을 위해 import
import 'dart:convert'; // JSON 변환을 위해 import
import 'memo_page.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import '../../widgets/bottom_nav.dart'; // 하단 네비게이션 가져오기
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // SecureStorage import
import 'memoModal_page.dart'; // 새로 만든 모달 페이지 import
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Set<DateTime> memoDates = {}; // 메모가 있는 날짜
  Map<DateTime, dynamic> memoDetails = {}; // 날짜별 메모 상세 정보
  int? userNo; // userNo 변수를 선언
  String? _monthImage; // 현재 월의 이미지
  final Map<int, String> _monthImages = {}; // 월별 이미지 캐시
  List<Map<String, dynamic>> _events = []; // 서버에서 가져온 이벤트 데이터 저장
  final URL = dotenv.env['URL'];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR'); // 한국어 로케일 초기화
    _selectedDay = DateTime.now(); // 오늘 날짜로 초기화
    _focusedDay = DateTime.now(); // 오늘 날짜로 초기화
    _fetchMonthImage(_focusedDay.month); // 초기 월의 이미지 로드
    _loadUserId().then((_) {
      _loadUserNo().then((_) {
        _loadAlarms(); // 캘린더 알람 데이터 로드 추가
        _loadMonthlyAttendance(); // 이번 달 출석 데이터 로드
        _loadEvents(); // 이벤트 데이터 로드
        print('Loaded Events: $_events');
      });
    });
  }

  // 날짜에서 시간 정보를 제거하는 함수
  DateTime _stripTime(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  // 알람 데이터 로드
  Future<void> _loadAlarms() async {
    String? userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$URL/alarm/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> alarms = jsonDecode(response.body);

        setState(() {
          memoDetails.clear(); // 기존 데이터 초기화
          memoDates.clear();

          for (var alarm in alarms) {
            DateTime alarmDate =
            _stripTime(DateTime.parse(alarm['user_calendar_date']).toLocal());

            if (!memoDetails.containsKey(alarmDate)) {
              memoDetails[alarmDate] = [];
            }
            memoDetails[alarmDate]!.add(alarm);
            memoDates.add(alarmDate); // 날짜 저장
          }
        });
      } else {
        print('Failed to load alarms: ${response.body}');
      }
    } catch (e) {
      print('Error loading alarms: $e');
    }
  }

  Future<void> _loadUserNo() async {
    final userNoString = await _storage.read(key: 'user_no'); // 문자열로 읽기

    if (userNoString == null) {
      print('Error: user_no not found in SecureStorage.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      userNo = int.parse(userNoString); // 문자열을 정수로 변환
      print('Loaded user_no: $userNo');
    } catch (e) {
      print('Error parsing user_no: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// 특정 날짜 클릭 시 모달 표시
  Future<void> _showMemoModal(DateTime selectedDate) async {
    DateTime strippedDate = _stripTime(selectedDate);

    if (memoDetails.containsKey(strippedDate)) {
      final memoList = memoDetails[strippedDate];
      final recentMemo = memoList?.first; // 첫 번째 메모를 가져옴

      // recentMemo 데이터 확인
      print('Recent Memo being passed to MemoModalPage: $recentMemo');

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (context) {
          return MemoModalPage(
            selectedDate: strippedDate,
            recentMemo: recentMemo,
            onViewAll: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SavedMemoPage(
                          selectedDate: strippedDate,
                          initialMemoList: memoDetails[strippedDate] ?? [],
                        ),
                  ),
                ),
          );
        },
      );
    } else {
      print('No memos found for selected date: $strippedDate');
    }
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
      final response = await http.get(
          Uri.parse('$URL/attendance/$userId')); // user_id 사용

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);

        setState(() {
          // 서버로부터 받은 날짜를 로컬 시간대로 변환
          _checkedDays = history
              .map((entry) =>
              DateTime.parse(entry['attendance_date']).toLocal())
              .toSet();
        });
      } else {
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
  // Future<void> _saveAttendance() async {
  //   if (userId == null) return; // userId가 없으면 요청 중지
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$URL/attendance'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'user_id': userId}), // user_id 사용
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //
  //       setState(() {
  //         // 서버에서 받은 날짜를 로컬 시간대로 변환 후 추가
  //         final checkedDate = DateTime.parse(data['attendance_date']).toLocal();
  //         _checkedDays.add(checkedDate);
  //
  //         // 선택된 날짜도 강제로 체크 상태로 갱신
  //         _selectedDay = checkedDate;
  //         print('Checked days updated: $_checkedDays');
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('출석 체크를 하셨습니다.'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     } else {
  //       final errorMessage = jsonDecode(response.body)['message'];
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(errorMessage ?? '출석 체크 실패.'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (error) {
  //     print('Error saving attendance: $error');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('서버 오류로 출석 체크를 저장하지 못했습니다.'),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

// 출석체크 저장과 포인트
  Future<void> _saveAttendance() async {
    if (userNo == null) return; // userNo가 없으면 요청 중지

    try {
      final response = await http.post(
        Uri.parse('$URL/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_no': userNo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // 서버에서 반환된 출석 날짜 추가
          final checkedDate = DateTime.parse(
              data['attendance']['attendance_date']).toLocal();
          _checkedDays.add(checkedDate);

          // 선택된 날짜 업데이트
          _selectedDay = checkedDate;
          print('Checked days updated: $_checkedDays');
        });

        // 포인트 정보 가져오기
        final pointAmount = data['point']['point_amount'];
        final pointTotal = data['point']['point_total'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출석 체크 완료! 포인트 +$pointAmount (총 $pointTotal)'),
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
                      builder: (_) =>
                          MemoPage(
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


  // 월별 이미지 데이터 가져오기
  Future<void> _fetchMonthImage(int month) async {
    try {
      final response = await http.get(
        Uri.parse('$URL/month_image/$month'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _monthImages[month] = 'assets/${data.first['custom_img']}';
            _monthImage = _monthImages[month];
          });
          print(_monthImage);
        } else {
          setState(() {
            _monthImage = null; // 이미지가 없을 경우
          });
        }
      } else {
        print('Failed to fetch month image: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching month image: $error');
    }
  }

// 출석 체크 히스토리 불러오기
  Future<void> _loadMonthlyAttendance() async {
    if (userNo == null) return; // userNo가 없으면 요청 중지

    try {
      final year = _focusedDay.year.toString(); // 연도 -> 문자열 변환
      final month = _focusedDay.month.toString(); // 월 -> 문자열 변환
      print(userNo);
      print(year);
      print(month);
      print(
          'Request URL: $URL/attendance/$userNo/$year/$month');
      print('Year: $year, Month: $month (Type: ${year.runtimeType}, ${month
          .runtimeType})');

      final response = await http.get(
        Uri.parse('$URL/attendance/$userNo/$year/$month'),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        final List<dynamic> attendanceList = jsonDecode(response.body);

        setState(() {
          _checkedDays.clear(); // 이전 데이터를 초기화
          _checkedDays.addAll(attendanceList.map((item) {
            return DateTime.parse(item['attendance_date']).toLocal();
          }));
        });

        print('Loaded monthly attendance: $_checkedDays');
      } else {
        print('Failed to load monthly attendance: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이번 달 출석 기록을 불러오지 못했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error loading monthly attendance: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버 오류로 출석 기록을 불러오지 못했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 이벤트 데이터 로드
  Future<void> _loadEvents() async {
    try {
      final year = _focusedDay.year.toString();
      final month = _focusedDay.month.toString().padLeft(2, '0');
      final response = await http.get(
        Uri.parse('$URL/get_event/$year/$month'),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _events = data.map((event) {
            print('Mapping Event: $event'); // 각 이벤트 매핑 확인
            return {
              'date': DateTime.parse(event['calendar_date']),
              'name': event['calendar_name'],
              'content': event['calendar_content'],
              'img': event['calendar_img'] != null
                  ? 'assets/${event['calendar_img']}'
                  : null,
            };
          }).toList();

          print('Updated Events: $_events'); // 업데이트된 _events 출력
        });
      } else {
        print('Failed to fetch events: ${response.statusCode}');
      }
    } catch (error) {
      print('Error loading events: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvent = _events.firstWhere(
          (e) =>
      e['date'].year == _selectedDay?.year &&
          e['date'].month == _selectedDay?.month &&
          e['date'].day == _selectedDay?.day,
      orElse: () => {}, // 기본값으로 빈 맵 반환
    );

    return Scaffold(
      appBar: const TopNavigationSection(
        title: '캘린더',
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // 화면 어디든 감지 가능
        onTap: () {
          // 화면 아무 곳이나 클릭 시 이벤트 창 닫기
          setState(() {
            _selectedDay = null; // 선택된 날짜 초기화
          });
        },
        child: Stack(
          children: [
            Column(
              children: [
                // 달력 영역
                TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  locale: 'ko_KR',
                  onDaySelected: (selectedDay, focusedDay) async {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    DateTime strippedDate = _stripTime(selectedDay); // 시간 제거

                    // 메모가 있는 날짜인 경우 모달 표시
                    if (memoDetails.containsKey(strippedDate)) {
                      await _showMemoModal(strippedDate);
                    }
                  },
                  onPageChanged: (focusedDay) async {
                    setState(() {
                      _focusedDay = focusedDay;
                      _selectedDay = null;
                    });
                    await _loadMonthlyAttendance();
                    await _fetchMonthImage(focusedDay.month);
                    await _loadEvents();
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Color(0xFFB0F4E6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, day) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.year}년 ${day.month}월',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_monthImage != null)
                            Image.asset(
                              _monthImage!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                        ],
                      );
                    },
                    markerBuilder: (context, day, focusedDay) {
                      final strippedDay = _stripTime(day);
                      final hasChecked = _checkedDays.any((checkedDay) => _stripTime(checkedDay) == strippedDay);
                      final hasMemo = memoDates.contains(strippedDay);
                      final hasEvent = _events.any((event) =>
                      event['date'] == strippedDay);
                      if (hasChecked) {
                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB0F4E6), // 민트색 배경
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.black), // 텍스트 색상
                            ),
                          ),
                        );
                      }
                      if (hasMemo) {
                        return Positioned(
                          bottom: 4,
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.blue, // 메모 파란 점
                          ),
                        );
                      }

                      if (hasEvent) {
                        return Positioned(
                          bottom: 4,
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.yellow, // 이벤트 노란 점
                          ),
                        );
                      }

                      return null;
                    },
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),

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
                              return;
                            }

                            if (_checkedDays.any((checkedDay) =>
                                isSameDay(_selectedDay, checkedDay))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이미 출석 체크를 하셨습니다.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            await _saveAttendance();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('날짜를 선택해주세요.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedDay != null &&
                                _checkedDays.any((checkedDay) =>
                                    isSameDay(_selectedDay, checkedDay))
                                ? const Color(0xFFB0F4E6)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedDay != null &&
                                  _checkedDays.any((checkedDay) =>
                                      isSameDay(_selectedDay, checkedDay))
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
                                      isSameDay(_selectedDay, checkedDay))
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
              ],
            ),

            // 이벤트 표시 창
            if (selectedEvent.isNotEmpty)
              Positioned(
                top: MediaQuery
                    .of(context)
                    .size
                    .height * 0.15,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {}, // 이벤트 창 내부 클릭 시 닫히지 않도록 설정
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_selectedDay?.month ?? ''}월 ${_selectedDay?.day ??
                              ''}일',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedEvent['img'] != null)
                          Image.asset(
                            selectedEvent['img'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          selectedEvent['name'] ?? '이벤트 없음',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedEvent['content'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationSection(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          final DateTime memoDate = _selectedDay ?? DateTime.now();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoPage(
                selectedDate: memoDate,
                onSave: _loadAlarms, // onSave에 _loadAlarms 전달
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
