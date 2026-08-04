import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  /// Safely resolves and formats a complete image URL for a given hotel object.
  static String? getHotelImageUrl(dynamic hotel) {
    if (hotel == null || hotel is! Map) return null;

    String? imagePath;
    if (hotel['primary_image'] != null) {
      if (hotel['primary_image'] is Map) {
        imagePath = hotel['primary_image']['image_path'] ?? hotel['primary_image']['url'];
      } else if (hotel['primary_image'] is String) {
        imagePath = hotel['primary_image'];
      }
    }

    if ((imagePath == null || imagePath.isEmpty) &&
        hotel['images'] != null &&
        hotel['images'] is List &&
        (hotel['images'] as List).isNotEmpty) {
      var firstImage = hotel['images'][0];
      if (firstImage is Map) {
        imagePath = firstImage['image_path'] ?? firstImage['url'];
      } else if (firstImage is String) {
        imagePath = firstImage;
      }
    }

    if ((imagePath == null || imagePath.isEmpty) &&
        hotel['image'] != null &&
        hotel['image'] is String) {
      imagePath = hotel['image'];
    }

    if (imagePath == null || imagePath.trim().isEmpty) return null;

    imagePath = imagePath.trim();

    // Direct HTTP/HTTPS URLs
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    String baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '') ?? '';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    String cleanPath = imagePath;
    if (cleanPath.startsWith('/storage/')) {
      cleanPath = cleanPath.substring(9);
    } else if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring(8);
    }
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    return '$baseUrl/storage/$cleanPath';
  }
}
