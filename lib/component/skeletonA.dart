import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              width: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
