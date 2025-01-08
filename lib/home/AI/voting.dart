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

  // 한글-영어 매핑 테이블
  final Map<String, String> _optionMapping = {
    '플라스틱': 'plastic',
    '유리': 'glass',
    '메탈': 'metal',
  };

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
  // 만료까지 남은 일수 계산하는 함수
  int _daysUntilExpiry(String createdAt) {
    final DateTime createdDate = DateTime.parse(createdAt);
    final DateTime expiryDate = createdDate.add(const Duration(days: 7));
    return expiryDate.difference(DateTime.now()).inDays;
  }

// 남은 날짜를 표시하는 위젯 (색상 변화 포함)
  Widget _buildRemainingDaysWidget(String createdAt) {
    final int remainingDays = _daysUntilExpiry(createdAt);
    final bool isCritical = remainingDays <= 3; // 3일 이하일 때 빨간색으로 표시

    return Text(
      remainingDays == 0 ? '오늘까지' : 'D-$remainingDays', // D-0일 때 "오늘까지"로 표시
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isCritical ? Colors.red : Colors.black, // 조건에 따라 색상 변경
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분리수거 결과 투표창',
            style: TextStyle(
              fontSize: 18, // 텍스트 크기 조정
              color: Colors.black, // 텍스트 색상 변경
            ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // 전체 Column에 왼쪽 및 오른쪽 여백 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI의 분석 결과에 투표하고 포인트 받으세요!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 6),
            Text(
              '투표하기 📥',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: voteList.length,
                itemBuilder: (context, index) {
                  final vote = voteList[index];
                  final bool expired = _isVoteExpired(vote['created_at']); // 만료 여부 확인
                  final bool alreadyVoted = vote['user_voted'] ?? false;

                  if (expired) return SizedBox.shrink(); // 만료된 투표는 표시하지 않음

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0), // 카드 간의 간격
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 수평 정렬
                            crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬
                            children: [
                              Text(
                                '이 쓰레기는 무엇일까요?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              _buildRemainingDaysWidget(vote['created_at']), // 오른쪽에 배치
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
                              _buildVoteButton('플라스틱', vote['vote_no'], alreadyVoted),
                              _buildVoteButton('유리', vote['vote_no'], alreadyVoted),
                              _buildVoteButton('메탈', vote['vote_no'], alreadyVoted),
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
            if (isLoading) ...[
              const SizedBox(height: 10),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center( // 중앙 정렬
                  child: IconButton(
                    onPressed: fetchNextPage,
                    icon: const Icon(Icons.refresh),
                    color: Colors.grey,
                    iconSize: 36.0,
                    tooltip: '더 보기',
                  ),
                ),
              ),
            if (!hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Text('모든 데이터를 로드했습니다.'),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildVoteButton(String label, int voteNo, bool alreadyVoted) {
    final bool alreadyVoted = voteList.any((vote) => vote['vote_no'] == voteNo && vote['user_voted'] == true);
    final String option = _optionMapping[label] ?? label;

    return ElevatedButton(
      onPressed: alreadyVoted
          ? null // 이미 투표한 경우 버튼 비활성화
      : () async {
        await updateVote(widget.userNo, voteNo, option); // userNo 전달
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
