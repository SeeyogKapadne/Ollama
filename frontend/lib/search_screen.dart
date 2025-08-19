import 'package:flutter/material.dart';
import 'api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final apiService = ApiService(baseUrl: 'http://localhost:3000'); // Replace with your Node backend
  String? _result;
  bool _loading = false;

  Future<void> search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    try {
      final response = await apiService.searchQuery(query);

      setState(() {
        if (response is Map<String, dynamic>) {
          // Format each key-value pair on a separate line
          _result = response.entries
              .map((e) => "${e.key}: ${e.value}")
              .join("\n");
        } else {
          _result = response.toString();
        }
      });
    } catch (e) {
      setState(() => _result = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Resumes")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter search query',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: search,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Search"),
              ),
              const SizedBox(height: 20),
              if (_result != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _result!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5, // Line spacing
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
