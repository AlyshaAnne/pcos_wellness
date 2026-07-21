import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isUpdatingFollow = false;

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  bool get _isOwnProfile {
    final currentUser = FirebaseAuth.instance.currentUser;

    return currentUser != null &&
        currentUser.uid == widget.userId;
  }

  DocumentReference<Map<String, dynamic>> _userReference(
      String userId,
      ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream() {
    return _userReference(widget.userId).snapshots();
  }

  Stream<String> _relationshipStatusStream() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || _isOwnProfile) {
      return Stream<String>.value('none');
    }

    final followingReference = _userReference(currentUser.uid)
        .collection('following')
        .doc(widget.userId);

    final requestReference = _userReference(widget.userId)
        .collection('followRequests')
        .doc(currentUser.uid);

    return followingReference.snapshots().asyncMap(
          (followingSnapshot) async {
        if (followingSnapshot.exists) {
          return 'following';
        }

        final requestSnapshot = await requestReference.get();

        if (requestSnapshot.exists) {
          final requestData = requestSnapshot.data() ?? {};
          final status = requestData['status']?.toString();

          if (status == 'pending') {
            return 'requested';
          }
        }

        return 'none';
      },
    );
  }

  Future<void> _handleRelationshipAction({
    required String relationshipStatus,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Please log in to follow community members.',
        isError: true,
      );
      return;
    }

    if (_isOwnProfile) {
      return;
    }

    setState(() {
      _isUpdatingFollow = true;
    });

    try {
      final currentUserSnapshot =
      await _userReference(currentUser.uid).get();

      final targetUserSnapshot =
      await _userReference(widget.userId).get();

      if (!targetUserSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'This user profile no longer exists.',
        );
      }

      final currentUserData = currentUserSnapshot.data() ?? {};
      final targetUserData = targetUserSnapshot.data() ?? {};

      final currentUserName = _text(
        currentUserData['fullName'],
        fallback:
        currentUser.displayName ?? 'Community Member',
      );

      final currentUserImage = _text(
        currentUserData['profileImageUrl'],
        fallback: currentUser.photoURL ?? '',
      );

      final targetUserName = _text(
        targetUserData['fullName'],
        fallback: 'Community Member',
      );

      final followingReference = _userReference(currentUser.uid)
          .collection('following')
          .doc(widget.userId);

      final followerReference = _userReference(widget.userId)
          .collection('followers')
          .doc(currentUser.uid);

      final requestReference = _userReference(widget.userId)
          .collection('followRequests')
          .doc(currentUser.uid);

      final batch = FirebaseFirestore.instance.batch();

      if (relationshipStatus == 'following') {
        batch.delete(followingReference);
        batch.delete(followerReference);
      } else if (relationshipStatus == 'requested') {
        batch.delete(requestReference);
      } else {
        batch.set(
          requestReference,
          {
            'requesterId': currentUser.uid,
            'requesterName': currentUserName,
            'requesterProfileImageUrl':
            currentUserImage == '-' ? '' : currentUserImage,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;

      if (relationshipStatus == 'following') {
        _showMessage(
          'You unfollowed $targetUserName.',
          isError: false,
        );
      } else if (relationshipStatus == 'requested') {
        _showMessage(
          'Follow request cancelled.',
          isError: false,
        );
      } else {
        _showMessage(
          'Follow request sent to $targetUserName.',
          isError: false,
        );
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ??
            'The follow request could not be updated.',
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFollow = false;
        });
      }
    }
  }

  void _showMessage(
      String message, {
        required bool isError,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : AppColors.petalRouge,
      ),
    );
  }

  Widget _profileAvatar({
    required String name,
    required String imageUrl,
  }) {
    if (imageUrl.isNotEmpty && imageUrl != '-') {
      return CircleAvatar(
        radius: 58,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial =
    name.trim().isEmpty ? '?' : name.trim()[0];

    return CircleAvatar(
      radius: 58,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
  }

  Widget _buildSocialStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _userReference(widget.userId)
                  .collection('followers')
                  .snapshots(),
              builder: (context, snapshot) {
                final followerCount =
                    snapshot.data?.docs.length ?? 0;

                return _socialStat(
                  count: followerCount,
                  label: 'Followers',
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: AppColors.petalFrost,
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _userReference(widget.userId)
                  .collection('following')
                  .snapshots(),
              builder: (context, snapshot) {
                final followingCount =
                    snapshot.data?.docs.length ?? 0;

                return _socialStat(
                  count: followingCount,
                  label: 'Following',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialStat({
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.petalRouge,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    if (_isOwnProfile) {
      return Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.petalFrost,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Text(
          'This is your profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.petalRouge,
          ),
        ),
      );
    }

    return StreamBuilder<String>(
      stream: _relationshipStatusStream(),
      builder: (context, snapshot) {
        final relationshipStatus =
            snapshot.data ?? 'none';

        final currentlyFollowing =
            relationshipStatus == 'following';

        final requestPending =
            relationshipStatus == 'requested';

        final outlinedState =
            currentlyFollowing || requestPending;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isUpdatingFollow
                ? null
                : () {
              _handleRelationshipAction(
                relationshipStatus: relationshipStatus,
              );
            },
            icon: _isUpdatingFollow
                ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(
              currentlyFollowing
                  ? Icons.person_remove_rounded
                  : requestPending
                  ? Icons.schedule_rounded
                  : Icons.person_add_rounded,
            ),
            label: Text(
              _isUpdatingFollow
                  ? 'Updating...'
                  : currentlyFollowing
                  ? 'Following'
                  : requestPending
                  ? 'Requested'
                  : 'Follow',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: outlinedState
                  ? Colors.white
                  : AppColors.petalRouge,
              foregroundColor: outlinedState
                  ? AppColors.petalRouge
                  : Colors.white,
              side: const BorderSide(
                color: AppColors.petalRouge,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicInformation(
      Map<String, dynamic> data,
      ) {
    final bio = _text(
      data['bio'],
      fallback:
      'This community member has not added a bio yet.',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(
        color: AppColors.petalFrost,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About 💗',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.darkText,
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
      color: color.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.petalFrost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Community Profile'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream(),
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
                'This profile could not be loaded.',
                style: TextStyle(
                  color: AppColors.greyText,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'This user profile no longer exists.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final fullName = _text(
            data['fullName'],
            fallback: 'Community Member',
          );

          final profileImageUrl = _text(
            data['profileImageUrl'],
            fallback: '',
          );

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    36,
                    28,
                    36,
                  ),
                  child: Column(
                    children: [
                      _profileAvatar(
                        name: fullName,
                        imageUrl: profileImageUrl,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PCOS Wellness Community Member',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildSocialStats(),
                      const SizedBox(height: 18),
                      _buildFollowButton(),
                      const SizedBox(height: 18),
                      _buildPublicInformation(data),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
