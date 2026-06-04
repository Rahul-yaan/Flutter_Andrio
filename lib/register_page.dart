// import 'package:flutter/material.dart';
// import 'otp_page.dart';
//
// class RegisterPage extends StatelessWidget {
//   const RegisterPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//
//     final nameController = TextEditingController();
//     final emailController = TextEditingController();
//     final phoneController = TextEditingController();
//     final passwordController = TextEditingController();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Register")),
//
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(
//                 labelText: "Full Name",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 15),
//
//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 15),
//
//             TextField(
//               controller: phoneController,
//               decoration: const InputDecoration(
//                 labelText: "Phone Number",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 15),
//
//             TextField(
//               controller: passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: (){
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context)=>OtpPage()),
//                   );
//                 },
//                 child: const Text("Register"),
//               ),
//             )
//
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_page.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void sendOtp(BuildContext context) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phoneText = phoneController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phoneText.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    String phone = "+91$phoneText";

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpPage(
              verificationId: verificationId,
              name: name,
              email: email,
              phone: phoneText,
              password: password, // ✅ FIXED
              role: "user",
            ),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => sendOtp(context),
                child: const Text("Send OTP"),
              ),
            )

          ],
        ),
      ),
    );
  }
}