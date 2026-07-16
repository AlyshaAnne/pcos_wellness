import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'The user account could not be created.',
        );
      }

      await user.updateDisplayName(
        fullNameController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fullName': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'dob': '',
        'height': '',
        'weight': '',
        'pcosDiagnosed': 'No',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (error) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Email Error'),
            content: SelectableText(
              '${error.code}\n\n${error.message}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        return;
      }

      debugPrint(
        'Verification email requested for ${user.email}',
      );

      if (!mounted) {
        return;
      }

      await _showVerificationDialog(user);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _firebaseErrorMessage(error),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _showVerificationDialog(User user) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isResending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> resendEmail() async {
              setDialogState(() {
                isResending = true;
              });

              try {
                await user.reload();

                final refreshedUser =
                    FirebaseAuth.instance.currentUser;

                if (refreshedUser == null) {
                  throw FirebaseAuthException(
                    code: 'user-not-found',
                    message:
                    'The account could not be loaded.',
                  );
                }

                if (refreshedUser.emailVerified) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your email is already verified. You may now log in.',
                      ),
                      backgroundColor: AppColors.petalRouge,
                    ),
                  );

                  Navigator.pop(dialogContext);

                  await FirebaseAuth.instance.signOut();

                  if (!mounted) {
                    return;
                  }

                  Navigator.pop(this.context);
                  return;
                }

                await refreshedUser.sendEmailVerification();

                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'A new verification email was sent to '
                          '${refreshedUser.email}.',
                    ),
                    backgroundColor: AppColors.petalRouge,
                  ),
                );
              } on FirebaseAuthException catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }

                String message;

                if (error.code == 'too-many-requests') {
                  message =
                  'Too many emails were requested. '
                      'Please wait a few minutes before trying again.';
                } else {
                  message = error.message ??
                      'The verification email could not be resent.';
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not resend the email: $error',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isResending = false;
                  });
                }
              }
            }

            Future<void> returnToLogin() async {
              Navigator.pop(dialogContext);

              await FirebaseAuth.instance.signOut();

              if (!mounted) {
                return;
              }

              Navigator.pop(this.context);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.petalRouge,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verify Your Email',
                    ),
                  ),
                ],
              ),
              content: Text(
                'A verification email has been sent to:\n\n'
                    '${user.email ?? emailController.text.trim()}\n\n'
                    'Open the email and tap the verification link. '
                    'After verifying your address, return to the app '
                    'and log in.\n\n'
                    'Check your Spam, Promotions, and All Mail folders '
                    'if you cannot find it.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.darkText,
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed:
                  isResending ? null : resendEmail,
                  icon: isResending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.petalRouge,
                    ),
                  )
                      : const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: Text(
                    isResending
                        ? 'Sending...'
                        : 'Resend Email',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor:
                    AppColors.petalRouge,
                  ),
                ),
                FilledButton(
                  onPressed:
                  isResending ? null : returnToLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    AppColors.petalRouge,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Return to Login',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _firebaseErrorMessage(
      FirebaseAuthException error,
      ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email already has an account.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password must contain at least 6 characters.';

      case 'operation-not-allowed':
        return 'Email and password registration is not enabled in Firebase.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many requests were made. Please try again later.';

      default:
        return error.message ??
            'Registration failed. Please try again.';
    }
  }

  InputDecoration decoration(
      String label,
      IconData icon,
      ) {
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
        title: const Text('Create Account'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 550,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 90,
                      color: AppColors.petalRouge,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register to begin tracking your wellness.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: fullNameController,
                      textCapitalization:
                      TextCapitalization.words,
                      decoration: decoration(
                        'Full Name',
                        Icons.person_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your full name.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: emailController,
                      keyboardType:
                      TextInputType.emailAddress,
                      decoration: decoration(
                        'Email',
                        Icons.email_rounded,
                      ),
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email.';
                        }

                        final emailPattern = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailPattern
                            .hasMatch(email)) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: decoration(
                        'Password',
                        Icons.lock_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () {
                            setState(() {
                              hidePassword =
                              !hidePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter a password.';
                        }

                        if (value.length < 6) {
                          return 'Password must contain at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller:
                      confirmPasswordController,
                      obscureText:
                      hideConfirmPassword,
                      onFieldSubmitted: (_) {
                        if (!loading) {
                          register();
                        }
                      },
                      decoration: decoration(
                        'Confirm Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () {
                            setState(() {
                              hideConfirmPassword =
                              !hideConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please confirm your password.';
                        }

                        if (value !=
                            passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed:
                        loading ? null : register,
                        icon: loading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(
                          loading
                              ? 'Creating Account...'
                              : 'Register',
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.petalRouge,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColors.petalRouge
                              .withOpacity(0.6),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          textStyle:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: AppColors.petalRouge,
                          fontWeight: FontWeight.bold,
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