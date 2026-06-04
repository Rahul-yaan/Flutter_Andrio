import 'package:flutter/material.dart';
import '../services/api_service.dart';
import ' confirmation_screen.dart'; // ✅ FIXED

class BookingScreen extends StatefulWidget {
  final int hotelId;

  const BookingScreen({super.key, required this.hotelId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController nameCtrl = TextEditingController();

  Future<void> book() async {
    await ApiService.createBooking({
      "hotel_id": widget.hotelId,
      "customer_name": nameCtrl.text,
      "booking_date": "2025-01-01",
      "from_time": "10:00",
      "to_time": "12:00",
      "total_price": 200
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfirmationScreen(), // ✅ WORKS NOW
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: book,
              child: const Text("CONFIRM"),
            )
          ],
        ),
      ),
    );
  }
}