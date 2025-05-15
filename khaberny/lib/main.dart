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
      },
    );
  }
}
