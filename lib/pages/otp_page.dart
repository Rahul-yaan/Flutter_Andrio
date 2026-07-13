import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import 'login_page.dart';

class OtpPage extends StatefulWidget {
  final int userId;
  final String phoneNumber;

  const OtpPage({super.key, required this.userId, required this.phoneNumber});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _passVisible = false;

  Future<void> _verify() async {
    final otp = _otpCtrl.text;
    if (otp.length != 6) {
      _snack('Enter complete 6-digit OTP');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _snack('Password min 6 characters');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    final idToken = await _authService.verifyOtp(otp);
    if (idToken == null) {
      setState(() => _loading = false);
      _snack('Wrong OTP. Try again.');
      return;
    }

    final result = await ApiService.verifyOtp(
      userId: widget.userId,
      firebaseIdToken: idToken,
      password: _passCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );

    setState(() => _loading = false);

    if (result['message'] != null) {
      _snack('Verified! Please login.');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (r) => false,
        );
      }
    } else {
      _snack(result['error'] ?? 'Verification failed');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color(0xFFC0392B),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFFC0392B), width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Modern Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFC0392B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC0392B).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.message_outlined,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify Phone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'OTP sent to ${widget.phoneNumber}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _otpCtrl,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      autofocus: true,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Set Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_passVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFC0392B),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF888888),
                        ),
                        onPressed: () =>
                            setState(() => _passVisible = !_passVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  CustomButton(
                    text: 'Verify & Continue',
                    onPressed: _verify,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: RichText(
                        text: const TextSpan(
                          text: "Didn't receive OTP? ",
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Resend',
                              style: TextStyle(
                                color: Color(0xFFC0392B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
