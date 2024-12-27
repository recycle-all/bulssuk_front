import 'package:flutter/material.dart';
import 'package:bulssuk/calendar/calendar_page.dart';
import '../home/home.dart';
import '../calendar/calendar_page.dart';
import '../myTree/tree_page.dart';
import '../myPage/dashboard.dart';

class BottomNavigationSection extends StatefulWidget {
  final int currentIndex; // 현재 선택된 인덱스

  const BottomNavigationSection({Key? key, required this.currentIndex})
      : super(key: key);

  @override
  _BottomNavigationSectionState createState() =>
      _BottomNavigationSectionState();
}

class _BottomNavigationSectionState extends State<BottomNavigationSection> {
  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return; // 같은 메뉴를 클릭하면 아무 동작도 하지 않음

    // 인덱스에 따라 페이지 네비게이션
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TreePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: widget.currentIndex, // 현재 선택된 인덱스
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '달력',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.nature),
          label: '내 나무',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '마이페이지',
        ),
      ],
    );
  }
}