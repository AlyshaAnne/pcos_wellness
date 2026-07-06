import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: const Center(
        child: Text(
          'Register Screen',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.petalRouge,
          ),
        ),
      ),
    );
  }
}