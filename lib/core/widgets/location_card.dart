// lib/core/widgets/location_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';

/// Premium Google-inspired Location Card with Material 3 design
class LocationCard extends StatefulWidget {
  final LocationCardData data;
  final bool isHovered;
  final VoidCallback? onTap;
  final bool isCompact;

  const LocationCard({
    super.key,
    required this.data,
    this.isHovered = false,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _borderAnimation;

  bool _internalHovered = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  bool get _isHovered => widget.isHovered || _internalHovered;

  String get _shortDescription {
    final features = AppConstants.locationFeatures[widget.data.title] ?? [];
    return features.isNotEmpty
        ? (features[0]['description'] as String? ?? 'Explore this facility')
        : 'Explore this beautiful campus facility';
  }

  void _navigateToDetails() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder:
            (context, animation, _) => FadeTransition(
              opacity: animation,
              child: LocationDetailScreen(
                locationName: widget.data.title,
                imagePath: widget.data.imagePath,
                locationData: widget.data,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _internalHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _internalHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: _navigateToDetails,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.isCompact ? 16.0 : (isSmallScreen ? 20.0 : 24.0),
                  ),
                  boxShadow: [
                    // Primary colored shadow on hover (Google-style)
                    BoxShadow(
                      color: primaryColor.withOpacity(_isHovered ? 0.25 : 0.0),
                      blurRadius: _elevationAnimation.value * 1.5,
                      spreadRadius: _isHovered ? 1 : 0,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                    // Standard shadow
                    BoxShadow(
                      color:
                          isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.black.withOpacity(0.12),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    widget.isCompact ? 16.0 : (isSmallScreen ? 20.0 : 24.0),
                  ),
                  child: InkWell(
                    onTap: _navigateToDetails,
                    borderRadius: BorderRadius.circular(
                      widget.isCompact ? 16.0 : (isSmallScreen ? 20.0 : 24.0),
                    ),
                    splashColor: primaryColor.withOpacity(0.1),
                    highlightColor: primaryColor.withOpacity(0.05),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          widget.isCompact
                              ? 16.0
                              : (isSmallScreen ? 20.0 : 24.0),
                        ),
                        border: Border.all(
                          color:
                              _isHovered
                                  ? primaryColor.withOpacity(0.3)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.05)),
                          width: _isHovered ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.isCompact
                              ? 16.0
                              : (isSmallScreen ? 20.0 : 24.0),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image with optimized aspect ratio
                            Positioned.fill(
                              child: Image.asset(
                                widget.data.imagePath,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryColor.withOpacity(0.2),
                                            primaryColor.withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 48,
                                          color:
                                              isDark
                                                  ? Colors.white.withOpacity(
                                                    0.3,
                                                  )
                                                  : Colors.black.withOpacity(
                                                    0.2,
                                                  ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),

                            // Gradient overlay - Google Material style
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors:
                                      _isHovered
                                          ? [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                            Colors.black.withOpacity(0.75),
                                          ]
                                          : [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.2),
                                            Colors.black.withOpacity(0.65),
                                          ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),

                            // Tag badge - modern minimal design
                            if (widget.data.tag.isNotEmpty)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: widget.isCompact ? 10 : 12,
                                      vertical: widget.isCompact ? 5 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.white.withOpacity(0.15)
                                              : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isDark
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.data.tag.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : primaryColor,
                                        fontSize: widget.isCompact ? 9 : 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Content section - Google card style
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(
                                  widget.isCompact
                                      ? 16
                                      : (isSmallScreen ? 20 : 24),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title with perfect typography
                                    Text(
                                      widget.data.title,
                                      style: GoogleFonts.roboto(
                                        fontSize:
                                            widget.isCompact
                                                ? 18
                                                : (isSmallScreen ? 20 : 24),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.3,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Description on hover
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeInOut,
                                      child:
                                          _isHovered
                                              ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height:
                                                        widget.isCompact
                                                            ? 8
                                                            : 10,
                                                  ),
                                                  Text(
                                                    _shortDescription,
                                                    style: GoogleFonts.roboto(
                                                      fontSize:
                                                          widget.isCompact
                                                              ? 12
                                                              : (isSmallScreen
                                                                  ? 13
                                                                  : 14),
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      height: 1.5,
                                                      letterSpacing: 0.2,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              )
                                              : const SizedBox.shrink(),
                                    ),

                                    // Action button on hover
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeInOut,
                                      child:
                                          _isHovered
                                              ? Column(
                                                children: [
                                                  SizedBox(
                                                    height:
                                                        widget.isCompact
                                                            ? 12
                                                            : 16,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          height:
                                                              widget.isCompact
                                                                  ? 36
                                                                  : 42,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  widget.isCompact
                                                                      ? 8
                                                                      : 12,
                                                                ),
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                primaryColor,
                                                                primaryColor
                                                                    .withOpacity(
                                                                      0.8,
                                                                    ),
                                                              ],
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: primaryColor
                                                                    .withOpacity(
                                                                      0.4,
                                                                    ),
                                                                blurRadius: 12,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      4,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Material(
                                                            color:
                                                                Colors
                                                                    .transparent,
                                                            child: InkWell(
                                                              onTap:
                                                                  _navigateToDetails,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    widget.isCompact
                                                                        ? 8
                                                                        : 12,
                                                                  ),
                                                              child: Center(
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      'Explore Now',
                                                                      style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            widget.isCompact
                                                                                ? 13
                                                                                : 14,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color:
                                                                            Colors.white,
                                                                        letterSpacing:
                                                                            0.5,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .arrow_forward,
                                                                      size:
                                                                          widget.isCompact
                                                                              ? 16
                                                                              : 18,
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
