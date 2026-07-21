import 'activity_participants_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  int _selectedTab = 0;

  final List<String> _tabs = const [
    'Upcoming',
    'Completed',
    'Hosted by Me',
  ];

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  bool _isHostedByCurrentUser(
      Map<String, dynamic> data,
      String currentUserId,
      ) {
    return data['hostId'] == currentUserId;
  }

  bool _isCompleted(Map<String, dynamic> data) {
    final endDateTime = _toDateTime(data['endDateTime']);
    final activityDate = _toDateTime(data['activityDate']);

    if (endDateTime != null) {
      return endDateTime.isBefore(DateTime.now());
    }

    if (activityDate != null) {
      final endOfDay = DateTime(
        activityDate.year,
        activityDate.month,
        activityDate.day,
        23,
        59,
        59,
      );

      return endOfDay.isBefore(DateTime.now());
    }

    return data['status'] == 'completed';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterActivities(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
      String currentUserId,
      ) {
    final filtered = activities.where((document) {
      final data = document.data();

      switch (_selectedTab) {
        case 0:
          return !_isCompleted(data);

        case 1:
          return _isCompleted(data);

        case 2:
          return _isHostedByCurrentUser(data, currentUserId);

        default:
          return true;
      }
    }).toList();

    filtered.sort((first, second) {
      final firstDate =
          _toDateTime(first.data()['startDateTime']) ??
              _toDateTime(first.data()['activityDate']) ??
              DateTime(2100);

      final secondDate =
          _toDateTime(second.data()['startDateTime']) ??
              _toDateTime(second.data()['activityDate']) ??
              DateTime(2100);

      if (_selectedTab == 1) {
        return secondDate.compareTo(firstDate);
      }

      return firstDate.compareTo(secondDate);
    });

    return filtered;
  }

  String _formatActivityDate(Map<String, dynamic> data) {
    final startDateTime =
        _toDateTime(data['startDateTime']) ??
            _toDateTime(data['activityDate']);

    if (startDateTime == null) {
      return 'Date not available';
    }

    return DateFormat('EEEE, d MMMM yyyy').format(startDateTime);
  }

  String _formatActivityTime(Map<String, dynamic> data) {
    final startLabel = _text(
      data['startTimeLabel'],
      fallback: '',
    );

    final endLabel = _text(
      data['endTimeLabel'],
      fallback: '',
    );

    if (startLabel.isNotEmpty && endLabel.isNotEmpty) {
      return '$startLabel – $endLabel';
    }

    final startDateTime = _toDateTime(data['startDateTime']);
    final endDateTime = _toDateTime(data['endDateTime']);

    if (startDateTime != null && endDateTime != null) {
      return '${DateFormat('h:mm a').format(startDateTime)} – '
          '${DateFormat('h:mm a').format(endDateTime)}';
    }

    if (startDateTime != null) {
      return DateFormat('h:mm a').format(startDateTime);
    }

    return 'Time not available';
  }

  String _timeUntilActivity(Map<String, dynamic> data) {
    final startDateTime =
        _toDateTime(data['startDateTime']) ??
            _toDateTime(data['activityDate']);

    if (startDateTime == null) {
      return '';
    }

    final difference = startDateTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Completed';
    }

    if (difference.inDays > 1) {
      return 'Starts in ${difference.inDays} days';
    }

    if (difference.inDays == 1) {
      return 'Starts tomorrow';
    }

    if (difference.inHours > 0) {
      return 'Starts in ${difference.inHours} hours';
    }

    if (difference.inMinutes > 0) {
      return 'Starts in ${difference.inMinutes} minutes';
    }

    return 'Starting soon';
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'walking':
        return '🚶';

      case 'running':
        return '🏃';

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
        return '💗';

      default:
        return '✨';
    }
  }

  Future<void> _deleteActivity({
    required String activityId,
    required String activityTitle,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to permanently delete "$activityTitle"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('communityActivities')
          .doc(activityId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete activity: $e'),
          ),
        );
      }
    }
  }

  Future<void> _leaveActivity({
    required String activityId,
    required Map<String, dynamic> activityData,
    required String currentUserId,
  }) async {
    final isHost = activityData['hostId'] == currentUserId;

    if (isHost) {
      _showMessage(
        'You are the host of this activity. Hosts cannot leave their own activity.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Leave Activity?'),
          content: Text(
            'Are you sure you want to leave '
                '${_text(activityData['title'], fallback: 'this activity')}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.petalRouge,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final activityReference = FirebaseFirestore.instance
          .collection('communityActivities')
          .doc(activityId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(activityReference);

        if (!snapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'The activity no longer exists.',
          );
        }

        final latestData = snapshot.data() ?? {};
        final participantIds = List<String>.from(
          latestData['participantIds'] ?? [],
        );

        participantIds.remove(currentUserId);

        transaction.update(activityReference, {
          'participantIds': participantIds,
          'participantCount': participantIds.length,
        });
      });

      if (!mounted) return;

      _showMessage(
        'You have left the activity.',
        isError: false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ?? 'Could not leave the activity.',
      );
    }
  }

  void _showActivityDetails(
      String activityId,
      Map<String, dynamic> data,
      ) {
    final category = _text(
      data['category'],
      fallback: 'Activity',
    );

    final participantIds = List<String>.from(
      data['participantIds'] ?? [],
    );

    final maxParticipants =
        int.tryParse(data['maxParticipants'].toString()) ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
              decoration: const BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.greyText.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _categoryEmoji(category),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                data['title'],
                                fallback: 'Community Activity',
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.petalRouge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _detailsCard(
                    children: [
                      _detailsRow(
                        Icons.calendar_month_rounded,
                        'Date',
                        _formatActivityDate(data),
                      ),
                      _detailsRow(
                        Icons.access_time_rounded,
                        'Time',
                        _formatActivityTime(data),
                      ),
                      _detailsRow(
                        Icons.location_on_rounded,
                        'Location',
                        _text(
                          data['location'],
                          fallback: 'Not specified',
                        ),
                      ),
                      _detailsRow(
                        Icons.person_rounded,
                        'Host',
                        _text(
                          data['hostName'],
                          fallback: 'Community Member',
                        ),
                      ),
                      _detailsRow(
                        Icons.groups_rounded,
                        'Participants',
                        '${participantIds.length}'
                            '${maxParticipants > 0 ? ' / $maxParticipants' : ''}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _detailsCard(
                    children: [
                      const Text(
                        'About This Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _text(
                          data['description'],
                          fallback: 'No description was provided.',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _detailsCard(
                    color: AppColors.petalFrost,
                    children: [
                      const Text(
                        'What to Bring 🎒',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _text(
                          data['itemsToBring'],
                          fallback:
                          'Nothing specific. Bring anything you need to stay comfortable.',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Activity ID: ${activityId.substring(0, 6).toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailsCard({
    required List<Widget> children,
    Color color = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.petalFrost,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailsRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: AppColors.petalRouge,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
      String message, {
        bool isError = true,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : AppColors.petalRouge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('My Activities'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: currentUser == null
          ? _buildNotLoggedIn()
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    14,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildTabs(),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('communityActivities')
                        .where(
                      'participantIds',
                      arrayContains: currentUser.uid,
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
                        return _buildErrorState(
                          snapshot.error.toString(),
                        );
                      }

                      final allActivities =
                          snapshot.data?.docs ?? [];

                      final filteredActivities =
                      _filterActivities(
                        allActivities,
                        currentUser.uid,
                      );

                      if (filteredActivities.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          8,
                          22,
                          34,
                        ),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          final document =
                          filteredActivities[index];

                          return Padding(
                            padding:
                            const EdgeInsets.only(bottom: 16),
                            child: _buildActivityCard(
                              activityId: document.id,
                              data: document.data(),
                              currentUserId: currentUser.uid,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.petalFrost,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          Text(
            '📅',
            style: TextStyle(fontSize: 42),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Activity Schedule',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Keep track of activities you joined and activities you organised.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(
          _tabs.length,
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
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.petalRouge
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    _tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
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

  Widget _buildActivityCard({
    required String activityId,
    required Map<String, dynamic> data,
    required String currentUserId,
  }) {
    final category = _text(
      data['category'],
      fallback: 'Activity',
    );

    final title = _text(
      data['title'],
      fallback: 'Community Activity',
    );

    final location = _text(
      data['location'],
      fallback: 'Location not specified',
    );

    final hostName = _text(
      data['hostName'],
      fallback: 'Community Member',
    );

    final participantIds = List<String>.from(
      data['participantIds'] ?? [],
    );

    final maxParticipants =
        int.tryParse(data['maxParticipants'].toString()) ?? 0;

    final isHost = data['hostId'] == currentUserId;
    final completed = _isCompleted(data);
    final timeStatus = _timeUntilActivity(data);

    return InkWell(
      onTap: () {
        _showActivityDetails(
          activityId,
          data,
        );
      },
      borderRadius: BorderRadius.circular(27),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: completed
              ? Colors.white.withOpacity(0.72)
              : const Color(0xFFFFE6A9),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: completed
                ? AppColors.petalFrost
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(category),
                      style: const TextStyle(fontSize: 29),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

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
                      const SizedBox(height: 5),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.petalRouge,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isHost)
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
                  ),
              ],
            ),

            const SizedBox(height: 18),

            _activityInformation(
              Icons.calendar_month_rounded,
              _formatActivityDate(data),
            ),
            _activityInformation(
              Icons.access_time_rounded,
              _formatActivityTime(data),
            ),
            _activityInformation(
              Icons.location_on_rounded,
              location,
            ),
            _activityInformation(
              Icons.person_rounded,
              'Hosted by $hostName',
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivityParticipantsScreen(
                      activityId: activityId,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 20,
                      color: AppColors.petalRouge,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${participantIds.length}'
                            '${maxParticipants > 0 ? ' / $maxParticipants' : ''} participants',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.petalRouge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: completed
                          ? AppColors.petalFrost
                          : Colors.white.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      completed ? 'Completed ✓' : timeStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: completed
                            ? AppColors.greyText
                            : AppColors.petalRouge,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  tooltip: 'View details',
                  onPressed: () {
                    _showActivityDetails(
                      activityId,
                      data,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.petalRouge,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),

            if (!completed && !isHost) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 47,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _leaveActivity(
                      activityId: activityId,
                      activityData: data,
                      currentUserId: currentUserId,
                    );
                  },
                  icon: const Icon(
                    Icons.exit_to_app_rounded,
                  ),
                  label: const Text('Leave Activity'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.petalRouge,
                    side: const BorderSide(
                      color: AppColors.petalRouge,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],

            if (isHost) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 47,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _deleteActivity(
                      activityId: activityId,
                      activityTitle: title,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                  ),
                  label: const Text(
                    'Delete Activity',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _activityInformation(
      IconData icon,
      String value,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
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

  Widget _buildEmptyState() {
    String title;
    String message;
    String emoji;

    switch (_selectedTab) {
      case 0:
        title = 'No Upcoming Activities';
        message =
        'Activities you join will appear here with their date, time and location.';
        emoji = '📅';
        break;

      case 1:
        title = 'No Completed Activities';
        message =
        'Past activities will appear here after their scheduled end time.';
        emoji = '🏁';
        break;

      case 2:
        title = 'You Have Not Hosted Yet';
        message =
        'Create a community activity and invite other members to join.';
        emoji = '✨';
        break;

      default:
        title = 'No Activities';
        message = 'No activities are available.';
        emoji = '📭';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.petalFrost,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 58),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.groups_rounded,
                ),
                label: const Text('Browse Community'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.petalRouge,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                'Could Not Load Activities',
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

  Widget _buildNotLoggedIn() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Please log in to view your activities.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }
}