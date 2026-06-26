import 'package:flutter/material.dart';

class HotelDetailPage extends StatelessWidget {
  final int hotelId;
  const HotelDetailPage({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        title: const Text('Hotel Detail'),
      ),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
