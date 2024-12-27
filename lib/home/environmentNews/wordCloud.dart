import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 디코딩
import 'package:url_launcher/url_launcher.dart'; // URL 열기
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import

// 페이지 UI
class Wordcloud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '오늘의 환경 뉴스',
      ),
      body: Column(
        children: [
          WordCloudSection(), // 워드클라우드 영역
          Expanded(child: ListSection()), // 리스트 영역
        ],
      ),
    );
  }
}

/// 워드클라우드 영역 위젯
class WordCloudSection extends StatefulWidget {
  @override
  _WordCloudSectionState createState() => _WordCloudSectionState();
}

class _WordCloudSectionState extends State<WordCloudSection> {
  String imageUrl = ""; // 서버에서 가져온 이미지 URL
  bool isLoading = true; // 로딩 상태

  // Flask 서버에서 워드클라우드 이미지 가져오기
  Future<void> fetchWordCloud() async {
    final String url = 'http://192.168.0.116:5001/api/wordcloud'; // Flask 서버 URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          imageUrl = url; // 이미지 URL 설정
          isLoading = false; // 로딩 완료
        });
      } else {
        print("Failed to fetch Word Cloud: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching Word Cloud: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWordCloud(); // 위젯 초기화 시 워드클라우드 이미지 가져오기
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 가로 전체 크기
      height: 350, // 높이 설정
      margin: EdgeInsets.all(16.0), // 외부 여백
      child: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : imageUrl.isNotEmpty
          ? Image.network(
        imageUrl, // 서버에서 받은 이미지 URL
        fit: BoxFit.cover, // 이미지 크기 맞추기
      )
          : Center(
        child: Text(
          '이미지를 불러올 수 없습니다.', // 오류 메시지
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// 리스트 영역 위젯
class ListSection extends StatefulWidget { // <-- StatefulWidget으로 변경
  @override
  _ListSectionState createState() => _ListSectionState();
}

class _ListSectionState extends State<ListSection> {
  List<dynamic> articles = []; // 기사 데이터 리스트
  bool isLoading = true; // 로딩 상태

  // Flask 서버에서 기사 데이터 가져오기
  Future<void> fetchArticles() async {
    final String url = 'http://192.168.0.116:5001/api/news';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body); // JSON 파싱
          isLoading = false;
        });
      } else {
        print("Failed to fetch articles: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching articles: $e");
    }
  }

  // URL 열기
  void _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchArticles(); // 위젯 초기화 시 기사 데이터 가져오기
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator()); // 로딩 중 표시
    }

    if (articles.isEmpty) {
      return Center(
        child: Text(
          '뉴스 기사를 가져올 수 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return ListTile(
          leading: Text(
            '${index + 1}', // 번호 추가
            style: TextStyle(
              fontSize: 18, // 번호 폰트 크기
              fontWeight: FontWeight.bold,
              color: Color(0xFF12D3CF), // 번호 색상
            ),
          ),
          title: Text(
            article['title'], // 기사 제목
            style: TextStyle(
              color: Colors.black, // 제목 텍스트 색상 설정
              fontSize: 14, // 제목 폰트 크기
            ),
            overflow: TextOverflow.ellipsis, // 줄바꿈 방지 + 말줄임표 표시
            maxLines: 1, // 최대 한 줄로 제한
          ),
          onTap: () => _openUrl(article['link']), // 제목 클릭 시 URL 열기
        );
      },
    );
  }
}

