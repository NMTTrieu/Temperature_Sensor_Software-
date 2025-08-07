import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.green, size: 22),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.green, fontSize: 14)),
      ],
    );
  }
}
