import 'package:flutter/material.dart';

class TranscriptItem extends StatelessWidget {
  final String text;
  final String startHMS;
  final String endHMS;
  final VoidCallback? onTap;

  TranscriptItem({
    Key? key,
    required this.text,
    required this.startHMS,
    required this.endHMS,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        title: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text('$startHMS - $endHMS'),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}
