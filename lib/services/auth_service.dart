import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function() onCodeSent,
    required Function(String) onError,
  }) async {
    print('SENDING OTP TO: $phoneNumber');
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) {
        print('VERIFICATION COMPLETED AUTOMATICALLY');
      },
      verificationFailed: (e) {
        print('FIREBASE ERROR CODE: ${e.code}');
        print('FIREBASE ERROR MESSAGE: ${e.message}');
        onError(e.message ?? 'OTP send failed');
      },
      codeSent: (verificationId, resendToken) {
        print('CODE SENT SUCCESSFULLY, verificationId: $verificationId');
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (id) {
        print('AUTO RETRIEVAL TIMEOUT: $id');
        _verificationId = id;
      },
      timeout: const Duration(seconds: 60),
    );
    print('verifyPhoneNumber CALL COMPLETED');
  }

  Future<String?> verifyOtp(String smsCode) async {
    if (_verificationId == null) return null;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return await result.user?.getIdToken();
    } catch (e) {
      print('OTP VERIFICATION ERROR: $e');
      return null;
    }
  }
}