import 'package:flutter/material.dart';
import 'package:youtube_client/screens/transcribe_screen.dart';
import 'screens/download_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Video Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.8;
    final cardHeight = size.height * 0.15;

    return Scaffold(
      appBar: AppBar(title: Text("YouTube Video Manager")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionCard(
                context,
                icon: Icons.download,
                label: "Download Video",
                color: Colors.blueAccent,
                width: cardWidth,
                height: cardHeight,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DownloadScreen())),
              ),
              SizedBox(height: 20),
              _buildActionCard(
                context,
                icon: Icons.transcribe,
                label: "Transcribe Video",
                color: Colors.greenAccent,
                width: cardWidth,
                height: cardHeight,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TranscribeScreen())),
              ),
              SizedBox(height: 20),
              _buildActionCard(
                context,
                icon: Icons.search,
                label: "Search Transcript",
                color: Colors.orangeAccent,
                width: cardWidth,
                height: cardHeight,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required double width,
      required double height,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
