import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'public_profile_screen.dart';

class FollowListScreen extends StatelessWidget {
  final String userId;
  final String listType;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.listType,
  });

  bool get _showingFollowers => listType == 'followers';

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  Widget _profileAvatar({
    required String name,
    required String imageUrl,
  }) {
    if (imageUrl.isNotEmpty && imageUrl != '-') {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial =
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionName =
    _showingFollowers ? 'followers' : 'following';

    final title =
    _showingFollowers ? 'Followers' : 'Following';

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collectionName)
            .orderBy(
          'followedAt',
          descending: true,
        )
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
                'This list could not be loaded.',
                style: TextStyle(
                  color: AppColors.greyText,
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                margin: const EdgeInsets.all(28),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.petalFrost,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showingFollowers
                          ? Icons.people_outline_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 54,
                      color: AppColors.petalRouge,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _showingFollowers
                          ? 'No Followers Yet'
                          : 'Not Following Anyone Yet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    30,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final data = document.data();

                    final listedUserId = _text(
                      data['userId'],
                      fallback: document.id,
                    );

                    final fullName = _text(
                      data['fullName'],
                      fallback: 'Community Member',
                    );

                    final profileImageUrl = _text(
                      data['profileImageUrl'],
                      fallback: '',
                    );

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.94,
                        ),
                        borderRadius:
                        BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.petalFrost,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicProfileScreen(
                                    userId: listedUserId,
                                  ),
                            ),
                          );
                        },
                        borderRadius:
                        BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _profileAvatar(
                                name: fullName,
                                imageUrl: profileImageUrl,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w900,
                                    color:
                                    AppColors.darkText,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.greyText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}