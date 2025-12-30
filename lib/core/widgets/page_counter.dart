import 'package:flutter/material.dart';

class PageCounter extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final bool isDark;

  const PageCounter({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Text(
        '${currentIndex + 1} / $totalCount',
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
