import 'package:flutter/material.dart';

class AlertBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const AlertBadge({Key? key, required this.count, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(icon: const Icon(Icons.notifications), onPressed: onTap),
        if (count > 0)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
      ],
    );
  }
}
