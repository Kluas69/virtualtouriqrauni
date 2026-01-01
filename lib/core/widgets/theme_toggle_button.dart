import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/themes.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
              ),
              child: themeProvider.isAnimating
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.amber : Colors.indigo,
                        ),
                      ),
                    )
                  : Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDark),
                      color: isDark ? Colors.amber : Colors.indigo,
                    ),
            ),
            onPressed: themeProvider.isAnimating ? null : onPressed,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
        );
      },
    );
  }
}
