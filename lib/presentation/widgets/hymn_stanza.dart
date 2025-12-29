import 'package:flutter/material.dart';

class HymnStanza extends StatelessWidget {
  final int number;
  final String text;
  final bool isChorus;

  const HymnStanza({
    super.key,
    required this.number,
    required this.text,
    this.isChorus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isChorus)
            SizedBox(
              width: 30,
              child: Text(
                '$number.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontStyle: isChorus ? FontStyle.italic : FontStyle.normal,
                fontWeight: isChorus ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
