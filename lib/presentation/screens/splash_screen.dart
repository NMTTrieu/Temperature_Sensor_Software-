import 'dart:async';
import 'package:flutter/material.dart';

import 'package:my_app/notifications/notifier.dart';
import 'package:my_app/presentation/screens/telemetry_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _boot();
  }

  Future<void> _boot() async {
    // Khởi tạo thông báo cục bộ (nhanh, không block lâu)
    await Notifier.init();

    // “Splash time”
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelemetryListScreen()),
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _ac,
              child: Image.asset(
                'assets/images/tl.webp', // bạn đã khai báo trong pubspec.yaml
                width: 160,
                height: 160,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Smart Garden',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
