import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingState extends StatelessWidget {
  final String message;
  final bool isDark;

  const LoadingState({
    super.key,
    this.message = 'Loading...',
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor.withOpacity(0.1),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: GoogleFonts.roboto(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
