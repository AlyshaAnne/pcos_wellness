import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  final List<Map<String, dynamic>> badges = const [
    {
      'emoji': '🌱',
      'title': 'First Log',
      'description': 'Complete your first daily wellness log.',
      'unlocked': true,
    },
    {
      'emoji': '💧',
      'title': 'Hydration Hero',
      'description': 'Reach your water goal multiple times.',
      'unlocked': true,
    },
    {
      'emoji': '🌸',
      'title': 'Cycle Tracker',
      'description': 'Record your first cycle log.',
      'unlocked': true,
    },
    {
      'emoji': '🤝',
      'title': 'Community Starter',
      'description': 'Create your first community post.',
      'unlocked': false,
    },
    {
      'emoji': '🏃',
      'title': 'Activity Joiner',
      'description': 'Join your first community activity.',
      'unlocked': false,
    },
    {
      'emoji': '🥗',
      'title': 'Meal Logger',
      'description': 'Record food logs consistently.',
      'unlocked': false,
    },
    {
      'emoji': '😴',
      'title': 'Sleep Supporter',
      'description': 'Log healthy sleep habits.',
      'unlocked': false,
    },
    {
      'emoji': '👑',
      'title': 'Wellness Champion',
      'description': 'Use all major app features.',
      'unlocked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unlockedCount =
        badges.where((badge) => badge['unlocked'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Achievements 🏆',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$unlockedCount / ${badges.length} badges unlocked',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 22),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: badges.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      return _badgeCard(
                        emoji: badge['emoji'],
                        title: badge['title'],
                        description: badge['description'],
                        unlocked: badge['unlocked'],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeCard({
    required String emoji,
    required String title,
    required String description,
    required bool unlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked ? AppColors.petalRouge : AppColors.petalFrost,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unlocked ? emoji : '🔒',
            style: const TextStyle(fontSize: 34),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: unlocked ? AppColors.darkText : AppColors.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unlocked ? description : 'Locked achievement',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}