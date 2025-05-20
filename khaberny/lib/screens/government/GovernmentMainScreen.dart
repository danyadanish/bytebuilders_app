import 'package:flutter/material.dart';
import 'GovernmentHomeScreen.dart';
import 'GovernmentFeedScreen.dart';
import 'government_delete_requests_screen.dart';

class GovernmentMainScreen extends StatefulWidget {
  const GovernmentMainScreen({super.key});

  @override
  State<GovernmentMainScreen> createState() => _GovernmentMainScreenState();
}

class _GovernmentMainScreenState extends State<GovernmentMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const GovernmentHomeScreen(),
      const GovernmentFeedScreen(),
      const GovernmentDeleteRequestsScreen(),
      const Placeholder(),
    ];
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1B203D),
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: const Color.fromARGB(255, 141, 135, 135),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Feed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.delete), label: 'Delete Req'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        ],
      ),
    );
  }
}
