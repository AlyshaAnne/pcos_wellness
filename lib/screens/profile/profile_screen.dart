import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../achievements/achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  String _text(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: AppColors.petalRouge,
                  );
                }

                final data = snapshot.data?.data() ?? {};

                final fullName = _text(data['fullName']);
                final email = user?.email ?? _text(data['email']);
                final dob = _text(data['dob']);
                final height = _text(data['height']);
                final weight = _text(data['weight']);
                final pcosDiagnosed = _text(data['pcosDiagnosed']);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 42, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.petalFrost,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.petalRouge,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 64,
                            color: AppColors.petalRouge,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Center(
                        child: Text(
                          fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.greyText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Details 💗',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _profileRow('Full Name', fullName),
                            _profileRow('Email', email),
                            _profileRow('Date of Birth', dob),
                            _profileRow('Height', '$height cm'),
                            _profileRow('Weight', '$weight kg'),
                            _profileRow('PCOS Diagnosed', pcosDiagnosed),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: _cardDecoration(color: AppColors.petalFrost),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Badges 🏆',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _badgePreview('🌱', 'First Log'),
                                _badgePreview('💧', 'Hydration'),
                                _badgePreview('🌸', 'Cycle'),
                                _badgePreview('🤝', 'Community'),
                              ],
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const AchievementsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.emoji_events_rounded),
                                label: const Text('View All Achievements'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.petalRouge,
                                  side: const BorderSide(
                                    color: AppColors.petalRouge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: _cardDecoration(color: AppColors.petalFrost),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Note ✨',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Your logs are saved securely under your account. Your insights are generated from your daily, food, and cycle tracking data.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.petalRouge,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgePreview(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.petalRouge),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.greyText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.petalFrost),
    );
  }
}