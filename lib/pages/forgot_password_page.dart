import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Enter your email');
      return;
    }

    setState(() => _loading = true);
    final result = await ApiService.forgotPassword(email: email);
    setState(() => _loading = false);

    // Daily limit reached — show blocking popup
    if (result['retry_tomorrow'] == true) {
      _showLimitDialog();
      return;
    }

    if (result['message'] != null) {
      final attemptsLeft = result['attempts_left'] ?? 0;
      setState(() => _sent = true);

      if (attemptsLeft > 0 && attemptsLeft < 3) {
        _snack('Email sent. You have $attemptsLeft attempt(s) left today.');
      }
    } else {
      _snack(result['error'] ?? 'Something went wrong');
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Color(0xFFC0392B)),
            SizedBox(width: 8),
            Text('Limit Reached'),
          ],
        ),
        content: const Text(
          'You have used all 3 password reset attempts for today.\n\nPlease try again tomorrow.',
          style: TextStyle(color: Color(0xFF555555), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to login
            },
            child: const Text(
              'Go to Login',
              style: TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        title: const Text('Forgot Password'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Text(
        'Enter the email address linked to your account.\nWe\'ll send a reset link valid for 3 minutes.',
        style: TextStyle(color: Color(0xFF666666), fontSize: 14, height: 1.5),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFC0392B)),
        ),
      ),
      const SizedBox(height: 24),
      CustomButton(
        text: 'Send Reset Link',
        onPressed: _submit,
        isLoading: _loading,
      ),
    ],
  );

  Widget _successView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Color(0xFF27AE60),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check your email',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'A reset link was sent to ${_emailCtrl.text.trim()}.\nIt expires in 3 minutes.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back to Login',
            style: TextStyle(color: Color(0xFFC0392B)),
          ),
        ),
      ],
    ),
  );
}
