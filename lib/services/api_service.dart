// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class ApiService {
//   static const baseUrl = "http://192.168.29.168:8000/api";
//
//   static Future<List<dynamic>> getHotels() async {
//     final res = await http.get(Uri.parse("$baseUrl/hotels"));
//     return jsonDecode(res.body);
//   }
//
//   static Future<Map<String, dynamic>> getHotelDetails(int id) async {
//     final res = await http.get(Uri.parse("$baseUrl/hotels/$id"));
//     return jsonDecode(res.body);
//   }
//
//   static Future<List<dynamic>> getReviews(int hotelId) async {
//     final res = await http.get(Uri.parse("$baseUrl/hotels/$hotelId/reviews"));
//     return jsonDecode(res.body);
//   }
//
//   static Future createBooking(Map data) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/bookings"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(data),
//     );
//     return jsonDecode(res.body);
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = "http://192.168.29.168:8000/api";

  // 🔐 Get token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // 📌 Common headers with token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // 🔥 IMPORTANT
    };
  }

  // 🟢 Public APIs
  static Future<List<dynamic>> getHotels() async {
    final res = await http.get(Uri.parse("$baseUrl/hotels"));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getHotelDetails(int id) async {
    final res = await http.get(Uri.parse("$baseUrl/hotels/$id"));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getReviews(int hotelId) async {
    final res = await http.get(Uri.parse("$baseUrl/hotels/$hotelId/reviews"));
    return jsonDecode(res.body);
  }

  // 🔴 Protected API (FIXED)
  static Future createBooking(Map data) async {
    final headers = await getHeaders();

    final res = await http.post(
      Uri.parse("$baseUrl/bookings"),
      headers: headers,
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);
  }
}