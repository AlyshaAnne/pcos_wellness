import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../daily_log/daily_log_screen.dart';
import '../food/food_screen.dart';
import '../cycle/cycle_screen.dart';
import '../insights/insights_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static void _go(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PCOS Wellness",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.petalRouge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Track your cycle, symptoms, food, and wellness progress.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.petalFrost,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Focus",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Log your mood, meals, cycle, and symptoms for better insights.",
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _DashboardCard(
                    title: "Daily Log",
                    subtitle: "Mood, sleep, water, stress and weight",
                    icon: Icons.edit_note_rounded,
                    onTap: () => _go(context, const DailyLogScreen()),
                  ),
                  _DashboardCard(
                    title: "Food Tracker",
                    subtitle: "Meals, snacks and PCOS-friendly notes",
                    icon: Icons.restaurant_rounded,
                    onTap: () => _go(context, const FoodScreen()),
                  ),
                  _DashboardCard(
                    title: "Cycle Tracker",
                    subtitle: "Period dates, cycle length and notes",
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _go(context, const CycleScreen()),
                  ),
                  _DashboardCard(
                    title: "Insights",
                    subtitle: "View your trends and graphs",
                    icon: Icons.show_chart_rounded,
                    onTap: () => _go(context, const InsightsScreen()),
                  ),
                  _DashboardCard(
                    title: "Profile",
                    subtitle: "Manage your account and preferences",
                    icon: Icons.person_rounded,
                    onTap: () => _go(context, const ProfileScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.petalFrost),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: AppColors.darkText,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}