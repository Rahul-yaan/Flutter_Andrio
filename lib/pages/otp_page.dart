import 'package:flutter/material.dart';
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
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _passVisible = false;

  String get _otp => _otpCtrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) {
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

    final idToken = await _authService.verifyOtp(_otp);
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
              children: [
                const Icon(Icons.phone_android, color: Colors.white, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Verify Phone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'OTP sent to ${widget.phoneNumber}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
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
                  const SizedBox(height: 8),
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6 OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 46,
                        height: 54,
                        child: TextField(
                          controller: _otpCtrls[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC0392B),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDDDDD),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFC0392B),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Set Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Verify & Continue',
                    onPressed: _verify,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: RichText(
                        text: const TextSpan(
                          text: "Didn't receive OTP? ",
                          style: TextStyle(color: Color(0xFF888888)),
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
