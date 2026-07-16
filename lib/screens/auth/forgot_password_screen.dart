import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Check Your Email'),
          content: Text(
            'Firebase accepted the password-reset request for:\n\n'
                '${_emailController.text.trim()}\n\n'
                'Check Inbox, Spam, Promotions and All Mail.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Password Reset Error'),
          content: SelectableText(
            '${error.code}\n\n${error.message}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.petalRouge,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 80,
                      color: AppColors.petalRouge,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Reset Your Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the email connected to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                      TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: const Icon(
                          Icons.email_rounded,
                          color: AppColors.petalRouge,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email.';
                        }

                        if (!email.contains('@')) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                        _loading ? null : _sendResetEmail,
                        icon: _loading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _loading
                              ? 'Sending...'
                              : 'Send Reset Email',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.petalRouge,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
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