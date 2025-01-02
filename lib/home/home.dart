import 'dart:async'; // Timer를 위해 추가
import 'package:flutter/material.dart';
import 'recyclingGuide/reupcycling_page.dart';
import 'recyclingGuide/recyclingMenu_page.dart';
import '../../widgets/top_nav.dart'; // 공통 AppBar 위젯 import
import '../../widgets/bottom_nav.dart'; // 하단 네비게이션 가져오기
import '../../home/environmentNews/wordCloud.dart'; // WordCloud 페이지 import
import 'package:http/http.dart' as http; // HTTP 요청을 위해 추가
import 'dart:convert'; // JSON 디코딩
import 'package:url_launcher/url_launcher.dart'; // URL 열기를 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart'; // image_picker import
import 'dart:io'; // File 사용

final URL = dotenv.env['URL'];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> articles = []; // 뉴스 리스트
  bool isLoading = true; // 로딩 상태
  PageController _pageController = PageController(); // PageView 컨트롤러
  Timer? _timer; // 자동 스크롤 타이머
  List<dynamic> categories = []; // 대분류 데이터 저장
  final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성
  File? _image; // 선택된 이미지 저장

  // 뉴스 데이터를 가져오는 함수
  Future<void> fetchArticles() async {
    final String url = 'http://192.168.0.116:5001/api/news'; // Flask 서버 URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body).take(10).toList(); // 최대 10개의 뉴스 데이터 가져오기
          isLoading = false;
        });
        _startAutoScroll(); // 뉴스 데이터를 가져온 후 자동 스크롤 시작
      } else {
        print("Failed to fetch articles: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching articles: $e");
    }
  }

  // 자동 스크롤 타이머 시작
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_pageController.page!.toInt() + 1) % articles.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 대분류 데이터를 API로 가져오기
  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$URL/categories'));
      if (response.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // 리사이클링, 업사이클링 기업 리스트를 가져오는 API 함수
  Future<List<Map<String, dynamic>>> fetchCompanies() async {
    final url = Uri.parse('$URL/company');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load companies');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // URL 열기 함수
  void _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  // 카메라 열기 함수
  Future<void> _openCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path); // 이미지 파일 저장
        });
      }
    } catch (e) {
      print("카메라 사용 중 오류 발생: $e");
    }
  }


  @override
  void initState() {
    super.initState();
    fetchArticles(); // 초기화 시 뉴스 데이터 가져오기
    fetchCategories(); // 초기화 시 대분류 데이터 가져옴
  }

  @override
  void dispose() {
    _pageController.dispose(); // PageView 컨트롤러 해제
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavigationSection(
        title: '',
        backgroundColor: Color(0xFFB0F4E6), // 홈 화면의 AppBar 색상
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. event 영역
            Container(
              color: const Color(0xFFB0F4E6),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 텍스트와 아이콘 배치
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // 위쪽 정렬
                    children: [
                      const Expanded(
                        child: Text(
                          '불쑥과 함께 분리수거하고\n나무도 키워요!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/tree2.png', // 이미지 경로
                        width: 68, // 이미지 너비
                        height: 68, // 이미지 높이
                        fit: BoxFit.cover, // 이미지 비율 유지
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // 간격 추가
                  // 버튼 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 오늘의 퀴즈 버튼
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/quiz'); // /quiz로 이동
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFCF9EC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('오늘의 퀴즈'),
                      ),
                      // 나무키우기 버튼
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFCF9EC), // 버튼 배경색
                          foregroundColor: Colors.black, // 버튼 글자색
                          padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('나무키우기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 뉴스 영역
            GestureDetector(
              onTap: () {
                // "오늘의 환경 뉴스" 클릭 시 WordCloud 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Wordcloud(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '오늘의 환경 뉴스',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // 뉴스 리스트 (하나씩 표시하며 자동 스크롤, 세로 스크롤)
            SizedBox(
              height: 50, // 높이 조정
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // 스크롤 방향 세로로 설정
                itemCount: articles.length,
                onPageChanged: (index) {
                  if (index == articles.length - 1) {
                    // 마지막 뉴스에서 4초 후 첫 번째 뉴스로 이동
                    Future.delayed(const Duration(seconds: 4), () {
                      _pageController.jumpToPage(0); // 모션 없이 첫 번째로 이동
                    });
                  }
                },
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 5.0), // 뉴스 번호를 쪽으로 띄움
                    child: ListTile(
                      leading: Text(
                        '${index + 1}', // 뉴스 번호
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF12D3CF),
                        ),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(), // 번호와 제목 간 간격 조정
                        child: Text(
                          article['title'], // 뉴스 제목
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      onTap: () => _openUrl(article['link']), // 뉴스 클릭 시 URL 열기
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // 3. AI 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
                children: [
                  const Text(
                    'AI한테 물어보기!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Center( // 아이콘을 가로 세로 중앙 정렬
                    child: GestureDetector(
                      onTap: _openCamera,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Color(0xFF12D3CF),
                      ),
                    ),
                  ),
                  if (_image != null) ...[
                    const SizedBox(height: 20), // 이미지와 텍스트 간 간격
                    Center( // 이미지를 가운데 정렬
                      child: Image.file(
                        _image!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),

            // 4. guide 영역
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '분리수거 대분류',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  // 데이터베이스 경로를 assets 경로로 변환
                  final imagePath = 'assets${category['category_img'].replaceFirst('/uploads/images', '')}';
                  return _buildCategoryItem(
                    context,
                    category['category_name'],
                    imagePath,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecyclingMenuPage(
                              categoryId: category['category_no'],
                              categoryName: category['category_name']), // 전달할 카테고리 이름
                        ),
                      );
                    },
                  );
                }),
              ),
            ),

            // 5. reupcycling 영역 (가로 스크롤)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '리사이클링, 업사이클링 기업',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 150,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchCompanies(), // 리사이클링 기업 데이터를 가져오는 함수
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No companies available'));
                  }

                  final companies = snapshot.data!;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal, // 가로 스크롤
                    physics: const AlwaysScrollableScrollPhysics(), // 스크롤 강제 활성화
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return _buildRecyclingCard(
                        context,
                        company['company_name'], // 기업 이름
                        company['company_img'], // 기업 이미지 URL
                        company['company_no'], // 기업 ID
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationSection(currentIndex: 0), // 하단 네비게이션 바
    );
  }

  // 분리수거 가이드 아이템 위젯
  Widget _buildCategoryItem(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12), // 둥근 테두리
              border: Border.all(
                color: const Color(0xFF67EACA),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath, // 로컬 경로로 이미지 로드
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  // 리사이클링 카드 위젯
  Widget _buildRecyclingCard(
      BuildContext context, String title, String imageUrl, int companyId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReupcyclingPage(companyId: companyId),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9EC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
