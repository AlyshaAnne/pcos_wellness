import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../achievements/achievements_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart';
import 'follow_requests_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String _measurement(
      dynamic value,
      String unit,
      ) {
    final text = _text(value);

    if (text == '-') {
      return '-';
    }

    return '$text $unit';
  }

  Widget _profileAvatar({
    required String fullName,
    required String profileImageUrl,
  }) {
    if (profileImageUrl.isNotEmpty && profileImageUrl != '-') {
      return CircleAvatar(
        radius: 55,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(profileImageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial = fullName.trim().isEmpty
        ? '?'
        : fullName.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 55,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
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
      body: user == null
          ? const Center(
        child: Text(
          'Please log in to view your profile.',
          style: TextStyle(
            color: AppColors.greyText,
          ),
        ),
      )
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: StreamBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.petalRouge,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Your profile could not be loaded.',
                      style: TextStyle(
                        color: AppColors.greyText,
                      ),
                    ),
                  );
                }

                final data = snapshot.data?.data() ?? {};

                final fullName = _text(
                  data['fullName'],
                  fallback:
                  user.displayName ?? 'Community Member',
                );

                final email = user.email ??
                    _text(data['email']);

                final dob = _text(data['dob']);

                final height = _measurement(
                  data['height'],
                  'cm',
                );

                final weight = _measurement(
                  data['weight'],
                  'kg',
                );

                final pcosDiagnosed = _text(
                  data['pcosDiagnosed'],
                  fallback: 'No',
                );

                final bio = _text(
                  data['bio'],
                  fallback: 'No bio added yet.',
                );

                final profileImageUrl = _text(
                  data['profileImageUrl'],
                  fallback: '',
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    42,
                    28,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.petalRouge,
                              width: 2,
                            ),
                          ),
                          child: _profileAvatar(
                            fullName: fullName,
                            profileImageUrl:
                            profileImageUrl,
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
                                const EditProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_rounded,
                          ),
                          label: const Text(
                            'Edit Profile',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            AppColors.petalRouge,
                            side: const BorderSide(
                              color:
                              AppColors.petalRouge,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),
                            ),
                            textStyle:
                            const TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildSocialStats(
                        context: context,
                        userId: user.uid,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons
                                .person_add_alt_1_rounded,
                          ),
                          label: const Text(
                            'Follow Requests',
                          ),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.petalRouge,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),
                            ),
                            textStyle:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const FollowRequestsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(22),
                        decoration:
                        _cardDecoration(),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Details 💗',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.w900,
                                color:
                                AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _profileRow(
                              'Full Name',
                              fullName,
                            ),
                            _profileRow(
                              'Email',
                              email,
                            ),
                            _profileRow(
                              'Date of Birth',
                              dob,
                            ),
                            _profileRow(
                              'Height',
                              height,
                            ),
                            _profileRow(
                              'Weight',
                              weight,
                            ),
                            _profileRow(
                              'PCOS Diagnosed',
                              pcosDiagnosed,
                            ),
                            _profileRow(
                              'Bio',
                              bio,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(22),
                        decoration: _cardDecoration(
                          color:
                          AppColors.petalFrost,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Badges 🏆',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.w900,
                                color:
                                AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection:
                              Axis.horizontal,
                              child: Row(
                                children: [
                                  _badgePreview(
                                    '🌱',
                                    'First Log',
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  _badgePreview(
                                    '💧',
                                    'Hydration',
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  _badgePreview(
                                    '🌸',
                                    'Cycle',
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  _badgePreview(
                                    '🤝',
                                    'Community',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child:
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const AchievementsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons
                                      .emoji_events_rounded,
                                ),
                                label: const Text(
                                  'View All Achievements',
                                ),
                                style:
                                OutlinedButton.styleFrom(
                                  foregroundColor:
                                  AppColors
                                      .petalRouge,
                                  side:
                                  const BorderSide(
                                    color: AppColors
                                        .petalRouge,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      16,
                                    ),
                                  ),
                                  textStyle:
                                  const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.w800,
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
                        padding:
                        const EdgeInsets.all(22),
                        decoration: _cardDecoration(
                          color:
                          AppColors.petalFrost,
                        ),
                        child: const Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Note ✨',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.w900,
                                color:
                                AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Your logs are saved securely under your account. Your insights are generated from your daily, food, and cycle tracking data.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color:
                                AppColors.darkText,
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
                          onPressed: () =>
                              _logout(context),
                          icon: const Icon(
                            Icons.logout_rounded,
                          ),
                          label:
                          const Text('Logout'),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.petalRouge,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                            ),
                            textStyle:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w800,
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

  Widget _buildSocialStats({
    required BuildContext context,
    required String userId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      decoration: _cardDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListScreen(
                      userId: userId,
                      listType: 'followers',
                    ),
                  ),
                );
              },
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('followers')
                    .snapshots(),
                builder: (context, snapshot) {
                  final followerCount =
                      snapshot.data?.docs.length ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$followerCount',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Followers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            AppColors.petalRouge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color: AppColors.petalFrost,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListScreen(
                      userId: userId,
                      listType: 'following',
                    ),
                  ),
                );
              },
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('following')
                    .snapshots(),
                builder: (context, snapshot) {
                  final followingCount =
                      snapshot.data?.docs.length ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$followingCount',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Following',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            AppColors.petalRouge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgePreview(
      String emoji,
      String label,
      ) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.petalRouge,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 26,
              ),
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

  Widget _profileRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
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

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.petalFrost,
      ),
    );
  }
}
