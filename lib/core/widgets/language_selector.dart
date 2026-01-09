import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/futuristic_ui_state.dart';
import 'unified_glassmorphic_container.dart';

/// Language selector with animated flags and RTL support
class LanguageSelector extends StatefulWidget {
  final Language currentLanguage;
  final Function(Language) onLanguageChanged;
  final bool isDark;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.isDark,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;
  
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AnimationConfig.languageTransition,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConfig.hoverScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.smoothCurve,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.bounceCurve,
    ));

    _glowAnimation = AnimationUtils.createGlowAnimation(
      controller: _animationController,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.defaultCurve,
    ));
  }

  void _setupKeyboardListener() {
    // Listen for Ctrl+Shift+L keyboard shortcut
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final isLPressed = event.logicalKey == LogicalKeyboardKey.keyL;
      
      if (isCtrlPressed && isShiftPressed && isLPressed) {
        _toggleDropdown();
        return true;
      }
    }
    return false;
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else if (!_isDropdownOpen) {
      _animationController.reverse();
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() {
      _isDropdownOpen = true;
    });
    
    context.read<FuturisticUIState>().toggleLanguageDropdown();
    _animationController.forward();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _animationController,
              child: _buildLanguageDropdown(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _closeDropdown() {
    setState(() {
      _isDropdownOpen = false;
    });
    
    context.read<FuturisticUIState>().toggleLanguageDropdown();
    
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    if (!_isHovered) {
      _animationController.reverse();
    }
  }

  Widget _buildLanguageDropdown() {
    return Material(
      color: Colors.transparent,
      child: UnifiedGlassmorphicContainer.languageSelector(
        isDark: widget.isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Language.supportedLanguages
              .map((language) => _buildLanguageItem(language))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(Language language) {
    final isSelected = language.code == widget.currentLanguage.code;
    
    return InkWell(
      onTap: () => _selectLanguage(language),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: AnimationConfig.quickActionHover,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Animated flag
            TweenAnimationBuilder<double>(
              duration: AnimationConfig.quickActionHover,
              tween: Tween(begin: 0.8, end: isSelected ? 1.2 : 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Language name
            Expanded(
              child: Text(
                language.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (widget.isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(Language language) {
    if (language.code != widget.currentLanguage.code) {
      // Update state
      context.read<FuturisticUIState>().setCurrentLanguage(language);
      
      // Trigger callback
      widget.onLanguageChanged(language);
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Show transition animation for flag change
      _playFlagTransitionAnimation();
      
      // Language changed - removed snackbar feedback for cleaner UX
    }
    
    _closeDropdown();
  }

  void _playFlagTransitionAnimation() {
    // Create a smooth scale animation for the flag change
    _animationController.reset();
    _animationController.forward().then((_) {
      // Add a subtle bounce back
      _animationController.reverse().then((_) {
        _animationController.forward();
      });
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _overlayEntry?.remove();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuturisticUIState>(
      builder: (context, state, child) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: UnifiedGlassmorphicContainer.languageSelector(
                        isDark: widget.isDark,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isHovered || _isDropdownOpen
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: _glowAnimation.value,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current language flag
                              TweenAnimationBuilder<double>(
                                duration: AnimationConfig.languageTransition,
                                tween: Tween(
                                  begin: 1.0,
                                  end: _isHovered || _isDropdownOpen ? 1.1 : 1.0,
                                ),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Text(
                                      widget.currentLanguage.flag,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Language code
                              Text(
                                widget.currentLanguage.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: widget.isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              
                              const SizedBox(width: 4),
                              
                              // Dropdown arrow
                              AnimatedRotation(
                                turns: _isDropdownOpen ? 0.5 : 0.0,
                                duration: AnimationConfig.quickActionHover,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: widget.isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Language preference persistence helper
class LanguagePreferences {
  static const String _languageKey = 'selected_language';
  
  // In a real app, you would use SharedPreferences or similar
  static String? _savedLanguage;
  
  static Future<void> saveLanguage(String languageCode) async {
    _savedLanguage = languageCode;
    // TODO: Implement actual persistence with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString(_languageKey, languageCode);
  }
  
  static Future<String?> getSavedLanguage() async {
    // TODO: Implement actual persistence with SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString(_languageKey);
    return _savedLanguage;
  }
  
  static Language getLanguageByCode(String code) {
    return Language.supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.english,
    );
  }
}

/// RTL layout helper
class RTLHelper {
  static bool isRTL(Language language) {
    return language.isRTL;
  }
  
  static TextDirection getTextDirection(Language language) {
    return language.isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
  
  static EdgeInsets getDirectionalPadding({
    required Language language,
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) {
    if (language.isRTL) {
      return EdgeInsets.only(
        left: end,
        right: start,
        top: top,
        bottom: bottom,
      );
    } else {
      return EdgeInsets.only(
        left: start,
        right: end,
        top: top,
        bottom: bottom,
      );
    }
  }
  
  static Alignment getDirectionalAlignment({
    required Language language,
    Alignment ltrAlignment = Alignment.centerLeft,
    Alignment rtlAlignment = Alignment.centerRight,
  }) {
    return language.isRTL ? rtlAlignment : ltrAlignment;
  }
}