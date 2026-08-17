import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/register');

      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'role': 'user',
            }),
          )
          .timeout(const Duration(seconds: 60));

      return jsonDecode(res.body);
    } catch (e) {
      print("REGISTER ERROR: $e");
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required int userId,
    required String firebaseIdToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'firebase_id_token': firebaseIdToken,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('VERIFY OTP ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'role': 'user',
            }),
          )
          .timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('LOGIN ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
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
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('FORGOT PASSWORD ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> searchHotels({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    List<String>? amenities,
  }) async {
    try {
      final token = await getToken();
      String url = '$baseUrl/hotels/search?from_lat=$fromLat&from_lng=$fromLng&to_lat=$toLat&to_lng=$toLng';
      
      if (amenities != null && amenities.isNotEmpty) {
        for (var amenity in amenities) {
          url += '&amenities[]=${Uri.encodeComponent(amenity)}';
        }
      }

      final res = await http
          .get(
            Uri.parse(url),
            headers: {..._headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('SEARCH ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getHotelDetail({required int hotelId}) async {
    try {
      final token = await getToken();
      final res = await http
          .get(
            Uri.parse('$baseUrl/hotels/$hotelId'),
            headers: {..._headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('GET HOTEL ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getHotelReviews({required int hotelId}) async {
    try {
      final token = await getToken();
      final res = await http
          .get(
            Uri.parse('$baseUrl/hotels/$hotelId/reviews'),
            headers: {..._headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 35));
          
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return {'reviews': decoded};
      }
      return decoded;
    } catch (e) {
      print('GET REVIEWS ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String input,
  ) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(cities)&key=$apiKey';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 35));
      final data = jsonDecode(res.body);

      if (data['predictions'] == null) return [];

      List<Map<String, dynamic>> results = [];
      for (var p in data['predictions']) {
        final placeId = p['place_id'];
        final detailUrl =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey';
        final detailRes = await http
            .get(Uri.parse(detailUrl))
            .timeout(const Duration(seconds: 35));
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
    } catch (e) {
      print('PLACES ERROR: $e');
      return [];
    }
  }
  static Future<Map<String, dynamic>> submitReview({
    required int hotelId,
    int? bookingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'hotel_id': hotelId,
          if (bookingId != null) 'booking_id': bookingId,
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
    } catch (e) {
      print('SUBMIT REVIEW ERROR: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> createBooking({
    required int hotelId,
    required String bookingDate,
    required String truckType,
    required String truckNo,
    required String logisticsName,
    required String logisticsNumber,
    required String paymentMethod,
    double? discountPercentage,
    double? discountAmount,
  }) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'hotel_id': hotelId,
          'booking_date': bookingDate,
          'truck_type': truckType,
          'truck_no': truckNo,
          'logistics_name': logisticsName,
          'logistics_number': logisticsNumber,
          'payment_method': paymentMethod,
          if (discountPercentage != null) 'discount_percentage': discountPercentage,
          if (discountAmount != null) 'discount_amount': discountAmount,
        }),
      ).timeout(const Duration(seconds: 35));
      return jsonDecode(res.body);
  } catch (e) {
    print('BOOKING ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

static Future<Map<String, dynamic>> getMyBookings() async {
  try {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/my'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 35));
    return jsonDecode(res.body);
  } catch (e) {
    print('MY BOOKINGS ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

static Future<Map<String, dynamic>> cancelBooking({
  required int bookingId,
}) async {
  try {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 35));
    return jsonDecode(res.body);
  } catch (e) {
    print('CANCEL BOOKING ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

static Future<Map<String, dynamic>> getProfile() async {
  try {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 35));
    return jsonDecode(res.body);
  } catch (e) {
    print('GET PROFILE ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

static Future<Map<String, dynamic>> updateProfile({
  String? name,
  String? email,
  String? phone,
  String? avatarPath,
}) async {
  try {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/update-profile'));
    request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    
    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (phone != null) request.fields['phone'] = phone;

    if (avatarPath != null && avatarPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    }

    var streamedResponse = await request.send().timeout(const Duration(seconds: 35));
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  } catch (e) {
    print('UPDATE PROFILE ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

static Future<Map<String, dynamic>> verifyPayment({
  required int bookingId,
  required String razorpayPaymentId,
  required String razorpayOrderId,
  required String razorpaySignature,
  String? transactionId,
}) async {
  try {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/verify-payment'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
        'transaction_id': transactionId ?? razorpayPaymentId,
      }),
    ).timeout(const Duration(seconds: 35));
    return jsonDecode(res.body);
  } catch (e) {
    print('VERIFY PAYMENT ERROR: $e');
    return {'error': 'Connection failed: $e'};
  }
}

}