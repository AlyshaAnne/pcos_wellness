import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'public_profile_screen.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({
    super.key,
  });

  @override
  State<FollowRequestsScreen> createState() =>
      _FollowRequestsScreenState();
}

class _FollowRequestsScreenState
    extends State<FollowRequestsScreen> {
  final Set<String> _processingRequestIds = {};

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>?
  get _followRequestsReference {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('followRequests');
  }

  DocumentReference<Map<String, dynamic>> _userReference(
      String userId,
      ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId);
  }

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  Future<void> _acceptRequest({
    required String requesterId,
    required Map<String, dynamic> requestData,
  }) async {
    final currentUser = _currentUser;

    if (currentUser == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    if (_processingRequestIds.contains(requesterId)) {
      return;
    }

    setState(() {
      _processingRequestIds.add(requesterId);
    });

    try {
      final currentUserSnapshot =
      await _userReference(currentUser.uid).get();

      final requesterSnapshot =
      await _userReference(requesterId).get();

      if (!requesterSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message:
          'The requesting user profile no longer exists.',
        );
      }

      final currentUserData =
          currentUserSnapshot.data() ?? {};

      final requesterData =
          requesterSnapshot.data() ?? {};

      final currentUserName = _text(
        currentUserData['fullName'],
        fallback:
        currentUser.displayName ??
            'Community Member',
      );

      final currentUserImage = _text(
        currentUserData['profileImageUrl'],
        fallback: currentUser.photoURL ?? '',
      );

      final requesterName = _text(
        requesterData['fullName'],
        fallback: _text(
          requestData['requesterName'],
          fallback: 'Community Member',
        ),
      );

      final requesterImage = _text(
        requesterData['profileImageUrl'],
        fallback: _text(
          requestData['requesterProfileImageUrl'],
          fallback: '',
        ),
      );

      final followerReference =
      _userReference(currentUser.uid)
          .collection('followers')
          .doc(requesterId);

      final followingReference =
      _userReference(requesterId)
          .collection('following')
          .doc(currentUser.uid);

      final requestReference =
      _userReference(currentUser.uid)
          .collection('followRequests')
          .doc(requesterId);

      final batch =
      FirebaseFirestore.instance.batch();

      batch.set(
        followerReference,
        {
          'userId': requesterId,
          'fullName': requesterName,
          'profileImageUrl':
          requesterImage == '-'
              ? ''
              : requesterImage,
          'followedAt':
          FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        followingReference,
        {
          'userId': currentUser.uid,
          'fullName': currentUserName,
          'profileImageUrl':
          currentUserImage == '-'
              ? ''
              : currentUserImage,
          'followedAt':
          FieldValue.serverTimestamp(),
        },
      );

      batch.delete(requestReference);

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        '$requesterName is now following you.',
        isError: false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ??
            'The follow request could not be accepted.',
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
          _processingRequestIds.remove(requesterId);
        });
      }
    }
  }

  Future<void> _rejectRequest({
    required String requesterId,
    required String requesterName,
  }) async {
    final currentUser = _currentUser;

    if (currentUser == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    if (_processingRequestIds.contains(requesterId)) {
      return;
    }

    setState(() {
      _processingRequestIds.add(requesterId);
    });

    try {
      await _userReference(currentUser.uid)
          .collection('followRequests')
          .doc(requesterId)
          .delete();

      if (!mounted) return;

      _showMessage(
        'Follow request from $requesterName rejected.',
        isError: false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ??
            'The follow request could not be rejected.',
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
          _processingRequestIds.remove(requesterId);
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
        isError
            ? Colors.red
            : AppColors.petalRouge,
      ),
    );
  }

  Widget _profileAvatar({
    required String name,
    required String imageUrl,
  }) {
    if (imageUrl.isNotEmpty && imageUrl != '-') {
      return CircleAvatar(
        radius: 27,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial =
    name.trim().isEmpty
        ? '?'
        : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 27,
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

  Widget _buildRequestCard(
      QueryDocumentSnapshot<Map<String, dynamic>>
      requestDocument,
      ) {
    final data = requestDocument.data();

    final requesterId = _text(
      data['requesterId'],
      fallback: requestDocument.id,
    );

    final requesterName = _text(
      data['requesterName'],
      fallback: 'Community Member',
    );

    final requesterImage = _text(
      data['requesterProfileImageUrl'],
      fallback: '',
    );

    final isProcessing =
    _processingRequestIds.contains(requesterId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PublicProfileScreen(
                        userId: requesterId,
                      ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                _profileAvatar(
                  name: requesterName,
                  imageUrl: requesterImage,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w900,
                          color:
                          AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Wants to follow you',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                          AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.greyText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    onPressed:
                    isProcessing
                        ? null
                        : () {
                      _rejectRequest(
                        requesterId:
                        requesterId,
                        requesterName:
                        requesterName,
                      );
                    },
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      AppColors.petalRouge,
                      side: const BorderSide(
                        color:
                        AppColors.petalRouge,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed:
                    isProcessing
                        ? null
                        : () {
                      _acceptRequest(
                        requesterId:
                        requesterId,
                        requestData: data,
                      );
                    },
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
                          15,
                        ),
                      ),
                    ),
                    child:
                    isProcessing
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Text(
                      'Accept',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final requestsReference =
        _followRequestsReference;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Follow Requests'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body:
      currentUser == null ||
          requestsReference == null
          ? const Center(
        child: Text(
          'Please log in to view follow requests.',
          style: TextStyle(
            color: AppColors.greyText,
          ),
        ),
      )
          : StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: requestsReference
            .where(
          'status',
          isEqualTo: 'pending',
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color:
                AppColors.petalRouge,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding:
                EdgeInsets.all(28),
                child: Text(
                  'Follow requests could not be loaded.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    AppColors.greyText,
                  ),
                ),
              ),
            );
          }

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Container(
                constraints:
                const BoxConstraints(
                  maxWidth: 450,
                ),
                margin:
                const EdgeInsets.all(
                  28,
                ),
                padding:
                const EdgeInsets.all(
                  28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    26,
                  ),
                  border: Border.all(
                    color:
                    AppColors.petalFrost,
                  ),
                ),
                child: const Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .person_add_alt_1_rounded,
                      size: 55,
                      color:
                      AppColors.petalRouge,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No Follow Requests',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        AppColors.darkText,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'New requests will appear here.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                        AppColors.greyText,
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
                constraints:
                const BoxConstraints(
                  maxWidth: 600,
                ),
                child: ListView(
                  padding:
                  const EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    30,
                  ),
                  children: [
                    Container(
                      width:
                      double.infinity,
                      padding:
                      const EdgeInsets.all(
                        22,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors.petalFrost,
                        borderRadius:
                        BorderRadius.circular(
                          26,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '💌',
                            style: TextStyle(
                              fontSize: 42,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          const Text(
                            'Follow Requests',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight:
                              FontWeight.w900,
                              color:
                              AppColors.darkText,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            '${requests.length} pending request'
                                '${requests.length == 1 ? '' : 's'}',
                            style:
                            const TextStyle(
                              fontSize: 14,
                              color:
                              AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...requests.map(
                      _buildRequestCard,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}