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
  static const String baseUrl = 'http://10.59.47.182:8000/api';

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
      body: jsonEncode({'email': email, 'password': password, 'role': 'user'}),
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

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> searchHotels({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse(
        '$baseUrl/hotels/search?from_lat=$fromLat&from_lng=$fromLng&to_lat=$toLat&to_lng=$toLng',
      ),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  static Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String input,
  ) async {
    const apiKey = 'AIzaSyBLCXUCuOLV-pUkoha8qKlsdVYQDg9e5VI';
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(cities)&key=$apiKey';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data['predictions'] == null) return [];

    List<Map<String, dynamic>> results = [];
    for (var p in data['predictions']) {
      final placeId = p['place_id'];
      final detailUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey';
      final detailRes = await http.get(Uri.parse(detailUrl));
      final detailData = jsonDecode(detailRes.body);

      if (detailData['result'] != null) {
        final loc = detailData['result']['geometry']['location'];
        results.add({
          'description': p['description'],
          'lat': loc['lat'],
          'lng': loc['lng'],
        });
      }
    }
    return results;
  }
}
