import 'package:flutter/material.dart';

class VideoListItem extends StatelessWidget {
  final String filePath;
  final String title;
  final VoidCallback onTap;

  VideoListItem({required this.filePath, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(filePath),
      onTap: onTap,
    );
  }
}
