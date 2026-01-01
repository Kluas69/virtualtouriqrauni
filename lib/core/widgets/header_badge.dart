import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderBadge extends StatelessWidget {
  final bool isDark;
  final String text;
  final IconData icon;

  const HeaderBadge({
    super.key,
    required this.isDark,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(
              alpha: isDark ? 0.3 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
