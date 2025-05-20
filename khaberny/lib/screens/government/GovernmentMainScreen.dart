import 'package:flutter/material.dart';
import 'package:khaberny/screens/citizen/citizen_report_problem_screen.dart';
import 'package:khaberny/screens/notifications/notification_screen.dart';
import 'GovernmentHomeScreen.dart';
import 'GovernmentFeedScreen.dart';
import '../messaging/messageHomepage.dart';
import 'government_delete_requests_screen.dart';
import 'government_problem_reports_screen.dart';

class GovernmentMainScreen extends StatefulWidget {
  const GovernmentMainScreen({super.key});

  @override
  State<GovernmentMainScreen> createState() => _GovernmentMainScreenState();
}

class _GovernmentMainScreenState extends State<GovernmentMainScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const GovernmentHomeScreen(), // Show the home screen by default
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:
            0, // Always highlight Home, or manage this with logic if needed
        backgroundColor: const Color(0xFF1B203D),
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: const Color.fromARGB(255, 141, 135, 135),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/government');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/governmentFeed');
              break;
            case 2:
              Navigator.pushNamed(context, '/message');
              break;
            case 3:
              Navigator.pushNamed(context, '/notifications');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Feed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }
}
