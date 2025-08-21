import 'package:flutter/material.dart';
import '../screens/video_player_screen.dart';

class BuildResultCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final Color color;
  final Color shadowColor;

  const BuildResultCard({
    required this.r,
    this.color = Colors.white,
    this.shadowColor = const Color(0x22000000),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shadowColor: shadowColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['text'] ?? '',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(
                  "${r['start_hms'] ?? ''} - ${r['end_hms'] ?? ''}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const Spacer(),
                Icon(Icons.videocam, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r['videoFile'] ?? '',
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          filename: r['videoFile'] ?? '',
                          startTime: r['start']?.toDouble() ?? 0.0,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(80, 36),
                    backgroundColor: Colors.blueGrey.shade800,
                  ),
                  child: Text("Play",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
