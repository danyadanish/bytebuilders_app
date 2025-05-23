import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/account_type_selection_screen.dart';
import 'screens/citizen/citizen_signup_screen.dart';
import 'screens/advertiser/advertiser_signup_screen.dart';
import 'screens/advertiser/advertiser_home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/advertiser/advertiser_main_screen.dart';
import 'screens/advertiser/my_advertisements_screen.dart';
import 'screens/advertiser/add_advertisement_screen.dart';
import 'screens/advertiser/advertiser_profile_screen.dart';
import 'screens/government/approve_ads_screen.dart';
import 'screens/government/create_poll_screen.dart';
import 'screens/government/poll_list_screen.dart';
import 'screens/government/GovernmentMainScreen.dart';
import 'screens/government/government_delete_requests_screen.dart';
import 'screens/citizen/citizen_feed_screen.dart';
import 'screens/citizen/citizen_report_problem_screen.dart';
import 'screens/messaging/messageHomepage.dart';
import 'screens/citizen/emergency_numbers_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/government/government_problem_reports_screen.dart';

class FirebaseMessagingService {
  Future<void> initialize() async {
    // Initialize Firebase Messaging here
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize Firebase Messaging
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khaberny App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFF1B203D),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/accountType': (context) => AccountTypeSelectionScreen(),
        '/citizenSignup': (context) => CitizenSignUpScreen(),
        '/advertiserSignup': (context) => AdvertiserSignUpScreen(),
        '/advertiserHome': (context) => AdvertiserHomeScreen(),
        '/signIn': (context) => SignInScreen(),
        '/advertiser': (context) => const AdvertiserMainScreen(),
        '/createAd': (context) => AddAdvertisementScreen(),
        '/myAds': (context) => MyAdvertisementsScreen(),
        '/profile': (context) => AdvertiserProfileScreen(),
        '/reportOverview': (context) => const Placeholder(),
        '/government': (context) => const GovernmentMainScreen(),
        '/approveAds': (context) => const ApproveAdsScreen(),
        '/createPoll': (context) => const CreatePollScreen(),
        '/polls': (context) => const PollListScreen(),
        '/deleteRequests': (context) => const GovernmentDeleteRequestsScreen(),
        '/citizen-feed': (context) => const CitizenFeedScreen(),
        '/report': (context) => const ReportProblemScreen(),
        '/message': (context) => const MessageHomepage(),
        '/emergency': (context) => const EmergencyNumbersScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/governmentProblemReports': (context) =>
            const GovernmentProblemReportsScreen(),
      },
    );
  }
}
