import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'The account could not be loaded.',
        );
      }

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'The account could not be loaded.',
        );
      }

      if (!refreshedUser.emailVerified) {
        debugPrint(
          'User email is not verified, but login is allowed during development.',
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = _firebaseErrorMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showVerificationDialog({
    required String email,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.mark_email_unread_rounded,
                color: AppColors.petalRouge,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Verify Your Email'),
              ),
            ],
          ),
          content: Text(
            'Please verify $email before logging in.\n\n'
                'Open the verification email sent by Firebase and tap the link. '
                'After verifying, return here and log in again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account was found using this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return error.message ?? 'Login failed. Please try again.';
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.petalRouge,
      ),
      suffixIcon: suffixIcon,
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/Dashboard_Large_Illustration_1.png',
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return const Icon(
                                Icons.favorite_rounded,
                                size: 120,
                                color: AppColors.petalRouge,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Image.asset(
                            'assets/images/pcos_app_logo.png',
                            width: 80,
                            errorBuilder: (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Log in to continue tracking your wellness.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      decoration: _inputDecoration(
                        label: 'Email address',
                        icon: Icons.email_rounded,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email address.';
                        }

                        final emailPattern = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailPattern.hasMatch(email)) {
                          return 'Please enter a valid email address.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      autofillHints: const [
                        AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_rounded,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        if (value.length < 6) {
                          return 'Password must contain at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.petalRouge,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.darkText,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.petalRouge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _login,
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
                          Icons.login_rounded,
                        ),
                        label: Text(
                          _isLoading ? 'Logging in...' : 'Login',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.petalRouge,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColors.petalRouge.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            color: AppColors.petalRouge,
                            fontWeight: FontWeight.w700,
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