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
    final String url = 'http://222.112.27.120:5002/api/wordcloud'; // Flask 서버 URL
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
class ListSection extends StatefulWidget {
  @override
  _ListSectionState createState() => _ListSectionState();
}

class _ListSectionState extends State<ListSection> {
  List<dynamic> articles = []; // 기사 데이터 리스트
  bool isLoading = true; // 로딩 상태

  // Flask 서버에서 기사 데이터 가져오기
  Future<void> fetchArticles() async {
    final String url = 'http://222.112.27.120:5002/api/news';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fetchedArticles = json.decode(response.body);
        // print("받은 기사 개수: ${fetchedArticles.length}"); // 디버깅: 받은 데이터 개수 출력
        setState(() {
          articles = fetchedArticles;
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

    // 디버깅: 데이터 개수 확인
    print("렌더링할 기사 개수: ${articles.length}");

    return ListView.builder(
      itemCount: articles.length, // 데이터 개수만큼 아이템 생성
      itemBuilder: (context, index) {
        // print("렌더링 중: $index 번째 기사 - ${articles[index]['title']}"); // 렌더링 확인
        final article = articles[index];
        return ListTile(
          leading: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12D3CF),
            ),
          ),
          title: Text(
            article['title'],
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          onTap: () => _openUrl(article['link']),
        );
      },
    );
  }
}

