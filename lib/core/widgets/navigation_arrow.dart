import 'package:flutter/material.dart';

class NavigationArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const NavigationArrow({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.95),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : theme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
