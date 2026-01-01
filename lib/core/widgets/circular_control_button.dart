import 'package:flutter/material.dart';

class CircularControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isEnabled;
  final Color? iconColor;
  final double size;

  const CircularControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isEnabled = true,
    this.iconColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  isEnabled
                      ? theme.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: isEnabled ? onPressed : null,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? theme.primaryColor : Colors.grey.shade600,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
