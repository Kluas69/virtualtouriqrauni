import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double fontSize;
  final bool isMobile;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    required this.fontSize,
    required this.isMobile,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 20 : 30,
              vertical: widget.isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    _isHovered
                        ? [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ]
                        : [
                          theme.primaryColor.withOpacity(0.9),
                          theme.primaryColor.withOpacity(0.7),
                        ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(_isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.text,
              style: GoogleFonts.roboto(
                fontSize: widget.fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
