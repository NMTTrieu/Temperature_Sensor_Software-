import 'package:flutter/material.dart';
import 'dart:async';

import 'telemetry_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay 2 giây rồi chuyển sang TelemetryListScreen
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelemetryListScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // có thể đổi màu
      body: Center(
        child: Image.asset('assets/images/tl.webp', width: 160, height: 160),
      ),
    );
  }
}
