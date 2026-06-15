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
  static const String baseUrl = 'https://your-laravel-app.com/api';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required int userId,
    required String firebaseIdToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'firebase_id_token': firebaseIdToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': 'user',
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
  }
}