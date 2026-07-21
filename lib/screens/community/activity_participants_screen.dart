import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';

class ActivityParticipantsScreen extends StatelessWidget {
  final String activityId;

  const ActivityParticipantsScreen({
    super.key,
    required this.activityId,
  });

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  Future<List<_ParticipantData>> _loadParticipants({
    required List<String> participantIds,
    required String hostId,
  }) async {
    final participants = <_ParticipantData>[];

    for (final participantId in participantIds) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(participantId)
          .get();

      final userData = userSnapshot.data() ?? {};

      participants.add(
        _ParticipantData(
          userId: participantId,
          fullName: _text(
            userData['fullName'],
            fallback: 'Community Member',
          ),
          profileImageUrl: _text(
            userData['profileImageUrl'],
            fallback: '',
          ),
          isHost: participantId == hostId,
        ),
      );
    }

    participants.sort((first, second) {
      if (first.isHost && !second.isHost) return -1;
      if (!first.isHost && second.isHost) return 1;

      return first.fullName
          .toLowerCase()
          .compareTo(second.fullName.toLowerCase());
    });

    return participants;
  }

  Widget _profileAvatar({
    required String name,
    required String imageUrl,
  }) {
    if (imageUrl.isNotEmpty && imageUrl != '-') {
      return CircleAvatar(
        radius: 25,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initial =
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
  }

  Widget _buildParticipantTile({
    required BuildContext context,
    required _ParticipantData participant,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = currentUser?.uid == participant.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: participant.isHost
              ? AppColors.petalRouge
              : AppColors.petalFrost,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                userId: participant.userId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _profileAvatar(
                name: participant.fullName,
                imageUrl: participant.profileImageUrl,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isCurrentUser
                          ? 'You'
                          : participant.isHost
                          ? 'Activity host'
                          : 'Participant',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),

              if (participant.isHost)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.petalFrost,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.petalRouge,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.greyText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
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
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Activity Participants'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('communityActivities')
            .doc(activityId)
            .snapshots(),
        builder: (context, activitySnapshot) {
          if (activitySnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.petalRouge,
              ),
            );
          }

          if (activitySnapshot.hasError) {
            return _buildErrorState(
              'The activity participants could not be loaded.',
            );
          }

          if (!activitySnapshot.hasData ||
              !activitySnapshot.data!.exists) {
            return _buildErrorState(
              'This activity no longer exists.',
            );
          }

          final activityData =
              activitySnapshot.data!.data() ?? {};

          final participantIds = _stringList(
            activityData['participantIds'],
          );

          final hostId = _text(
            activityData['hostId'],
            fallback: '',
          );

          final activityTitle = _text(
            activityData['title'],
            fallback: 'Community Activity',
          );

          final participantListVisibility = _text(
            activityData['participantListVisibility'],
            fallback: 'participants',
          );

          final currentUser = FirebaseAuth.instance.currentUser;

          final currentUserJoined = currentUser != null &&
              participantIds.contains(currentUser.uid);

          final currentUserIsHost =
              currentUser?.uid == hostId;

          final canViewParticipants = currentUserIsHost;

          if (!canViewParticipants) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.petalFrost,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 52,
                        color: AppColors.petalRouge,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Participant List Is Private',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Only joined participants can view the people attending this activity.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return FutureBuilder<List<_ParticipantData>>(
            future: _loadParticipants(
              participantIds: participantIds,
              hostId: hostId,
            ),
            builder: (context, participantsSnapshot) {
              if (participantsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.petalRouge,
                  ),
                );
              }

              if (participantsSnapshot.hasError) {
                return _buildErrorState(
                  'Participant profiles could not be loaded.',
                );
              }

              final participants =
                  participantsSnapshot.data ?? [];

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 620,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            22,
                            24,
                            22,
                            16,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.petalFrost,
                              borderRadius:
                              BorderRadius.circular(26),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '👥',
                                  style: TextStyle(
                                    fontSize: 42,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  activityTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${participants.length} participant'
                                      '${participants.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: participants.isEmpty
                              ? const Center(
                            child: Text(
                              'No participants have joined yet.',
                              style: TextStyle(
                                color: AppColors.greyText,
                              ),
                            ),
                          )
                              : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              22,
                              4,
                              22,
                              30,
                            ),
                            itemCount: participants.length,
                            itemBuilder: (context, index) {
                              return _buildParticipantTile(
                                context: context,
                                participant:
                                participants[index],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ParticipantData {
  final String userId;
  final String fullName;
  final String profileImageUrl;
  final bool isHost;

  const _ParticipantData({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.isHost,
  });
}