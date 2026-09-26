import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://192.168.1.45:8000/api';
  
  for (int i = 1; i <= 10; i++) {
    try {
      final res = await http.get(Uri.parse('\$baseUrl/hotels/\$i'), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        print('HOTEL \$i DATA: \${res.body}');
      }
    } catch (e) {
      print('Error: \$e');
    }
  }
}
