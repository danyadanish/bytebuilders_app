import 'package:flutter/material.dart';
import 'advertiser_home_screen.dart';
import 'add_advertisement_screen.dart';
import 'my_advertisements_screen.dart';
import 'advertiser_profile_screen.dart';
import 'advertiser_notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertiserMainScreen extends StatefulWidget {
  const AdvertiserMainScreen({super.key});

  @override
  State<AdvertiserMainScreen> createState() => _AdvertiserMainScreenState();
}

class _AdvertiserMainScreenState extends State<AdvertiserMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdvertiserHomeScreen(),
    const AdvertiserNotificationsScreen(),
    const AddAdvertisementScreen(),
    const MyAdvertisementsScreen(),
    const AdvertiserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowPopupNotification();
  }

  Future<void> _checkAndShowPopupNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: user.uid)
        .where('shown', isEqualTo: false)
        .get();

    for (final doc in query.docs) {
      final message = doc['message'] ?? 'You have a new notification';

      // Show popup dialog
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B203D),
          title: const Text("Notification", style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      );

      // Mark this notification as shown
      await doc.reference.update({'shown': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A1A3A),
        selectedItemColor: const Color.fromARGB(255, 81, 139, 184),
        unselectedItemColor: const Color.fromARGB(255, 143, 169, 182),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'Add Ad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'My Ads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
