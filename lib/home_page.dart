// import 'package:flutter/material.dart';
//
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body: const Center(
//         child: Text("Welcome to Home Page", style: TextStyle(fontSize: 24)),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? token;

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  void loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString("token");
    });

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  // 🔥 OPTIONAL: Logout function
  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: token == null
            ? const CircularProgressIndicator()
            : Text(
          "Token:\n$token",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}