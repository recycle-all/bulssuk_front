import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoteBoardPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialVoteList;
  final int userNo; // 사용자 번호

  const VoteBoardPage({Key? key, required this.initialVoteList, required this.userNo})
      : super(key: key);

  @override
  _VoteBoardPageState createState() => _VoteBoardPageState();
}

class _VoteBoardPageState extends State<VoteBoardPage> {
  List<Map<String, dynamic>> voteList = [];
  int currentPage = 1; // 현재 페이지 번호
  bool isLoading = false; // 로딩 상태
  bool hasMore = true; // 추가 데이터 존재 여부

  @override
  void initState() {
    super.initState();
    // 만료된 투표 필터링과 초기 데이터를 설정
    voteList = widget.initialVoteList.where((vote) => !_isVoteExpired(vote['created_at'])).toList();
    // voteList = widget.initialVoteList; // 초기 데이터를 설정
  }
  // 만료된 투표인지 확인하는 함수 (7일이 지난 투표는 만료)
  bool _isVoteExpired(String createdAt) {
    final DateTime createdDate = DateTime.parse(createdAt);
    final DateTime expiryDate = createdDate.add(const Duration(days: 7));
    return DateTime.now().isAfter(expiryDate);
  }

  Future<void> fetchNextPage() async {
    if (isLoading || !hasMore) return; // 이미 로딩 중이거나 더 이상 데이터가 없으면 중단
    setState(() {
      isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> newVotes = await fetchVoteList(page: currentPage + 1);
      // 새로 가져온 데이터에서 만료된 투표 필터링
      final filteredVotes = newVotes.where((vote) => !_isVoteExpired(vote['created_at'])).toList();

      if (filteredVotes.isEmpty) {
        setState(() {
          hasMore = false; // 더 이상 데이터가 없음을 설정
        });
      } else {
        setState(() {
          voteList.addAll(newVotes); // 기존 리스트에 새로운 데이터 추가
          currentPage++; // 현재 페이지 증가
        });
      }
    } catch (e) {
      print('Error fetching votes: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateVote(int userNo, int voteNo, String option) async {
    const String serverUrl = 'http://222.112.27.120:8001/updatevote';

    try {
      final response = await http.put(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_no': userNo, // 사용자 번호 전달
          'vote_no': voteNo,
          'option': option,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Vote updated successfully: ${data['vote_result']}');
        final message = data['message']; // 서버에서 반환한 메시지 (포인트 지급 여부 포함)
        // 투표 완료 후 UI 업데이트
        setState(() {
          // 이미 투표한 것으로 표시
          final index = voteList.indexWhere((vote) => vote['vote_no'] == voteNo);
          if (index != -1) {
            voteList[index]['user_voted'] = true;
          }
        });
        // 성공 메시지 다이얼로그 표시
        _showSuccessDialog(message);
      } else {
        // print('Failed to update vote: ${response.statusCode}');
        // print('Response body: ${response.body}');
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? '알 수 없는 오류가 발생했습니다.';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('Error updating vote: $e');
      _showErrorDialog('네트워크 오류가 발생했습니다.');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 외부를 눌러도 닫히지 않도록 설정
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(); // 2초 후 모달 닫기
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }


  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분리수거 결과 투표창',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: voteList.length,
              itemBuilder: (context, index) {
                final vote = voteList[index];
                final bool expired = _isVoteExpired(vote['created_at']); // 만료 여부 확인
                final bool alreadyVoted = vote['user_voted'] ?? false;

                if (expired) return Container(); // 만료된 투표는 표시하지 않음

                return Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white, // 박스 배경색 하얀색
                    border: Border.all( // 테두리 설정
                      color: Colors.grey[200]!,
                      width: 2.0, // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '이 쓰레기는 무엇일까요?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Image.network(
                          'http://222.112.27.120:81/img/${vote['img_url']?.split('/').last ?? 'default.jpg'}',
                          fit: BoxFit.contain,
                          height: 200,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('Image loading error: $error');
                            print('Image URL: ${vote['img_url']}');
                            return const Center(child: Text('이미지를 불러오지 못했습니다.'));
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildVoteButton('plastic', vote['vote_no'], alreadyVoted),
                            _buildVoteButton('glass', vote['vote_no'], alreadyVoted),
                            _buildVoteButton('metal', vote['vote_no'], alreadyVoted),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );

              },
            ),
          ),
          const SizedBox(height: 10), // 간격 추가
          if (isLoading) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: IconButton(
                onPressed: fetchNextPage,
                icon: const Icon(Icons.refresh),
                color: Colors.grey,
                iconSize: 36.0, // 아이콘 크기 조정 가능
                tooltip: '더 보기',
              ),
            ),
          const SizedBox(height: 10), // 간격 추가
          if (!hasMore) const Text('모든 데이터를 로드했습니다.'),
        ],
      ),
    );
  }

  Widget _buildVoteButton(String label, int voteNo, bool alreadyVoted) {
    final bool alreadyVoted = voteList.any((vote) => vote['vote_no'] == voteNo && vote['user_voted'] == true);

    return ElevatedButton(
      onPressed: alreadyVoted
          ? null // 이미 투표한 경우 버튼 비활성화
      : () async {
        await updateVote(widget.userNo, voteNo, label); // userNo 전달
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: alreadyVoted ? Colors.grey : Colors.white,
        foregroundColor: alreadyVoted ? Colors.black45 : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFFB0F4E6)),
        ),
      ),
      child: Text(label),
    );
  }

  Future<List<Map<String, dynamic>>> fetchVoteList({required int page}) async {
    const String serverUrl = 'http://222.112.27.120:8001/votes';

    try {
      // final response = await http.get(Uri.parse('$serverUrl?page=$page&limit=10'));
      // user_no를 쿼리 파라미터로 추가
      final response = await http.get(Uri.parse('$serverUrl?page=$page&limit=10&user_no=${widget.userNo}'));


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Failed to fetch vote list: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching vote list: $e');
      return [];
    }
  }
}
