import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController =
  TextEditingController();
  final _bioController =
  TextEditingController();
  final _dobController =
  TextEditingController();
  final _heightController =
  TextEditingController();
  final _weightController =
  TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String _pcosDiagnosed = 'No';
  String _profileImageUrl = '';

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data() ?? {};

      _fullNameController.text =
          data['fullName']?.toString() ??
              user.displayName ??
              '';

      _bioController.text =
          data['bio']?.toString() ?? '';

      _dobController.text =
          data['dob']?.toString() ?? '';

      _heightController.text =
          data['height']?.toString() ?? '';

      _weightController.text =
          data['weight']?.toString() ?? '';

      final diagnosed =
      data['pcosDiagnosed']?.toString();

      if (diagnosed == 'Yes' || diagnosed == 'No') {
        _pcosDiagnosed = diagnosed!;
      }

      _profileImageUrl =
          data['profileImageUrl']?.toString() ?? '';
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Your profile could not be loaded: $error',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedImage =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedImage == null) {
        return;
      }

      final bytes = await pickedImage.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedImage.name;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'The image could not be selected: $error',
        isError: true,
      );
    }
  }

  Future<String> _uploadProfileImage(
      String userId,
      ) async {
    final imageBytes = _selectedImageBytes;

    if (imageBytes == null) {
      return _profileImageUrl;
    }

    final safeName =
    (_selectedImageName ?? 'profile.jpg')
        .replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final storageReference = FirebaseStorage.instance
        .ref()
        .child('profilePictures')
        .child(userId)
        .child(
      '${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );

    final metadata = SettableMetadata(
      contentType: _contentTypeFor(
        safeName,
      ),
    );

    final uploadTask = await storageReference.putData(
      imageBytes,
      metadata,
    );

    return uploadTask.ref.getDownloadURL();
  }

  String _contentTypeFor(
      String fileName,
      ) {
    final lowerCaseName = fileName.toLowerCase();

    if (lowerCaseName.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerCaseName.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profileImageUrl =
      await _uploadProfileImage(
        user.uid,
      );

      final fullName =
      _fullNameController.text.trim();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fullName': fullName,
          'bio': _bioController.text.trim(),
          'dob': _dobController.text.trim(),
          'height':
          _heightController.text.trim(),
          'weight':
          _weightController.text.trim(),
          'pcosDiagnosed': _pcosDiagnosed,
          'profileImageUrl': profileImageUrl,
          'updatedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updateDisplayName(fullName);

      if (profileImageUrl.isNotEmpty) {
        await user.updatePhotoURL(
          profileImageUrl,
        );
      }

      if (!mounted) return;

      _showMessage(
        'Profile updated successfully.',
        isError: false,
      );

      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message ??
            'Your profile could not be updated.',
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
          _isSaving = false;
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

  Widget _profileAvatar() {
    if (_selectedImageBytes != null) {
      return CircleAvatar(
        radius: 58,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: MemoryImage(
          _selectedImageBytes!,
        ),
      );
    }

    if (_profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundColor: AppColors.petalFrost,
        backgroundImage: NetworkImage(
          _profileImageUrl,
        ),
        onBackgroundImageError: (_, __) {},
      );
    }

    final fullName =
    _fullNameController.text.trim();

    final initial = fullName.isEmpty
        ? '?'
        : fullName[0].toUpperCase();

    return CircleAvatar(
      radius: 58,
      backgroundColor: AppColors.petalFrost,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: AppColors.petalRouge,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.petalRouge,
      ),
      filled: true,
      fillColor: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.petalRouge,
        ),
      )
          : user == null
          ? const Center(
        child: Text(
          'Please log in to edit your profile.',
          style: TextStyle(
            color: AppColors.greyText,
          ),
        ),
      )
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.fromLTRB(
                28,
                34,
                28,
                34,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.all(
                            3,
                          ),
                          decoration:
                          BoxDecoration(
                            shape:
                            BoxShape.circle,
                            border: Border.all(
                              color: AppColors
                                  .petalRouge,
                              width: 2,
                            ),
                          ),
                          child: _profileAvatar(),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 2,
                          child: Material(
                            color: AppColors
                                .petalRouge,
                            shape:
                            const CircleBorder(),
                            child: InkWell(
                              customBorder:
                              const CircleBorder(),
                              onTap:
                              _pickProfileImage,
                              child:
                              const Padding(
                                padding:
                                EdgeInsets.all(
                                  10,
                                ),
                                child: Icon(
                                  Icons
                                      .camera_alt_rounded,
                                  size: 21,
                                  color:
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                      _pickProfileImage,
                      child: const Text(
                        'Change profile picture',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          color: AppColors
                              .petalRouge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller:
                      _fullNameController,
                      decoration:
                      _inputDecoration(
                        label: 'Full name',
                        icon:
                        Icons.person_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return 'Please enter your full name.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue:
                      user.email ?? '',
                      readOnly: true,
                      decoration:
                      _inputDecoration(
                        label: 'Email',
                        icon:
                        Icons.email_rounded,
                      ).copyWith(
                        helperText:
                        'Email cannot be changed here.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                      _bioController,
                      maxLines: 4,
                      maxLength: 180,
                      decoration:
                      _inputDecoration(
                        label: 'Bio',
                        icon:
                        Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                      _dobController,
                      readOnly: true,
                      onTap: () async {
                        final now =
                        DateTime.now();

                        final selectedDate =
                        await showDatePicker(
                          context: context,
                          initialDate: DateTime(
                            now.year - 20,
                          ),
                          firstDate:
                          DateTime(1940),
                          lastDate: now,
                        );

                        if (selectedDate ==
                            null) {
                          return;
                        }

                        _dobController.text =
                        '${selectedDate.day.toString().padLeft(2, '0')}/'
                            '${selectedDate.month.toString().padLeft(2, '0')}/'
                            '${selectedDate.year}';
                      },
                      decoration:
                      _inputDecoration(
                        label: 'Date of birth',
                        icon: Icons
                            .calendar_month_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                      _heightController,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      _inputDecoration(
                        label: 'Height (cm)',
                        icon:
                        Icons.height_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return null;
                        }

                        final height =
                        double.tryParse(
                          value.trim(),
                        );

                        if (height == null ||
                            height <= 0) {
                          return 'Enter a valid height.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                      _weightController,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      _inputDecoration(
                        label: 'Weight (kg)',
                        icon: Icons
                            .monitor_weight_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return null;
                        }

                        final weight =
                        double.tryParse(
                          value.trim(),
                        );

                        if (weight == null ||
                            weight <= 0) {
                          return 'Enter a valid weight.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _pcosDiagnosed,
                      decoration: _inputDecoration(
                        label: 'PCOS diagnosed',
                        icon: Icons.health_and_safety_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Yes',
                          child: Text('Yes'),
                        ),
                        DropdownMenuItem(
                          value: 'No',
                          child: Text('No'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _pcosDiagnosed =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child:
                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons
                              .save_rounded,
                        ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Changes',
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors
                              .petalRouge,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              18,
                            ),
                          ),
                          textStyle:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w900,
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
