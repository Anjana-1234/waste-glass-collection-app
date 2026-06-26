import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://waste-glass-collection-app-production.up.railway.app';

class ApiService {
  static Future<List<dynamic>> getTodayRoute() async {
    final response = await http.get(Uri.parse('$baseUrl/api/suppliers/route'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['route'];
    }
    throw Exception('Failed to load route');
  }

  static Future<bool> submitCollection({
    required String barcodeId,
    required double clearKg,
    required double colouredKg,
    required String condition,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/suppliers/collect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'barcodeId': barcodeId,
        'clearKg': clearKg,
        'colouredKg': colouredKg,
        'condition': condition,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getTripSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/suppliers/trip-summary'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load trip summary');
  }
}