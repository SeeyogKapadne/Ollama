import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _fileBytes;
  String? _fileName;

  final apiService = ApiService(baseUrl: 'http://localhost:3000'); // Replace with your Node backend

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> uploadFile() async {
    if (_fileBytes == null || _fileName == null) return;

    final response = await apiService.uploadDocument(fileBytes: _fileBytes!, fileName: _fileName!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Resume")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: pickFile, child: const Text("Pick File")),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: uploadFile, child: const Text("Upload")),
              const SizedBox(height: 20),
              if (_fileName != null) Text("Selected: $_fileName"),
              if (_fileBytes != null) Text("File size: ${_fileBytes!.lengthInBytes} bytes"),
            ],
          ),
        ),
      ),
    );
  }
}
