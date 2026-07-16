import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import 'create_activity_screen.dart';
import 'create_post_screen.dart';
import 'leaderboard_screen.dart';
import 'my_activities_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTab = 0;

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
    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  String _formatTimeAgo(dynamic value) {
    final date = _date(value);

    if (date == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat('d MMM yyyy').format(date);
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'exercise':
      case 'running':
        return '🏃';

      case 'nutrition':
      case 'food':
        return '🥗';

      case 'symptoms':
        return '🩺';

      case 'cycle':
        return '🌸';

      case 'sleep':
        return '😴';

      case 'mental wellness':
        return '🧠';

      case 'motivation':
        return '💗';

      case 'question':
        return '❓';

      case 'achievement':
        return '🏆';

      case 'wellness tip':
        return '✨';

      case 'walking':
        return '🚶';

      case 'yoga':
        return '🧘';

      case 'gym':
        return '🏋️';

      case 'cycling':
        return '🚴';

      case 'swimming':
        return '🏊';

      case 'dance':
        return '💃';

      case 'hiking':
        return '🥾';

      case 'wellness meetup':
        return '🤝';

      default:
        return '🌷';
    }
  }

  Future<Map<String, dynamic>> _currentUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {};
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snapshot.data() ?? {};
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _selectedTab = 0;
      });
    }
  }

  Future<void> _openCreateActivity() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateActivityScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _selectedTab = 1;
      });
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),
          decoration: const BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.greyText.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Something ✨',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share your journey or organise an activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 22),
                _createOption(
                  icon: Icons.edit_rounded,
                  title: 'Create Post',
                  subtitle: 'Share progress, advice or a question',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openCreatePost();
                  },
                ),
                const SizedBox(height: 14),
                _createOption(
                  icon: Icons.directions_run_rounded,
                  title: 'Create Activity',
                  subtitle: 'Organise an activity others can join',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openCreateActivity();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _createOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.petalFrost,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.petalFrost,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.petalRouge,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike({
    required String postId,
    required Map<String, dynamic> post,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to like posts.');
      return;
    }

    final postReference = FirebaseFirestore.instance
        .collection('communityPosts')
        .doc(postId);

    try {
      await FirebaseFirestore.instance.runTransaction(
            (transaction) async {
          final snapshot = await transaction.get(postReference);

          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'This post no longer exists.',
            );
          }

          final latestData = snapshot.data() ?? {};
          final likedBy = _stringList(latestData['likedBy']);

          if (likedBy.contains(user.uid)) {
            likedBy.remove(user.uid);
          } else {
            likedBy.add(user.uid);
          }

          transaction.update(postReference, {
            'likedBy': likedBy,
            'likeCount': likedBy.length,
          });
        },
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ?? 'Could not update the like.',
      );
    }
  }

  Future<void> _toggleSave({
    required String postId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to save posts.');
      return;
    }

    final postReference = FirebaseFirestore.instance
        .collection('communityPosts')
        .doc(postId);

    try {
      await FirebaseFirestore.instance.runTransaction(
            (transaction) async {
          final snapshot = await transaction.get(postReference);

          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'This post no longer exists.',
            );
          }

          final data = snapshot.data() ?? {};
          final savedBy = _stringList(data['savedBy']);

          if (savedBy.contains(user.uid)) {
            savedBy.remove(user.uid);
          } else {
            savedBy.add(user.uid);
          }

          transaction.update(postReference, {
            'savedBy': savedBy,
          });
        },
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ?? 'Could not save the post.',
      );
    }
  }

  Future<void> _addComment({
    required String postId,
    required TextEditingController controller,
    required BuildContext bottomSheetContext,
  }) async {
    final commentText = controller.text.trim();

    if (commentText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to comment.');
      return;
    }

    try {
      final userData = await _currentUserData();

      final fullName = _text(
        userData['fullName'],
        fallback: user.displayName ?? 'Community Member',
      );

      final profileImageUrl = _text(
        userData['profileImageUrl'],
        fallback: user.photoURL ?? '',
      );

      final postReference = FirebaseFirestore.instance
          .collection('communityPosts')
          .doc(postId);

      final commentReference =
      postReference.collection('comments').doc();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(commentReference, {
        'authorId': user.uid,
        'authorName': fullName,
        'authorProfileImageUrl':
        profileImageUrl == '-' ? '' : profileImageUrl,
        'text': commentText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(postReference, {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();

      controller.clear();

      if (!bottomSheetContext.mounted) return;

      FocusScope.of(bottomSheetContext).unfocus();
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ?? 'Could not add the comment.',
      );
    }
  }

  void _showComments({
    required String postId,
  }) {
    final commentController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
            MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(bottomSheetContext).size.height *
                0.72,
            padding: const EdgeInsets.fromLTRB(
              22,
              16,
              22,
              22,
            ),
            decoration: const BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.greyText.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Comments 💬',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('communityPosts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy(
                      'createdAt',
                      descending: false,
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
                            'Comments could not be loaded.',
                            style: TextStyle(
                              color: AppColors.greyText,
                            ),
                          ),
                        );
                      }

                      final comments = snapshot.data?.docs ?? [];

                      if (comments.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '💬',
                                style: TextStyle(fontSize: 46),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.darkText,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Be the first to leave some support.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final data = comments[index].data();

                          return _commentTile(data);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  textCapitalization:
                  TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      onPressed: () {
                        _addComment(
                          postId: postId,
                          controller: commentController,
                          bottomSheetContext:
                          bottomSheetContext,
                        );
                      },
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.petalRouge,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _commentTile(Map<String, dynamic> data) {
    final name = _text(
      data['authorName'],
      fallback: 'Community Member',
    );

    final profileImageUrl = _text(
      data['authorProfileImageUrl'],
      fallback: '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _profileAvatar(
            name: name,
            imageUrl:
            profileImageUrl == '-' ? '' : profileImageUrl,
            radius: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimeAgo(data['createdAt']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _text(
                      data['text'],
                      fallback: '',
                    ),
                    style: const TextStyle(
                      height: 1.4,
                      color: AppColors.darkText,
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

  Future<void> _toggleJoinActivity({
    required String activityId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to join activities.');
      return;
    }

    final reference = FirebaseFirestore.instance
        .collection('communityActivities')
        .doc(activityId);

    try {
      bool joinedAfterUpdate = false;

      await FirebaseFirestore.instance.runTransaction(
            (transaction) async {
          final snapshot = await transaction.get(reference);

          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'This activity no longer exists.',
            );
          }

          final data = snapshot.data() ?? {};
          final hostId = _text(
            data['hostId'],
            fallback: '',
          );

          final participantIds =
          _stringList(data['participantIds']);

          final maxParticipants =
          _number(data['maxParticipants']);

          final alreadyJoined =
          participantIds.contains(user.uid);

          if (alreadyJoined) {
            if (hostId == user.uid) {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                message:
                'Hosts cannot leave their own activity.',
              );
            }

            participantIds.remove(user.uid);
            joinedAfterUpdate = false;
          } else {
            if (maxParticipants > 0 &&
                participantIds.length >= maxParticipants) {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                message: 'This activity is already full.',
              );
            }

            participantIds.add(user.uid);
            joinedAfterUpdate = true;
          }

          transaction.update(reference, {
            'participantIds': participantIds,
            'participantCount': participantIds.length,
          });
        },
      );

      if (joinedAfterUpdate) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'weeklyXp': FieldValue.increment(15),
          'monthlyXp': FieldValue.increment(15),
          'totalXp': FieldValue.increment(15),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ?? 'Could not update the activity.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'My Activities',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const MyActivitiesScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.event_available_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCommunityStats(),
                  const SizedBox(height: 20),
                  _buildChallengeCard(),
                  const SizedBox(height: 22),
                  _buildTabs(),
                  const SizedBox(height: 20),
                  if (_selectedTab == 0) _buildFeed(),
                  if (_selectedTab == 1) _buildActivities(),
                  if (_selectedTab == 2) _buildSavedPosts(),
                  if (_selectedTab == 3) _buildLeaderboardPreview(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>>(
      future: _currentUserData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};

        final fullName = _text(
          data['fullName'],
          fallback: user?.displayName ?? 'Community Member',
        );

        final firstName = fullName == '-'
            ? 'there'
            : fullName.split(' ').first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.petalFrost,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
              AppColors.petalRouge.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $firstName 👋',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.petalRouge,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wellness Community 💗',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your progress, find activities and support others on their wellness journey.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityStats() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>>(
      future: _currentUserData(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data ?? {};
        final streak =
        _number(userData['currentStreak']);

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('communityActivities')
              .snapshots(),
          builder: (context, activitySnapshot) {
            final activityCount =
                activitySnapshot.data?.docs.length ?? 0;

            return StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, usersSnapshot) {
                int rank = 0;

                if (user != null &&
                    usersSnapshot.hasData) {
                  final users = [
                    ...usersSnapshot.data!.docs,
                  ];

                  users.sort(
                        (first, second) => _number(
                      second.data()['totalXp'],
                    ).compareTo(
                      _number(
                        first.data()['totalXp'],
                      ),
                    ),
                  );

                  final index = users.indexWhere(
                        (document) =>
                    document.id == user.uid,
                  );

                  if (index >= 0) {
                    rank = index + 1;
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        emoji: '🔥',
                        number: '$streak',
                        label: 'Day streak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        emoji: '🏃',
                        number: '$activityCount',
                        label: 'Activities',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        emoji: '🏆',
                        number:
                        rank > 0 ? '#$rank' : '-',
                        label: 'Your rank',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required String emoji,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 25),
          ),
          const SizedBox(height: 6),
          Text(
            number,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD978),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Weekly Challenge',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Move for 30 minutes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete this goal four times this week.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 12,
              backgroundColor: Colors.white54,
              color: AppColors.petalRouge,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2 of 4 completed',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                '+40 XP',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.petalRouge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const labels = [
      'Feed',
      'Activities',
      'Saved',
      'Leaderboard',
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(
          labels.length,
              (index) {
            final selected = _selectedTab == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.petalRouge
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: Text(
                    labels[index],
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

  Widget _buildFeed() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communityPosts')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.petalRouge,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Posts could not be loaded.\n${snapshot.error}',
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return _emptyCard(
            emoji: '💬',
            title: 'No Posts Yet',
            message:
            'Be the first person to share something with the community.',
            buttonLabel: 'Create First Post',
            onPressed: _openCreatePost,
          );
        }

        return Column(
          children: posts.map((document) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostCard(
                postId: document.id,
                post: document.data(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPostCard({
    required String postId,
    required Map<String, dynamic> post,
  }) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    final authorName = _text(
      post['authorName'],
      fallback: 'Community Member',
    );

    final profileImageUrl = _text(
      post['authorProfileImageUrl'],
      fallback: '',
    );

    final category = _text(
      post['category'],
      fallback: 'Community',
    );

    final mood = _text(
      post['mood'],
      fallback: '',
    );

    final imageUrl = _text(
      post['imageUrl'],
      fallback: '',
    );

    final likedBy = _stringList(post['likedBy']);
    final savedBy = _stringList(post['savedBy']);

    final liked = currentUser != null &&
        likedBy.contains(currentUser.uid);

    final saved = currentUser != null &&
        savedBy.contains(currentUser.uid);

    final likeCount =
    _number(post['likeCount']) > 0
        ? _number(post['likeCount'])
        : likedBy.length;

    final commentCount =
    _number(post['commentCount']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              0,
            ),
            child: Row(
              children: [
                _profileAvatar(
                  name: authorName,
                  imageUrl: profileImageUrl == '-'
                      ? ''
                      : profileImageUrl,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatTimeAgo(post['createdAt'])} · $category',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _categoryEmoji(category),
                  style: const TextStyle(fontSize: 27),
                ),
              ],
            ),
          ),
          if (mood.isNotEmpty && mood != '-') ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.petalFrost,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Feeling $mood',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              _text(
                post['text'],
                fallback: '',
              ),
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.darkText,
              ),
            ),
          ),
          if (imageUrl.isNotEmpty && imageUrl != '-') ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(0),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _FullScreenImageViewer(
                          imageUrl: imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      debugPrint('==================================');
                      debugPrint('IMAGE ERROR:');
                      debugPrint(error.toString());
                      debugPrint('IMAGE URL:');
                      debugPrint(imageUrl);
                      debugPrint('==================================');

                      return Container(
                        color: AppColors.petalFrost,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: AppColors.greyText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              12,
            ),
            child: Column(
              children: [
                const Divider(
                  color: AppColors.petalFrost,
                ),
                Row(
                  children: [
                    _postAction(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '$likeCount',
                      selected: liked,
                      onTap: () {
                        _toggleLike(
                          postId: postId,
                          post: post,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _postAction(
                      icon:
                      Icons.chat_bubble_outline_rounded,
                      label: '$commentCount',
                      onTap: () {
                        _showComments(
                          postId: postId,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _postAction(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () async {
                        final postText = _text(
                          post['text'],
                          fallback: '',
                        );

                        final shareText = imageUrl.isNotEmpty && imageUrl != '-'
                            ? '$postText\n\n$imageUrl'
                            : postText;

                        await Share.share(
                          shareText,
                          subject: 'PCOS Wellness Community Post',
                        );
                      },
                    ),
                    const Spacer(),

                    if (currentUser?.uid == post['authorId'])
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Delete',
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('communityPosts')
                              .doc(postId)
                              .delete();
                        },
                      ),

                    IconButton(
                      tooltip:
                      saved ? 'Unsave post' : 'Save post',
                      onPressed: () {
                        _toggleSave(
                          postId: postId,
                        );
                      },
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: saved
                            ? AppColors.petalRouge
                            : AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar({
    required String name,
    required String imageUrl,
    required double radius,
  }) {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial =
    name.trim().isEmpty ? '?' : name.trim()[0];

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
  }

  Widget _postAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected
                  ? AppColors.petalRouge
                  : AppColors.greyText,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.petalRouge
                    : AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const MyActivitiesScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.event_available_rounded,
            ),
            label: const Text('View My Activities'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.petalRouge,
              side: const BorderSide(
                color: AppColors.petalRouge,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('communityActivities')
              .orderBy(
            'startDateTime',
            descending: false,
          )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.petalRouge,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return _errorCard(
                'Activities could not be loaded.\n${snapshot.error}',
              );
            }

            final activities =
                snapshot.data?.docs.where((document) {
                  final data = document.data();

                  final startDate =
                      _date(data['startDateTime']) ??
                          _date(data['activityDate']);

                  if (startDate == null) return true;

                  return startDate.isAfter(
                    DateTime.now().subtract(
                      const Duration(hours: 3),
                    ),
                  );
                }).toList() ??
                    [];

            if (activities.isEmpty) {
              return _emptyCard(
                emoji: '🏃',
                title: 'No Upcoming Activities',
                message:
                'Create an activity and invite the community to join.',
                buttonLabel: 'Create Activity',
                onPressed: _openCreateActivity,
              );
            }

            return Column(
              children: activities.map((document) {
                return Padding(
                  padding:
                  const EdgeInsets.only(bottom: 16),
                  child: _buildActivityCard(
                    activityId: document.id,
                    activity: document.data(),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String activityId,
    required Map<String, dynamic> activity,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    final category = _text(
      activity['category'],
      fallback: 'Activity',
    );

    final participantIds =
    _stringList(activity['participantIds']);

    final maxParticipants =
    _number(activity['maxParticipants']);

    final joined = user != null &&
        participantIds.contains(user.uid);

    final full = maxParticipants > 0 &&
        participantIds.length >= maxParticipants;

    final startDate =
        _date(activity['startDateTime']) ??
            _date(activity['activityDate']);

    final endDate =
    _date(activity['endDateTime']);

    final dateLabel = startDate == null
        ? 'Date not available'
        : DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(startDate);

    String timeLabel;

    final storedStartTime = _text(
      activity['startTimeLabel'],
      fallback: '',
    );

    final storedEndTime = _text(
      activity['endTimeLabel'],
      fallback: '',
    );

    if (storedStartTime.isNotEmpty &&
        storedEndTime.isNotEmpty) {
      timeLabel = '$storedStartTime – $storedEndTime';
    } else if (startDate != null && endDate != null) {
      timeLabel =
      '${DateFormat('h:mm a').format(startDate)} – '
          '${DateFormat('h:mm a').format(endDate)}';
    } else if (startDate != null) {
      timeLabel =
          DateFormat('h:mm a').format(startDate);
    } else {
      timeLabel = 'Time not available';
    }

    final progress = maxParticipants <= 0
        ? 0.0
        : (participantIds.length / maxParticipants)
        .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6A9),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(category),
                    style: const TextStyle(fontSize: 28),
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
                      _text(
                        activity['title'],
                        fallback: 'Community Activity',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.petalRouge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _activityInfo(
            Icons.calendar_month_rounded,
            dateLabel,
          ),
          _activityInfo(
            Icons.access_time_rounded,
            timeLabel,
          ),
          _activityInfo(
            Icons.location_on_rounded,
            _text(
              activity['location'],
              fallback: 'Location not specified',
            ),
          ),
          _activityInfo(
            Icons.person_rounded,
            'Hosted by ${_text(
              activity['hostName'],
              fallback: 'Community Member',
            )}',
          ),
          const SizedBox(height: 12),
          Text(
            '${participantIds.length}'
                '${maxParticipants > 0 ? ' / $maxParticipants' : ''} '
                'participants',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white60,
              color: AppColors.petalRouge,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: full && !joined
                  ? null
                  : () {
                _toggleJoinActivity(
                  activityId: activityId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: joined
                    ? Colors.white
                    : AppColors.petalRouge,
                foregroundColor: joined
                    ? AppColors.petalRouge
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
              ),
              child: Text(
                full && !joined
                    ? 'Activity Full'
                    : joined
                    ? 'Joined ✓'
                    : 'Join Activity',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityInfo(
      IconData icon,
      String text,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.petalRouge,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSavedPosts() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _emptyCard(
        emoji: '🔖',
        title: 'Login Required',
        message: 'Please log in to view your saved posts.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communityPosts')
          .where(
        'savedBy',
        arrayContains: user.uid,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _errorCard('Unable to load saved posts.');
        }

        final posts = snapshot.data?.docs ?? [];
        posts.sort((first, second) {
          final firstTimestamp =
          first.data()['createdAt'] as Timestamp?;

          final secondTimestamp =
          second.data()['createdAt'] as Timestamp?;

          final firstDate = firstTimestamp?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final secondDate = secondTimestamp?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return secondDate.compareTo(firstDate);
        });

        if (posts.isEmpty) {
          return _emptyCard(
            emoji: '🔖',
            title: 'No Saved Posts',
            message: 'Posts you bookmark will appear here.',
          );
        }

        return Column(
          children: posts.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostCard(
                postId: doc.id,
                post: doc.data(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  Widget _buildLeaderboardPreview() {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.petalRouge,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Leaderboard could not be loaded.',
          );
        }

        final users = [
          ...?snapshot.data?.docs,
        ];

        users.sort(
              (first, second) => _number(
            second.data()['totalXp'],
          ).compareTo(
            _number(
              first.data()['totalXp'],
            ),
          ),
        );

        final topUsers = users.take(4).toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF4D9A88),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                children: [
                  Text(
                    '🏆',
                    style: TextStyle(fontSize: 52),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Community Leaderboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Earn XP by logging, posting and joining activities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (topUsers.isEmpty)
              _emptyCard(
                emoji: '🏆',
                title: 'No Rankings Yet',
                message:
                'Users will appear here after earning XP.',
              )
            else
              ...List.generate(
                topUsers.length,
                    (index) {
                  final document = topUsers[index];
                  final data = document.data();

                  final name = _text(
                    data['fullName'],
                    fallback: 'Community Member',
                  );

                  final profileImageUrl = _text(
                    data['profileImageUrl'],
                    fallback: '',
                  );

                  final medals = [
                    '🥇',
                    '🥈',
                    '🥉',
                    '🌟',
                  ];

                  final isCurrentUser =
                      document.id == currentUser?.uid;

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? AppColors.petalFrost
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(21),
                      border: Border.all(
                        color: isCurrentUser
                            ? AppColors.petalRouge
                            : AppColors.petalFrost,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          medals[index],
                          style:
                          const TextStyle(fontSize: 29),
                        ),
                        const SizedBox(width: 12),
                        _profileAvatar(
                          name: name,
                          imageUrl:
                          profileImageUrl == '-'
                              ? ''
                              : profileImageUrl,
                          radius: 21,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        Text(
                          '${_number(data['totalXp'])} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.petalRouge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const LeaderboardScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.leaderboard_rounded,
                ),
                label:
                const Text('View Full Leaderboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  AppColors.petalRouge,
                  side: const BorderSide(
                    color: AppColors.petalRouge,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyCard({
    required String emoji,
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 54),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.greyText,
            ),
          ),
          if (buttonLabel != null &&
              onPressed != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor:
                AppColors.petalRouge,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('View Image'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (
                context,
                error,
                stackTrace,
                ) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Unable to display this image.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}