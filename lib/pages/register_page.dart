import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'otp_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _snack('All fields are required');
      return;
    }
    if (phone.length != 10) {
      _snack('Enter valid 10-digit phone number');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.register(
      name: name,
      email: email,
      phone: '+91$phone',
    );

    print("========== REGISTER RESPONSE ==========");
    print(result);
    print("======================================");

    // Extract error message if any
    String? extractErrorMessage(Map<String, dynamic> res) {
      if (res['errors'] != null) {
        final errors = res['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          } else if (firstVal != null) {
            return firstVal.toString();
          }
        } else if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        } else if (errors is String && errors.isNotEmpty) {
          return errors;
        }
      }
      if (res['error'] != null && res['error'].toString().trim().isNotEmpty) {
        return res['error'].toString().trim();
      }
      if (res['message'] != null && res['message'].toString().trim().isNotEmpty) {
        final msg = res['message'].toString().trim();
        if (!msg.toLowerCase().contains('proceed to otp') &&
            !msg.toLowerCase().contains('success')) {
          return msg;
        }
      }
      return null;
    }

    final rawUserId = result['user_id'];
    final errorMsg = extractErrorMessage(result);

    if (errorMsg != null || rawUserId == null) {
      setState(() => _loading = false);
      _snack(errorMsg ?? 'Registration failed. Please try again.');
      return;
    }

    final userId = rawUserId is int ? rawUserId : int.parse(rawUserId.toString());

    await _authService.sendOtp(
      phoneNumber: '+91$phone',
      onCodeSent: () {
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(userId: userId, phoneNumber: '+91$phone'),
          ),
        );
      },
      onError: (err) {
        setState(() => _loading = false);
        _snack(err);
      },
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: const BoxDecoration(
              color: Color(0xFFC0392B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in your details to get started',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Color(0xFFC0392B),
                      ),
                      prefixText: '+91  ',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Register & Send OTP',
                    onPressed: _submit,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFFC0392B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
