import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _bringController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _selectedCategory;
  bool _isLoading = false;

  String _locationVisibility = 'participants';
  String _participantListVisibility = 'participants';

  final List<String> _categories = const [
    'Walking',
    'Running',
    'Yoga',
    'Gym',
    'Cycling',
    'Swimming',
    'Dance',
    'Hiking',
    'Wellness Meetup',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _bringController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      helpText: 'Select activity date',
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Future<void> _pickStartTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      helpText: 'Select start time',
    );

    if (selectedTime == null) return;

    setState(() {
      _startTime = selectedTime;
    });
  }

  Future<void> _pickEndTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          _startTime ??
          TimeOfDay.now(),
      helpText: 'Select end time',
    );

    if (selectedTime == null) return;

    setState(() {
      _endTime = selectedTime;
    });
  }

  DateTime _combineDateAndTime(
      DateTime date,
      TimeOfDay time,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDate() {
    if (_selectedDate == null) {
      return 'Select date';
    }

    return DateFormat('EEE, d MMM yyyy').format(_selectedDate!);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    return time.format(context);
  }

  Future<void> _createActivity() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showMessage('Please select an activity date.');
      return;
    }

    if (_startTime == null) {
      _showMessage('Please select a start time.');
      return;
    }

    if (_endTime == null) {
      _showMessage('Please select an end time.');
      return;
    }

    final startDateTime = _combineDateAndTime(
      _selectedDate!,
      _startTime!,
    );

    final endDateTime = _combineDateAndTime(
      _selectedDate!,
      _endTime!,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      _showMessage(
        'The end time must be later than the start time.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in to create an activity.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final hostName =
      userData['fullName']?.toString().trim().isNotEmpty == true
          ? userData['fullName'].toString()
          : user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'Community Member';

      final maxParticipants = int.parse(
        _maxParticipantsController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('communityActivities')
          .add({
        'hostId': user.uid,
        'hostName': hostName,
        'hostPhotoUrl': userData['photoUrl'] ?? '',

        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),

        'activityDate': Timestamp.fromDate(_selectedDate!),
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),

        'startTimeLabel': _formatTime(_startTime),
        'endTimeLabel': _formatTime(_endTime),

        'location': _locationController.text.trim(),
        'locationVisibility': _locationVisibility,

        'maxParticipants': maxParticipants,

        'participantIds': [user.uid],
        'participantCount': 1,
        'participantListVisibility': _participantListVisibility,

        'attendedParticipantIds': <String>[],
        'attendanceCount': 0,

        'itemsToBring': _bringController.text.trim(),

        'allowParticipantSharing': true,
        'sharedByParticipantIds': <String>[],

        'status': 'upcoming',
        'isCancelled': false,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: AppColors.petalRouge,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Activity Created'),
                ),
              ],
            ),
            content: Text(
              '${_titleController.text.trim()} has been added to the community.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.petalRouge,
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ??
            'The activity could not be created.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.petalRouge,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.petalFrost,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.petalFrost,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.petalRouge,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Widget _selectionCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.petalFrost,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.petalRouge,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Create Activity'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                40,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD978),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏃 Create Something Fun',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Plan a wellness activity and invite community members to join you.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.petalFrost,
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            textCapitalization:
                            TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'Activity title',
                              icon: Icons.local_activity_rounded,
                              hint: 'Morning walk at KLCC',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter an activity title.';
                              }

                              if (value.trim().length < 3) {
                                return 'The title is too short.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _inputDecoration(
                              label: 'Category',
                              icon: Icons.category_rounded,
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                                .toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 7,
                            textCapitalization:
                            TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'Description',
                              icon: Icons.description_rounded,
                              hint:
                              'Explain what the activity involves and who it is suitable for.',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please add a short description.';
                              }

                              if (value.trim().length < 10) {
                                return 'Please provide a little more detail.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _selectionCard(
                            label: 'Activity date',
                            value: _formatDate(),
                            icon: Icons.calendar_month_rounded,
                            onTap: _pickDate,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _selectionCard(
                                  label: 'Start time',
                                  value: _formatTime(_startTime),
                                  icon: Icons.play_circle_rounded,
                                  onTap: _pickStartTime,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _selectionCard(
                                  label: 'End time',
                                  value: _formatTime(_endTime),
                                  icon: Icons.stop_circle_rounded,
                                  onTap: _pickEndTime,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _locationController,
                            textCapitalization:
                            TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: 'Location',
                              icon: Icons.location_on_rounded,
                              hint: 'KLCC Park',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter the activity location.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _locationVisibility,
                            decoration: _inputDecoration(
                              label: 'Who can see the exact location?',
                              icon: Icons.location_off_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'participants',
                                child: Text('Joined participants only'),
                              ),
                              DropdownMenuItem(
                                value: 'followers',
                                child: Text('My followers'),
                              ),
                              DropdownMenuItem(
                                value: 'public',
                                child: Text('Everyone'),
                              ),
                            ],
                            onChanged: _isLoading
                                ? null
                                : (value) {
                              if (value == null) return;

                              setState(() {
                                _locationVisibility = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _participantListVisibility,
                            decoration: _inputDecoration(
                              label: 'Who can view the participant list?',
                              icon: Icons.visibility_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'participants',
                                child: Text('Joined participants only'),
                              ),
                              DropdownMenuItem(
                                value: 'followers',
                                child: Text('My followers'),
                              ),
                              DropdownMenuItem(
                                value: 'public',
                                child: Text('Everyone'),
                              ),
                            ],
                            onChanged: _isLoading
                                ? null
                                : (value) {
                              if (value == null) return;

                              setState(() {
                                _participantListVisibility = value;
                              });
                            },
                          ),

                          TextFormField(
                            controller:
                            _maxParticipantsController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              label: 'Maximum participants',
                              icon: Icons.groups_rounded,
                              hint: '12',
                            ),
                            validator: (value) {
                              final number = int.tryParse(
                                value?.trim() ?? '',
                              );

                              if (number == null) {
                                return 'Please enter a valid number.';
                              }

                              if (number < 2) {
                                return 'Allow at least 2 participants.';
                              }

                              if (number > 500) {
                                return 'The participant limit is too high.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _bringController,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization:
                            TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'What should participants bring?',
                              icon: Icons.backpack_rounded,
                              hint:
                              'Water bottle, comfortable shoes, yoga mat...',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.petalFrost,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.petalRouge,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will automatically be added as the host and first participant. '
                                  'Participants can choose whether to share their attendance after the activity.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                        _isLoading ? null : _createActivity,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.celebration_rounded,
                        ),
                        label: Text(
                          _isLoading
                              ? 'Creating Activity...'
                              : 'Create Activity',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.petalRouge,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColors.petalRouge.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}