// import 'package:flutter/material.dart';
// import 'login_page.dart';
//
// class OtpPage extends StatefulWidget {
//   const OtpPage({super.key});
//
//   @override
//   State<OtpPage> createState() => _OtpPageState();
// }
//
// class _OtpPageState extends State<OtpPage> {
//   final TextEditingController otpController = TextEditingController();
//
//   @override
//   void dispose() {
//     otpController.dispose(); // important to avoid memory leaks
//     super.dispose();
//   }
//
//   void verifyOtp() {
//     String otp = otpController.text.trim();
//
//     // Basic validation (don’t skip this)
//     if (otp.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter OTP")),
//       );
//       return;
//     }
//
//     // For now: direct navigation (you'll replace with Firebase later)
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const LoginPage(),
//       ),
//       (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("OTP Verification"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Enter OTP",
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             TextField(
//               controller: otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "OTP Code",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: verifyOtp,
//                 child: const Text("Verify OTP"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'login_page.dart';
//
// class OtpPage extends StatefulWidget {
//   final String verificationId;
//
//   const OtpPage({super.key, required this.verificationId});
//
//   @override
//   State<OtpPage> createState() => _OtpPageState();
// }
//
// class _OtpPageState extends State<OtpPage> {
//
//   final TextEditingController otpController = TextEditingController();
//
//   @override
//   void dispose() {
//     otpController.dispose();
//     super.dispose();
//   }
//
//   void verifyOtp() async {
//     String otp = otpController.text.trim();
//
//     if (otp.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter OTP")),
//       );
//       return;
//     }
//
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: widget.verificationId,
//         smsCode: otp,
//       );
//
//       UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       // 🔥 Save user in Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({
//         'phone': userCredential.user!.phoneNumber,
//         'createdAt': DateTime.now(),
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("OTP Verified Successfully")),
//       );
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//       );
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid OTP")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("OTP Verification"),
//         centerTitle: true,
//       ),
//
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//
//             const Text(
//               "Enter OTP",
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             TextField(
//               controller: otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "OTP Code",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: verifyOtp,
//                 child: const Text("Verify OTP"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//}
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'home_page.dart';
//
// class OtpPage extends StatefulWidget {
//   final String verificationId;
//   final String name;
//   final String email;
//   final String phone;
//   final String role;
//
//   const OtpPage({
//     super.key,
//     required this.verificationId,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.role,
//   });
//
//   @override
//   State<OtpPage> createState() => _OtpPageState();
// }
//
// class _OtpPageState extends State<OtpPage> {
//   final TextEditingController otpController = TextEditingController();
//   bool loading = false;
//
//   void verifyOtp() async {
//     setState(() => loading = true);
//
//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: widget.verificationId,
//         smsCode: otpController.text.trim(),
//       );
//
//       UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       String firebaseUid = userCredential.user!.uid;
//
//       // SEND TO LARAVEL
//       final response = await http.post(
//         Uri.parse("http://YOUR_IP_ADDRESS:8000/api/firebase-login"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "name": widget.name,
//           "email": widget.email,
//           "phone": widget.phone,
//           "role": widget.role,
//           "firebase_uid": firebaseUid,
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (response.statusCode == 200) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const HomePage()),
//               (route) => false,
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data["message"] ?? "Login failed")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid OTP")),
//       );
//     }
//
//     setState(() => loading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("OTP Verification")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "Enter OTP",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: loading ? null : verifyOtp,
//                 child: Text(loading ? "Loading..." : "Verify OTP"),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  TextEditingController otpController = TextEditingController();

  bool isLoading = false;

  Future<void> verifyOtp() async {
    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      String firebaseUid = userCredential.user!.uid;

      await sendToBackend(firebaseUid);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Error: $e")),
      );
    }
  }
  Future<void> sendToBackend(String uid) async {
    var url = Uri.parse("http://192.168.29.168:8000/api/firebase-login");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": widget.name,
          "email": widget.email,
          "phone": widget.phone,
          "password": widget.password,
          "firebase_uid": uid,
          "role": widget.role,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      var data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['status'] == true) {

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Login failed")),
        );
      }

    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: verifyOtp,
              child: const Text("Verify OTP"),
            )
          ],
        ),
      ),
    );
  }
}