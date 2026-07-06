import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

import '../../theme/app_theme.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pcos_app_logo.png',
              width: 180,
            ),

            const SizedBox(height: 24),

            const Text(
              'PCOS Wellness',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.petalRouge,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Your cycle, symptoms, and wellness in one place',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),

            const SizedBox(height: 32),

            const CircularProgressIndicator(
              color: AppColors.petalRouge,
            ),
          ],
        ),
      ),
    );
  }
}