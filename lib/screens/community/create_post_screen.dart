import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = const [
    'Exercise',
    'Nutrition',
    'Symptoms',
    'Cycle',
    'Sleep',
    'Mental Wellness',
    'Motivation',
    'Question',
    'Achievement',
    'Wellness Tip',
  ];

  final List<String> _moods = const [
    '😊 Happy',
    '💪 Motivated',
    '😌 Calm',
    '🥱 Tired',
    '😟 Worried',
    '🌸 Hopeful',
  ];

  String? _selectedCategory;
  String? _selectedMood;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not select the image: $error',
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<String?> _uploadPostImage({
    required String userId,
    required String postId,
  }) async {
    if (_selectedImage == null ||
        _selectedImageBytes == null) {
      return null;
    }

    final extension = _selectedImage!.name
        .split('.')
        .last
        .toLowerCase()
        .trim()
        .isEmpty
        ? 'jpg'
        : _selectedImage!.name.split('.').last.toLowerCase();

    final storageReference = FirebaseStorage.instance
        .ref()
        .child('communityPosts')
        .child(userId)
        .child('$postId.$extension');

    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(extension),
    );

    final uploadTask = await storageReference.putData(
      _selectedImageBytes!,
      metadata,
    );

    return uploadTask.ref.getDownloadURL();
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      default:
        return 'image/jpeg';
    }
  }

  Future<void> _createPost() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to create a post.',
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDocument.data() ?? {};

      final fullName =
      userData['fullName']?.toString().trim().isNotEmpty == true
          ? userData['fullName'].toString()
          : user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'Community Member';

      final profileImageUrl =
          userData['profileImageUrl']?.toString() ??
              user.photoURL ??
              '';

      final postReference = FirebaseFirestore.instance
          .collection('communityPosts')
          .doc();

      final imageUrl = await _uploadPostImage(
        userId: user.uid,
        postId: postReference.id,
      );

      await postReference.set({
        'authorId': user.uid,
        'authorName': fullName,
        'authorProfileImageUrl': profileImageUrl,
        'category': _selectedCategory,
        'mood': _selectedMood,
        'text': _postController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'likedBy': <String>[],
        'savedBy': <String>[],
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'weeklyXp': FieldValue.increment(10),
        'monthlyXp': FieldValue.increment(10),
        'totalXp': FieldValue.increment(10),
      }, SetOptions(merge: true));

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Post Shared 🎉'),
            content: const Text(
              'Your post has been added to the community. You also earned 10 XP.',
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
        error.message ?? 'The post could not be created.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Create Post'),
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
                42,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.petalFrost,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💬 Share With the Community',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Share progress, ask a question or motivate someone else.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.greyText,
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
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(
                          color: AppColors.petalFrost,
                        ),
                      ),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _inputDecoration(
                              label: 'Post category',
                              icon: Icons.category_rounded,
                            ),
                            items: _categories
                                .map(
                                  (category) =>
                                  DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  ),
                            )
                                .toList(),
                            onChanged: _isPosting
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

                          DropdownButtonFormField<String>(
                            value: _selectedMood,
                            decoration: _inputDecoration(
                              label: 'How are you feeling?',
                              icon: Icons.emoji_emotions_rounded,
                            ),
                            items: _moods
                                .map(
                                  (mood) =>
                                  DropdownMenuItem<String>(
                                    value: mood,
                                    child: Text(mood),
                                  ),
                            )
                                .toList(),
                            onChanged: _isPosting
                                ? null
                                : (value) {
                              setState(() {
                                _selectedMood = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _postController,
                            minLines: 6,
                            maxLines: 12,
                            maxLength: 1000,
                            textCapitalization:
                            TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'What would you like to share?',
                              icon: Icons.edit_rounded,
                              hint:
                              'Share progress, advice, encouragement or ask a question...',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Please write something before posting.';
                              }

                              if (text.length < 3) {
                                return 'Your post is too short.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_selectedImageBytes != null)
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.petalFrost,
                          ),
                        ),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                  _isPosting ? null : _removeImage,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  label: const Text('Remove Image'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: _isPosting ? null : _pickImage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.petalFrost,
                              ),
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor:
                                  AppColors.petalFrost,
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AppColors.petalRouge,
                                    size: 29,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a Photo',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Optional: attach a progress photo, meal or activity image.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.greyText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.greyText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6A9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✨',
                            style: TextStyle(fontSize: 25),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Be respectful and avoid posting private medical information. Creating a post earns 10 XP.',
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
                        _isPosting ? null : _createPost,
                        icon: _isPosting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isPosting
                              ? 'Sharing Post...'
                              : 'Share Post',
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