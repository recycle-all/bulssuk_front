import 'dart:io';
import '../ai/airesult.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Ai extends StatelessWidget {
  final File imageFile;

  const Ai({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('찍은 사진'),
        actions: [
          TextButton(
            onPressed: () {
              // 분석하기 버튼 눌렀을 때 동작
              _analyzeImage(context);
            },
            child: const Text(
              '분석하기',
              style: TextStyle(
                color: Colors.black, // 텍스트 색상
                fontSize: 16, // 텍스트 크기
                fontWeight: FontWeight.bold, // 텍스트 두께
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: imageFile != null
            ? Image.file(
          imageFile,
          fit: BoxFit.contain,
        )
            : const Text('사진이 없습니다.'),
      ),
    );
  }

  void _analyzeImage(BuildContext context) async {
    // FastAPI 서버 URL
    const String serverUrl = 'http://192.168.0.240:8765/analyze';
    debugPrint('서버 URL: $serverUrl');

    try {
      // 서버로 이미지 전송
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      debugPrint('이미지 업로드 준비 중...');
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // FastAPI에서 받는 매개변수 이름
          imageFile.path,
        ),
      );

      debugPrint('이미지 업로드 시작...');
      var response = await request.send();
      debugPrint('응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 결과 파싱
        final responseData = json.decode(await response.stream.bytesToString());
        final List<Map<String, dynamic>> predictions = List<Map<String, dynamic>>.from(responseData['predictions']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Airesult(
              imageFile: imageFile,
              predictions: predictions,
            ),
          ),
        );
      } else {
        // 서버 오류 처리
        debugPrint('서버 오류: ${response.statusCode}');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('오류'),
            content: Text('서버 오류 발생: ${response.statusCode}\n서버 상태를 확인해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 네트워크 오류 처리
      debugPrint('네트워크 오류 발생: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text('네트워크 오류 발생: $e\n네트워크 상태와 서버 URL을 확인해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
