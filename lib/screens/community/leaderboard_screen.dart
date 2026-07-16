import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedPeriod = 0;

  final List<String> _periods = const [
    'Weekly',
    'Monthly',
    'All Time',
  ];

  String get _xpField {
    switch (_selectedPeriod) {
      case 0:
        return 'weeklyXp';
      case 1:
        return 'monthlyXp';
      case 2:
        return 'totalXp';
      default:
        return 'totalXp';
    }
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

  int _number(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _calculateLevel(int xp) {
    if (xp <= 0) {
      return 1;
    }

    return (xp ~/ 250) + 1;
  }

  int _xpForNextLevel(int level) {
    return level * 250;
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '⭐';
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD978);
      case 2:
        return const Color(0xFFE9E9E9);
      case 3:
        return const Color(0xFFFFD2A6);
      default:
        return Colors.white;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortUsers(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
      ) {
    final sortedUsers = [...users];

    sortedUsers.sort((first, second) {
      final firstXp = _number(first.data()[_xpField]);
      final secondXp = _number(second.data()[_xpField]);

      return secondXp.compareTo(firstXp);
    });

    return sortedUsers;
  }

  int _findCurrentUserRank(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
      String currentUserId,
      ) {
    final index = users.indexWhere(
          (document) => document.id == currentUserId,
    );

    if (index == -1) {
      return 0;
    }

    return index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 780,
            ),
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
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
                  return _buildErrorState(
                    snapshot.error.toString(),
                  );
                }

                final allUsers = snapshot.data?.docs ?? [];
                final sortedUsers = _sortUsers(allUsers);

                final currentUserRank = currentUser == null
                    ? 0
                    : _findCurrentUserRank(
                  sortedUsers,
                  currentUser.uid,
                );

                QueryDocumentSnapshot<Map<String, dynamic>>?
                currentUserDocument;

                if (currentUser != null) {
                  for (final document in sortedUsers) {
                    if (document.id == currentUser.uid) {
                      currentUserDocument = document;
                      break;
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildPeriodTabs(),
                      const SizedBox(height: 20),

                      if (currentUserDocument != null)
                        _buildCurrentUserCard(
                          rank: currentUserRank,
                          data: currentUserDocument.data(),
                        ),

                      if (currentUserDocument != null)
                        const SizedBox(height: 20),

                      if (sortedUsers.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildTopThree(sortedUsers),
                        const SizedBox(height: 22),
                        const Text(
                          'Community Rankings',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(
                          sortedUsers.length,
                              (index) {
                            final document =
                            sortedUsers[index];

                            return Padding(
                              padding:
                              const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: _buildRankingTile(
                                rank: index + 1,
                                userId: document.id,
                                data: document.data(),
                                currentUserId:
                                currentUser?.uid,
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),
                      _buildHowToEarnXpCard(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF4D9A88),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Column(
        children: [
          Text(
            '🏆',
            style: TextStyle(fontSize: 58),
          ),
          SizedBox(height: 10),
          Text(
            'Community Leaderboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Stay consistent, support others and earn XP.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(
          _periods.length,
              (index) {
            final selected = _selectedPeriod == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.petalRouge
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    _periods[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? Colors.white
                          : AppColors.greyText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard({
    required int rank,
    required Map<String, dynamic> data,
  }) {
    final name = _text(
      data['fullName'],
      fallback: 'You',
    );

    final xp = _number(data[_xpField]);
    final totalXp = _number(data['totalXp']);
    final level = _calculateLevel(totalXp);
    final nextLevelXp = _xpForNextLevel(level);
    final levelProgress =
        (totalXp % 250) / 250;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.petalFrost,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: AppColors.petalRouge,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress ✨',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: Colors.white,
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.petalRouge,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank > 0
                          ? 'Rank #$rank'
                          : 'Not ranked yet',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$xp XP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.petalRouge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                '$totalXp / $nextLevelXp XP',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: AppColors.petalRouge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
      ) {
    final topUsers = users.take(3).toList();

    while (topUsers.length < 3) {
      break;
    }

    if (topUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Top Members',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topUsers.length > 1)
                Expanded(
                  child: _buildPodiumMember(
                    rank: 2,
                    data: topUsers[1].data(),
                    height: 120,
                  ),
                ),
              if (topUsers.length > 1)
                const SizedBox(width: 10),
              Expanded(
                child: _buildPodiumMember(
                  rank: 1,
                  data: topUsers[0].data(),
                  height: 155,
                ),
              ),
              if (topUsers.length > 2)
                const SizedBox(width: 10),
              if (topUsers.length > 2)
                Expanded(
                  child: _buildPodiumMember(
                    rank: 3,
                    data: topUsers[2].data(),
                    height: 105,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumMember({
    required int rank,
    required Map<String, dynamic> data,
    required double height,
  }) {
    final name = _text(
      data['fullName'],
      fallback: 'Member',
    );

    final xp = _number(data[_xpField]);

    return Column(
      children: [
        Text(
          _rankEmoji(rank),
          style: const TextStyle(fontSize: 34),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: rank == 1 ? 32 : 27,
          backgroundColor: AppColors.petalFrost,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: rank == 1 ? 23 : 19,
              fontWeight: FontWeight.w900,
              color: AppColors.petalRouge,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$xp XP',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.petalRouge,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _rankColor(rank),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTile({
    required int rank,
    required String userId,
    required Map<String, dynamic> data,
    required String? currentUserId,
  }) {
    final name = _text(
      data['fullName'],
      fallback: 'Community Member',
    );

    final xp = _number(data[_xpField]);
    final totalXp = _number(data['totalXp']);
    final badges = _number(data['badgeCount']);
    final streak = _number(data['currentStreak']);
    final level = _calculateLevel(totalXp);

    final isCurrentUser = userId == currentUserId;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.petalFrost
            : rank <= 3
            ? _rankColor(rank).withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.petalRouge
              : AppColors.petalFrost,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: rank <= 3
                ? Text(
              _rankEmoji(rank),
              style: const TextStyle(
                fontSize: 28,
              ),
            )
                : Text(
              '#$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.greyText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.petalRouge,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.petalRouge,
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Level $level  •  $badges badges  •  🔥 $streak',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.petalRouge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnXpCard() {
    final xpItems = const [
      {
        'emoji': '📝',
        'title': 'Complete a daily log',
        'xp': '+10 XP',
      },
      {
        'emoji': '🥗',
        'title': 'Complete a food log',
        'xp': '+10 XP',
      },
      {
        'emoji': '🌸',
        'title': 'Complete a cycle log',
        'xp': '+10 XP',
      },
      {
        'emoji': '💬',
        'title': 'Create a community post',
        'xp': '+10 XP',
      },
      {
        'emoji': '🏃',
        'title': 'Join an activity',
        'xp': '+15 XP',
      },
      {
        'emoji': '✨',
        'title': 'Create an activity',
        'xp': '+20 XP',
      },
      {
        'emoji': '🏆',
        'title': 'Complete a challenge',
        'xp': '+40 XP',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6A9),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Earn XP 💫',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          ...xpItems.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Text(
                    item['emoji']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  Text(
                    item['xp']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.petalRouge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '🏆',
            style: TextStyle(fontSize: 58),
          ),
          SizedBox(height: 14),
          Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Leaderboard rankings will appear once users begin earning XP.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.petalFrost,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.red,
              ),
              const SizedBox(height: 14),
              const Text(
                'Could Not Load Leaderboard',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}