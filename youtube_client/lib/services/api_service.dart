import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class ApiService {
  static const baseUrl = "http://localhost:3000"; // Change if needed

  // ----------------------------
  // Download single video
  // ----------------------------
  static Future<Map<String, dynamic>> downloadVideo(String url) async {
    final res = await http.post(
      Uri.parse('$baseUrl/download'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"url": url}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to download video: ${res.body}');
    }
  }

  // ----------------------------
  // Transcribe multiple videos (mobile/desktop)
  // ----------------------------
  static Future<Map<String, dynamic>> transcribeMultipleVideos(
      List<String> filePaths) async {
    final body = jsonEncode({
      "videoFiles": filePaths,
      "outPrefix": "transcript",
      "formats": ["json", "csv", "srt"]
    });

    // Logging
    print("POST $baseUrl/transcribe");
    print("Request Body: $body");

    final res = await http.post(
      Uri.parse("$baseUrl/transcribe"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("Response Status: ${res.statusCode}");
    print("Response Body: ${res.body}");

    return jsonDecode(res.body);
  }

  // ----------------------------
  // Transcribe multiple videos (Web)
  // ----------------------------
  static Future<Map<String, dynamic>> transcribeVideosWeb(
      List<Uint8List> filesBytes, List<String> fileNames) async {
    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/transcribe"));

    for (int i = 0; i < filesBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "videoFiles",
          filesBytes[i],
          filename: fileNames[i],
          contentType: MediaType("video", "mp4"),
        ),
      );
    }

    request.fields["outPrefix"] = "transcript";
    request.fields["formats"] = jsonEncode(["json", "csv", "srt"]);

    // Logging
    print("POST $baseUrl/transcribe (Web Multipart)");
    print("Files: ${fileNames.join(', ')}");
    print("Fields: ${request.fields}");

    var response = await request.send();
    var resBody = await response.stream.bytesToString();

    print("Response Status: ${response.statusCode}");
    print("Response Body: $resBody");

    if (response.statusCode == 200) {
      return jsonDecode(resBody);
    } else {
      throw Exception("Failed to transcribe videos (web): $resBody");
    }
  }

  // ----------------------------
  // Search transcripts (Mobile/Desktop)
  // ----------------------------
  static Future<Map<String, dynamic>> searchTranscriptMobile(
      String query, List<File> files) async {
    var uri = Uri.parse("$baseUrl/search");
    var request = http.MultipartRequest('POST', uri);

    request.fields['query'] = query;

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath(
        'transcriptFiles',
        file.path,
        filename: file.path.split('/').last,
      ));
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    print("HTTP Status: ${response.statusCode}");
    print("Response body: $respStr");

    return jsonDecode(respStr);
  }

  // ----------------------------
  // Search transcripts (Web)
  // ----------------------------
  static Future<Map<String, dynamic>> searchTranscriptWeb(
      String query, List<Uint8List> filesBytes, List<String> fileNames) async {
    var uri = Uri.parse("$baseUrl/search");
    var request = http.MultipartRequest('POST', uri);

    request.fields['query'] = query;

    for (int i = 0; i < filesBytes.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        'transcriptFiles',
        filesBytes[i],
        filename: fileNames[i],
        contentType: MediaType("application", "json"),
      ));
    }

    // Logging
    print("POST $baseUrl/search (Web Multipart)");
    print("Files: ${fileNames.join(', ')}");
    print("Fields: ${request.fields}");

    var response = await request.send();
    var resBody = await response.stream.bytesToString();

    print("HTTP Status: ${response.statusCode}");
    print("Response body: $resBody");

    if (response.statusCode == 200) {
      return jsonDecode(resBody);
    } else {
      throw Exception("Failed to search transcripts (web): $resBody");
    }
  }

  // ----------------------------
  // Helper: Get video URL
  // ----------------------------
  static String getVideoUrl(String filename) {
    final encoded = Uri.encodeComponent(filename);
    return "$baseUrl/videos/$encoded";
  }
}
