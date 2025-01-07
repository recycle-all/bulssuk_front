import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert'; // JSON 처리
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지
import 'package:web_socket_channel/status.dart' as status;

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  WebSocketChannel? channel;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  int? userNo;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadUserNo();
    await _loadUserId();
    if (userNo != null) {
      await _fetchChatHistory();
      _connectWebSocket();
    }
  }

  Future<void> _loadUserNo() async {
    final userNoString = await _storage.read(key: 'user_no');
    if (userNoString != null) {
      userNo = int.tryParse(userNoString);
      print('Loaded user_no: $userNo');
    } else {
      print('Error: user_no not found in SecureStorage.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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
    } else {
      print('Loaded user_id: $userId');
    }
  }

  Future<void> _fetchChatHistory() async {
    if (userNo == null) return;

    try {
      final url = Uri.parse('http://192.168.0.112:7777/chat_logs?user_no=$userNo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['chat_logs']);
        });
        print('Loaded chat history: $messages');
      } else {
        print('Failed to fetch chat history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
  }

  void _connectWebSocket() {
    if (channel != null || userNo == null) return;

    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.112:7777/ws/chatbot?user_no=$userNo'),
    );

    channel!.stream.listen(
          (message) {
        final decodedMessage = utf8.decode(message.runes.toList());
        final parsedMessage = jsonDecode(decodedMessage);
        final sender = parsedMessage['sender'];
        final content = parsedMessage['message'];

        setState(() {
          messages.add({"sender": sender, "message": content});
        });
      },
      onError: (error) => print("WebSocket 오류 발생: $error"),
      onDone: () {
        print("WebSocket 연결 종료");
        channel = null;
        _connectWebSocket();
      },
    );
  }

  void sendMessage() {
    if (_controller.text.isNotEmpty) {
      final messageText = _controller.text;

      channel?.sink.add(jsonEncode({"message": messageText}));

      setState(() {
        messages.add({"sender": "user", "message": messageText});
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    channel?.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ChatBot')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMessage = message['sender'] == 'user';
                final senderText = isUserMessage ? userId ?? '나' : '불쑥잉';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderText,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75, // 화면 너비의 75%로 제한
                          ),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.grey[300] : Color(0xFFB0F4E6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message['message'],
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 25), // 입력창 외부 간격 추가
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Color(0xFFB0F4E6), width: 2), // 기본 테두리
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Color(0xFFB0F4E6), width: 2), // 포커스 테두리
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  IconButton(
                    icon: Icon(Icons.send, color: Color(0xFFB0F4E6)),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          )

        ],
      ),
    );
  }
}
