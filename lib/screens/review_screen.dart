import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final int hotelId;
  ReviewScreen({required this.hotelId});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List reviews = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    final data = await ApiService.getReviews(widget.hotelId);
    setState(() => reviews = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reviews")),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (_, i) {
          final r = reviews[i];
          return ListTile(
            title: Text(r['user_name']),
            subtitle: Text(r['comment'] ?? ''),
            trailing: Text("⭐${r['rating']}"),
          );
        },
      ),
    );
  }
}