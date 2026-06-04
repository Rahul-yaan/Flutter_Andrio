import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key}); // ✅ FIX ADDED

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              "Booking Confirmed",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text("GO HOME"),
            )
          ],
        ),
      ),
    );
  }
}