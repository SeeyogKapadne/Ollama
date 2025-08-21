import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TranscribeScreen extends StatefulWidget {
  @override
  _TranscribeScreenState createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> {
  String _status = "No file uploaded yet";
  bool _isLoading = false;

  // Web: bytes + filenames
  List<Uint8List> _webFilesBytes = [];
  List<String> _webFileNames = [];

  // Mobile/Desktop: file paths
  List<String> _mobileFilePaths = [];

  // Pick multiple video files
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'mkv'],
      withData: kIsWeb, // Important for web
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _webFilesBytes = result.files.map((f) => f.bytes!).toList();
          _webFileNames = result.files.map((f) => f.name).toList();
          _status = "${_webFilesBytes.length} file(s) selected (Web)";
        } else {
          _mobileFilePaths =
              result.paths.whereType<String>().toList(); // only non-null paths
          _status = "${_mobileFilePaths.length} file(s) selected";
        }
      });
    } else {
      setState(() => _status = "No files selected");
    }
  }

  // Upload and transcribe
  Future<void> _uploadAndTranscribe() async {
    if ((kIsWeb && _webFilesBytes.isEmpty) ||
        (!kIsWeb && _mobileFilePaths.isEmpty)) {
      setState(() => _status = "⚠️ Please select at least one file.");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "⏳ Uploading & transcribing...";
    });

    try {
      Map<String, dynamic> response;

      if (kIsWeb) {
        response =
            await ApiService.transcribeVideosWeb(_webFilesBytes, _webFileNames);
      } else {
        response = await ApiService.transcribeMultipleVideos(_mobileFilePaths);
      }

      // Safely parse output files
      final results = response['results'] as List<dynamic>? ?? [];

      final allOutputFiles = results
          .map((r) => r['outputFiles'] as Map<String, dynamic>)
          .map((m) => m.values.toList())
          .expand((f) => f)
          .toList();

      if (allOutputFiles.isEmpty) {
        setState(() => _status = "❌ Transcription failed: No output files returned");
      } else {
        setState(() {
          _status =
              "✅ Transcription successful!\nOutput files:\n${allOutputFiles.join('\n')}";
        });
      }
    } catch (e) {
      print("Error during transcription: $e");
      setState(() => _status = "❌ Error during transcription: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transcribe Video"),
        backgroundColor: Colors.blueAccent.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Select Videos Button
                ElevatedButton(
                  onPressed: _pickFiles,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueAccent.shade700,
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "Select Video(s)",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Upload & Transcribe Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _uploadAndTranscribe,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueAccent.shade700,
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        _isLoading ? "Processing..." : "Upload & Transcribe",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Status Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
