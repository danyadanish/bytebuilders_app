import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/accountType');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B203D),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خبّرني',
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your Government Companion\nPowered by AI Assistance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6FA8DC),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.horizontal_rule,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}