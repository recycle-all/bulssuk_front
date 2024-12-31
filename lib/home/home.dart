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
import 'package:image_picker/image_picker.dart'; // image_picker import
import 'dart:io'; // File 사용

class HomePage extends StatefulWidget {
  const HomePage({super.key}); // const 생성자 유지

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> articles = []; // 뉴스 리스트
  bool isLoading = true; // 로딩 상태
  PageController _pageController = PageController(); // PageView 컨트롤러
  Timer? _timer; // 자동 스크롤 타이머
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
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
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
    'assets/tree2.png',
    width: 68,
    height: 68,
    fit: BoxFit.cover,
    ),
    ],
    ),
    const SizedBox(height: 10),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    ElevatedButton(
    onPressed: () {},
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
    ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFCF9EC),
    foregroundColor: Colors.black,
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
      SizedBox(
        height: 50,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              leading: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF12D3CF),
                ),
              ),
              title: Text(
                article['title'],
                style: const TextStyle(fontSize: 14, color: Colors.black),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              onTap: () => _openUrl(article['link']),
            );
          },
        ),
      ),
      const Divider(),

      // 3. AI 영역
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'AI한테 물어보기!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _openCamera,
              child: const Icon(Icons.camera_alt, size: 60, color: Color(0xFF12D3CF)),
            ),
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
      const Divider(),

      // 4. guide 영역
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          '분리수거 가이드',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildGuideItemWithImage(context, '종이', 'assets/paper.png', () {
              print('종이 클릭됨');
            }),
            _buildGuideItemWithImage(context, '종이팩', 'assets/paper_pack.png', () {
              print('종이팩 클릭됨');
            }),
            _buildGuideItemWithImage(context, '금속캔', 'assets/can.png', () {
              print('금속캔 클릭됨');
            }),
            _buildGuideItemWithImage(context, '유리', 'assets/glass.png', () {
              print('유리 클릭됨');
            }),
            _buildGuideItemWithImage(context, '비닐', 'assets/binil.png', () {
              print('비닐 클릭됨');
            }),
            _buildGuideItemWithImage(context, '페트병', 'assets/pet.png', () {
              print('페트병 클릭됨');
            }),
            _buildGuideItemWithImage(context, '플라스틱', 'assets/plastic.png', () {
              print('플라스틱 클릭됨');
            }),
            _buildGuideItemWithImage(context, '스티로폼', 'assets/styrofoam.png', () {
              print('스티로폼 클릭됨');
            }),
            _buildGuideItemWithImage(context, '기타', 'assets/trashcan.png', () {
              print('기타 클릭됨');
            }),
          ],
        ),
      ),
      const Divider(),

      // 5. reupcycling 영역
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          '리사이클링, 업사이클링 기업',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      SizedBox(
        height: 150,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildRecyclingCard(context, '플라스틱 방앗간', 'assets/plastic_bag.png'),
            _buildRecyclingCard(context, '119REO', 'assets/119reo.jpg'),
            _buildRecyclingCard(context, 'seedkeeper', 'assets/seedkeeper.jpg'),
          ],
        ),
      ),
    ],
    ),
    ),
      bottomNavigationBar: const BottomNavigationSection(currentIndex: 0), // 하단 네비게이션 바
    );
  }

  // 분리수거 가이드 아이템 위젯
  Widget _buildGuideItemWithImage(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecyclingMenuPage(title: title),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  imagePath,
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
  Widget _buildRecyclingCard(BuildContext context, String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReupcyclingPage()),
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
            Image.asset(imagePath, height: 80, fit: BoxFit.cover),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}