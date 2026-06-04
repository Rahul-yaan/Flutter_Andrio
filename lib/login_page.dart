import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Login", style: TextStyle(fontSize: 30)),

            TextField(controller: emailController),
            TextField(controller: passwordController, obscureText: true),

            ElevatedButton(
              onPressed: () async {
                var response = await http.post(
                  Uri.parse("http://192.168.29.168:8000/api/login"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "email": emailController.text,
                    "password": passwordController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  var data = jsonDecode(response.body);

                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setString("token", data["token"]);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                } else {
                  print("Login failed");
                }
              },
              child: const Text("Login"),
            )
          ],
        ),
      ),
    );
  }
}