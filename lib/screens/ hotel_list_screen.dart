import 'package:flutter/material.dart';

class HotelListScreen extends StatefulWidget {
  final String city;
  final DateTime fromDate;
  final DateTime toDate;

  const HotelListScreen({
    Key? key,
    required this.city,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hotels in ${widget.city}"),
      ),
      body: Center(
        child: Text(
          "From: ${widget.fromDate}\nTo: ${widget.toDate}",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}