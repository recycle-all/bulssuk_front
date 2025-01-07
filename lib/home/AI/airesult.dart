import 'dart:io';
import 'package:flutter/material.dart';
import '../home.dart';
import '../ai/voting.dart';
import 'package:http/http.dart' as http;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as path; // 파일명 처리
import 'dart:convert'; // JSON 변환을 위해 추가
import 'package:uuid/uuid.dart';



const String ftpHost = "222.112.27.120"; // FTP 서버 주소
const String ftpUser = "suddenly"; // FTP 계정 사용자 이름
const String ftpPassword = "suddenly"; // FTP 계정 비밀번호
const String ftpDirectory = "img/"; // 파일을 저장할 디렉터리

class Airesult extends StatelessWidget {
  final File imageFile;
  final List<Map<String, dynamic>> predictions;

  const Airesult({
    Key? key,
    required this.imageFile,
    required this.predictions,
  }) : super(key: key);

  Future<String> uploadFileToFTP(File file) async {
    final ftpConnect = FTPConnect(
      ftpHost,
      user: ftpUser,
      pass: ftpPassword,
      timeout: const Duration(seconds: 30).inMilliseconds,
    );

    try {
      print("FTP 서버에 연결 시도...");
      await ftpConnect.connect();

      // 업로드할 디렉터리로 변경
      await ftpConnect.changeDirectory(ftpDirectory);

      // 고유 파일명 생성
      final uuid = Uuid();
      final String uniqueFilename = '${uuid.v4()}.jpg';

      // 파일 업로드
      final bool result = await ftpConnect.uploadFile(
        file,
        sRemoteName: uniqueFilename,
      );

      if (result) {
        print("파일 업로드 성공: $uniqueFilename");
        return uniqueFilename; // 성공적으로 업로드된 파일명 반환
      } else {
        throw Exception("파일 업로드 실패");
      }
    } catch (e) {
      print("FTP 업로드 중 오류 발생: $e");
      throw Exception("FTP 업로드 실패: $e"); // 예외 발생 시에도 반드시 예외를 던져야 함
    } finally {
      await ftpConnect.disconnect();
      print("FTP 연결 종료");
    }
  }


  // 투표 업로드
  Future<bool> uploadVote(File imageFile, String voteResult) async {
    const String serverUrl = 'http://222.112.27.120:8001/upload';


    try {
      // FTP 업로드 함수 호출
      final uniqueFilename = await uploadFileToFTP(imageFile);
      final String imgUrl = 'http://222.112.27.120:81/img/$uniqueFilename';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vote_result': voteResult,
          'img_url': imgUrl,
        }),
      );

      if (response.statusCode == 200) {

        print('Vote uploaded successfully');
        return true;
      } else {
        print('Failed to upload vote: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error uploading vote: $e');
      return false;
    }
  }


  // 페이지 이동 함수
  void navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분석 결과',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              '이 쓰레기 어떻게 버리지?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI한테 물어보기!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              '불쑥 AI는 실수를 할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '분석 결과',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            predictions.isNotEmpty
                ? Text(
              predictions[0]['name'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            )
                : const Text(
              '분석 결과가 없습니다.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => navigateToHome(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text('확인'),
            ),
            const SizedBox(height: 80),
            const Text(
              '결과에 대한 정확한 의견을 얻고 싶나요?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () async {
                try {
                  final success = await uploadVote(
                    imageFile,
                    predictions.isNotEmpty ? predictions[0]['name'] ?? '' : '분석 결과 없음',
                  );
                  if (success) {
                    showTopNotification(context, '투표글을 올렸어요.');
                    navigateToHome(context);
                  } else {
                    showTopNotification(context, '투표 업로드 실패!');
                  }
                } catch (e) {
                  showTopNotification(context, '네트워크 오류 발생!');
                  print('Error uploading vote: $e');
                }
              },
              child: const Text(
                '내 분리수거 결과 투표에 올리기',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 상단 알림 표시 함수
void showTopNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50.0,
      left: 20.0,
      right: 20.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👀', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
