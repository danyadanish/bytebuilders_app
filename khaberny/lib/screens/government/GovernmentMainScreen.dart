import 'package:flutter/material.dart';
import 'GovernmentHomeScreen.dart';
import 'GovernmentFeedScreen.dart';

class GovernmentMainScreen extends StatefulWidget {
  const GovernmentMainScreen({super.key});

  @override
  State<GovernmentMainScreen> createState() => _GovernmentMainScreenState();
}

class _GovernmentMainScreenState extends State<GovernmentMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GovernmentHomeScreen(),
    const GovernmentFeedScreen(),
    Placeholder(), // Chat
    Placeholder(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1B203D),
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: const Color.fromARGB(255, 141, 135, 135),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        ],
      ),
    );
  }
}
