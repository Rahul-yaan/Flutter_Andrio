import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
          (){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingPage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.red,

      body: Center(
        child: Text(
          "YAAN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),

    );
  }
}