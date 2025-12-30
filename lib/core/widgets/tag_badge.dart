import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagBadge extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const TagBadge({
    super.key,
    required this.text,
    this.fontSize = 11,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: fontSize,
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
