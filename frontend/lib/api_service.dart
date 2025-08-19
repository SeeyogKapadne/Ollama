import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Upload a file (mobile, desktop, web)
  Future<String> uploadDocument({required Uint8List fileBytes, required String fileName}) async {
    try {
      final content = utf8.decode(fileBytes); // Convert bytes to string
      final payload = {
        "model": "nomic-embed-text",
        "prompt": content,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/index'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return "Uploaded successfully:";
      } else {
        return "Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }

  /// Search query
  Future<Map<String, dynamic>> searchQuery(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'query': query}),
    );
    return json.decode(response.body);
  }
}
