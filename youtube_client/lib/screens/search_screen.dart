import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_client/widgets/build_result_card.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  String? _status;
  List<Map<String, dynamic>>? _results;

  // Web files: bytes + names
  List<Uint8List> _webFilesBytes = [];
  List<String> _webFileNames = [];

  // Mobile/Desktop files
  List<File> _localFiles = [];

  /// Pick files depending on platform
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // required for web
    );

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _webFilesBytes = result.files.map((f) => f.bytes!).toList();
          _webFileNames = result.files.map((f) => f.name).toList();
          _status = "${_webFilesBytes.length} file(s) selected (Web)";
        });
      } else {
        setState(() {
          _localFiles = result.paths
              .where((p) => p != null)
              .map((p) => File(p!))
              .toList();
          _status = "${_localFiles.length} file(s) selected";
        });
      }
    } else {
      setState(() => _status = "No files selected");
    }
  }

  /// Search transcripts
  Future<void> _searchTranscript() async {
    if (_queryController.text.isEmpty) {
      setState(() => _status = "⚠️ Enter a search query");
      return;
    }

    if ((kIsWeb && _webFilesBytes.isEmpty) ||
        (!kIsWeb && _localFiles.isEmpty)) {
      setState(() => _status = "⚠️ Please select transcript files");
      return;
    }

    setState(() {
      _status = "Searching...";
      _results = null;
    });

    try {
      Map<String, dynamic> response;

      if (kIsWeb) {
        // Send web files as bytes
        response = await ApiService.searchTranscriptWeb(
            _queryController.text, _webFilesBytes, _webFileNames);
      } else {
        // Send mobile/desktop files as File objects
        response =
            await ApiService.searchTranscriptMobile(_queryController.text, _localFiles);
      }

      final result = response['result'];
      setState(() {
        _results = result != null ? [Map<String, dynamic>.from(result)] : [];
        _status = _results!.isEmpty
            ? "No results found"
            : response['message'] ?? "Results found";
      });
    } catch (e) {
      setState(() => _status = "❌ Error during search: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final cardWidth = isLargeScreen ? 600.0 : size.width * 0.95;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text("Search Transcript"),
        backgroundColor: Colors.blueAccent.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _queryController,
                          decoration: InputDecoration(
                            labelText: "Search Query",
                            prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFiles,
                          icon: Icon(Icons.upload_file, color: Colors.white),
                          label: Text("Select Transcript JSON Files",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blueAccent.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _searchTranscript,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blueAccent.shade700,
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Search",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_status != null) ...[
                          SizedBox(height: 16),
                          Text(
                            _status!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                if (_results != null)
                  ..._results!.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: BuildResultCard(
                        r: r,
                        color: Colors.white,
                        shadowColor: Colors.blueAccent.withOpacity(0.2),
                      ),
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
