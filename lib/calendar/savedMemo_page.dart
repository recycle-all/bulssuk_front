import 'package:flutter/material.dart';
import 'updateMemo_page.dart'; // 수정 페이지 import
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final URL = dotenv.env['URL'];

class SavedMemoPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<dynamic> initialMemoList; // 초기 메모 리스트

  const SavedMemoPage({
    Key? key,
    required this.selectedDate,
    required this.initialMemoList,
  }) : super(key: key);

  @override
  _SavedMemoPageState createState() => _SavedMemoPageState();
}

class _SavedMemoPageState extends State<SavedMemoPage> {
  late List<dynamic> memoList;

  @override
  void initState() {
    super.initState();
    memoList = widget.initialMemoList; // 초기 메모 리스트 설정
    _refreshMemoList(); // API를 호출해 메모 리스트 초기화
  }

  Future<void> _refreshMemoList() async {
    setState(() {
      memoList = []; // 기존 리스트 초기화
    });

    final storage = FlutterSecureStorage(); // Secure Storage 객체 생성
    String? userId = await storage.read(key: 'user_id'); // 저장된 user_id 읽기

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$URL/date?user_id=$userId&user_calendar_date=${widget.selectedDate.toIso8601String().split('T')[0]}',
        ),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedMemos = jsonDecode(response.body);

        // user_calendar_list == true 데이터만 필터링
        final filteredMemos = fetchedMemos.where((memo) => memo['user_calendar_list'] == true).toList();

        setState(() {
          memoList = filteredMemos; // 필터링된 데이터만 업데이트
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모를 불러오지 못했습니다: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error fetching memos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar 배경색 변경
        title: Text(
            '${widget.selectedDate.year}년 ${widget.selectedDate.month}월 ${widget
                .selectedDate.day}일 메모'),
      ),
      body: memoList.isEmpty
          ? Center(child: CircularProgressIndicator()) // 로딩 상태 표시
          : ListView.builder(
        itemCount: memoList.length,
        itemBuilder: (context, index) {
          final memo = memoList[index];


          return Card(
            color: const Color(0xFFFCF9EC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥근 모서리
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // 외부 여백
            child: Padding(
              padding: const EdgeInsets.all(16.0), // 내부 여백
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 메모 정보 (제목과 내용)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memo['user_calendar_name'], // 제목
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          memo['user_calendar_memo'], // 내용
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                          maxLines: 2, // 최대 2줄로 제한
                          overflow: TextOverflow.ellipsis, // 길면 말줄임표 처리
                        ),
                      ],
                    ),
                  ),
                  // 수정 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateMemoPage(
                            memo: memo, // `user_calendar_no` 포함
                            selectedDate: widget.selectedDate,
                          ),
                        ),
                      );

                      if (result == true) {
                        _refreshMemoList();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 버튼 배경색
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                        side: const BorderSide(color: Color(0xFFCCCCCC)), // 테두리
                      ),
                    ),
                    child: const Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.black, // 텍스트 색상
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}