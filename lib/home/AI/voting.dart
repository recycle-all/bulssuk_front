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
    voteList = widget.initialVoteList; // 초기 데이터를 설정
  }

  Future<void> fetchNextPage() async {
    if (isLoading || !hasMore) return; // 이미 로딩 중이거나 더 이상 데이터가 없으면 중단
    setState(() {
      isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> newVotes = await fetchVoteList(page: currentPage + 1);
      if (newVotes.isEmpty) {
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
    const String serverUrl = 'http://192.168.0.240:8001/updatevote';

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
                return Card(
                  margin: const EdgeInsets.all(10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '이 쓰레기는 무엇 일까요?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          // 이미지 URL 생성
                          'http://192.168.0.240:8001/images/${vote['img_url']?.split('/').last ?? 'default.jpg'}',
                          fit: BoxFit.cover,
                          height: 350,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('Image loading error: $error');
                            print('Image URL: ${vote['img_url']}');
                            return const Center(child: Text('이미지를 불러오지 못했습니다.'));
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildVoteButton('plastic', vote['vote_no']),
                            _buildVoteButton('glass', vote['vote_no']),
                            _buildVoteButton('metal', vote['vote_no'])
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          if (hasMore)
            ElevatedButton(
              onPressed: fetchNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('더 보기'),
            ),
          if (!hasMore) const Text('모든 데이터를 로드했습니다.'),
        ],
      ),
    );
  }

  Widget _buildVoteButton(String label, int voteNo) {
    final bool alreadyVoted = voteList.any((vote) => vote['vote_no'] == voteNo && vote['user_voted'] == true);

    return ElevatedButton(
      onPressed: alreadyVoted
          ? null // 이미 투표한 경우 버튼 비활성화
      : () async {
        await updateVote(widget.userNo, voteNo, label); // userNo 전달

        // 투표 완료 메시지 표시
        // showDialog(
        //   context: context,
        //   barrierDismissible: false, // 사용자가 외부를 눌러도 닫히지 않도록 설정
        //   builder: (BuildContext context) {
        //     Future.delayed(const Duration(seconds: 2), () {
        //       Navigator.of(context).pop(); // 2초 후 모달 닫기
        //     });
        //
        //     return AlertDialog(
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       content: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           const Icon(
        //             Icons.check_circle,
        //             color: Colors.green,
        //             size: 50,
        //           ),
        //           const SizedBox(height: 10),
        //           Text(
        //             '\'$label\'에 투표하셨습니다.',
        //             style: const TextStyle(fontSize: 16),
        //             textAlign: TextAlign.center,
        //           ),
        //         ],
        //       ),
        //     );
        //   },
        // );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: alreadyVoted ? Colors.grey : Colors.white,
        foregroundColor: alreadyVoted ? Colors.black45 : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.green),
        ),
      ),
      child: Text(label),
    );
  }

  Future<List<Map<String, dynamic>>> fetchVoteList({required int page}) async {
    const String serverUrl = 'http://192.168.0.240:8001/votes';

    try {
      final response = await http.get(Uri.parse('$serverUrl?page=$page&limit=10'));

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
