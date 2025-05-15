import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/account_type_selection_screen.dart';
import 'screens/citizen/citizen_signup_screen.dart';
import 'screens/advertisers/advertiser_signup_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/advertisers/advertiser_home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/advertiser/advertiser_main_screen.dart';
import 'screens/advertiser/my_advertisements_screen.dart';
import 'screens/advertiser/add_advertisement_screen.dart';
import 'screens/advertiser/advertiser_profile_screen.dart';
import 'screens/government/GovernmentHomeScreen.dart';
import 'screens/government/GovernmentMainScreen.dart';
import 'screens/government/GovernmentFeedScreen.dart';
import 'screens/government/approve_ads_screen.dart';
import 'screens/government/create_poll_screen.dart';
import 'screens/government/poll_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
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
        '/citizenHome': (context) => CitizenHomeScreen(),
        '/advertiserHome': (context) => AdvertiserHomeScreen(),
        '/signIn': (context) => SignInScreen(),
        '/advertiser': (context) => const AdvertiserMainScreen(),
        '/createAd': (context) => AddAdvertisementScreen(),
        '/myAds': (context) => MyAdvertisementsScreen(),
        '/profile': (context) => AdvertiserProfileScreen(),
        '/reportOverview': (context) => const Placeholder(),
        '/governmentHome': (context) => const GovernmentHomeScreen(),
        '/governmentHome': (context) => const GovernmentMainScreen(),
        '/government': (context) => const GovernmentFeedScreen(),
        '/approveAds': (context) => const ApproveAdsScreen(),
        '/createPoll': (context) => const CreatePollScreen(),
        '/polls': (context) => const PollListScreen(),
      },
    );
  }
}
