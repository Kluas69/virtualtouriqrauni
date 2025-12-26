import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/Screens/webgl_room_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/themes/Themes.dart';

class PanoramaScreen extends StatefulWidget {
  final String locationName;

  const PanoramaScreen({super.key, required this.locationName});

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  bool _showHelpOverlay = false;
  bool _showInfoOverlay = false;
  bool _isFullScreen = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _currentLocation = '';
  double _zoomLevel = 1.0;

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.locationName;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _initPreferencesAndHelp();
    _hideControlsAfterDelay();
  }

  Future<void> _initPreferencesAndHelp() async {
    _prefs = await SharedPreferences.getInstance();
    final hasSeenHelp = _prefs.getBool('hasSeenPanoramaHelp') ?? false;

    if (!hasSeenHelp && mounted) {
      setState(() => _showHelpOverlay = true);
      await _prefs.setBool('hasSeenPanoramaHelp', true);
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isFullScreen && _showControls) {
        setState(() => _showControls = false);
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.reverse();
        _hideControlsAfterDelay();
      } else {
        _fadeController.forward();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
      _fadeController.reverse();
    });
  }

  void _zoomIn() {
    setState(() => _zoomLevel = (_zoomLevel * 0.9).clamp(0.5, 3.0));
    _showSnackBar('Zoomed In');
  }

  void _zoomOut() {
    setState(() => _zoomLevel = (_zoomLevel * 1.1).clamp(0.5, 3.0));
    _showSnackBar('Zoomed Out');
  }

  void _resetView() {
    setState(() => _zoomLevel = 1.0);
    _showSnackBar('View Reset');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleInfoOverlay() {
    setState(() => _showInfoOverlay = !_showInfoOverlay);
  }

  void _dismissHelpOverlay() {
    setState(() => _showHelpOverlay = false);
  }

  void _loadPanorama(String locationName) {
    final String? imagePath = AppConstants.panoramaImages[locationName];
    final String targetImage = imagePath ?? AppConstants.fallbackPanoramaImage;

    if (targetImage.isEmpty) {
      _showSnackBar('No panorama available for $locationName');
      return;
    }

    setState(() {
      _currentLocation = locationName;
      _zoomLevel = 1.0;
    });
  }

  void _openLocationFromHotspot(String targetLocation) {
    final viewType = AppConstants.viewTypeFor(targetLocation);

    if (viewType == 'webgl') {
      final url = AppConstants.webglUrlFor(targetLocation);
      if (url == null || url.isEmpty) {
        _showSnackBar('WebGL tour not available for $targetLocation');
        return;
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, _) => FadeTransition(
                opacity: animation,
                child: WebGlRoomScreen(title: targetLocation, url: url),
              ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    // Panorama navigation
    if (AppConstants.panoramaImages.containsKey(targetLocation)) {
      _loadPanorama(targetLocation);
    } else {
      _showSnackBar('Location not available: $targetLocation');
    }
  }

  List<Hotspot> _buildHotspots() {
    final hotspotsData = AppConstants.panoramaHotspots[_currentLocation] ?? [];

    return hotspotsData.map<Hotspot>((hotspot) {
      final String text = hotspot['text'] ?? 'Hotspot';
      final double pitch = (hotspot['pitch'] as num?)?.toDouble() ?? 0.0;
      final double yaw = (hotspot['yaw'] as num?)?.toDouble() ?? 0.0;
      final String type = hotspot['type'] ?? 'scene';
      final String? target = hotspot['sceneId'] as String?;

      return Hotspot(
        latitude: pitch,
        longitude: yaw,
        width: 100,
        height: 100,
        widget: GestureDetector(
          onTap: () {
            if (type == 'scene' && target != null) {
              _openLocationFromHotspot(target);
            } else if (type == 'info') {
              _showSnackBar(text);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.95),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              type == 'info' ? Icons.info_outline : Icons.arrow_forward,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? theme.primaryColor : Colors.grey.shade600,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final String panoramaImage =
        AppConstants.panoramaImages[_currentLocation] ??
        AppConstants.fallbackPanoramaImage;

    if (panoramaImage.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.panorama_photosphere_select,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No panorama available',
                style: GoogleFonts.roboto(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Panorama Viewer
          Panorama(
            animSpeed: 1.0,
            sensitivity: 2.0,
            zoom: _zoomLevel,
            hotspots: _buildHotspots(),
            onTap: (longitude, latitude, tilt) => _toggleControls(),
            child: Image.asset(
              panoramaImage,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey.shade900,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Failed to load panorama',
                            style: GoogleFonts.roboto(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),

          // Fade overlay when controls are hidden
          if (!_showControls)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),

          // Top Bar Controls with glassmorphism
          if (_showControls)
            SafeArea(
              child: FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.black.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildControlButton(
                              icon: Icons.arrow_back,
                              tooltip: 'Back',
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _currentLocation,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            _buildControlButton(
                              icon: Icons.info_outline,
                              tooltip: 'Location Info',
                              onPressed: _toggleInfoOverlay,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Controls with glassmorphism
          if (_showControls)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildControlButton(
                                icon: Icons.zoom_in,
                                tooltip: 'Zoom In',
                                onPressed: _zoomIn,
                              ),
                              const SizedBox(width: 16),
                              _buildControlButton(
                                icon: Icons.zoom_out,
                                tooltip: 'Zoom Out',
                                onPressed: _zoomOut,
                              ),
                              const SizedBox(width: 16),
                              _buildControlButton(
                                icon: Icons.refresh,
                                tooltip: 'Reset View',
                                onPressed: _resetView,
                              ),
                              const SizedBox(width: 24),
                              _buildControlButton(
                                icon:
                                    _isFullScreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                tooltip: 'Toggle Fullscreen',
                                onPressed: _toggleFullScreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // First-Time Help Overlay
          if (_showHelpOverlay)
            FadeIn(
              duration: const Duration(milliseconds: 400),
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey.shade900.withOpacity(0.95)
                                    : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.panorama_photosphere,
                                size: 64,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome to 360° Virtual Tour',
                                style: GoogleFonts.roboto(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _buildHelpItem(
                                Icons.touch_app,
                                'Drag to look around',
                              ),
                              _buildHelpItem(
                                Icons.pinch,
                                'Pinch to zoom in/out',
                              ),
                              _buildHelpItem(
                                Icons.control_camera,
                                'Tap glowing hotspots to navigate',
                              ),
                              _buildHelpItem(
                                Icons.touch_app_outlined,
                                'Tap anywhere to toggle controls',
                              ),
                              const SizedBox(height: 32),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _dismissHelpOverlay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Got It!',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
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
              ),
            ),

          // Info Overlay
          if (_showInfoOverlay)
            FadeIn(
              duration: const Duration(milliseconds: 400),
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey.shade900.withOpacity(0.95)
                                    : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 56,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentLocation,
                                style: GoogleFonts.roboto(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Explore this location in immersive 360° view. Navigate using hotspots to discover connected areas.',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    onPressed: _toggleInfoOverlay,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.primaryColor,
                                      side: BorderSide(
                                        color: theme.primaryColor,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      'Close',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  _,
                                                ) => FadeTransition(
                                                  opacity: animation,
                                                  child: LocationDetailScreen(
                                                    locationName:
                                                        _currentLocation,
                                                    imagePath:
                                                        AppConstants
                                                            .panoramaImages[_currentLocation] ??
                                                        'lib/images/fallback.jpg',
                                                    locationData: AppConstants
                                                        .locationCards
                                                        .firstWhere(
                                                          (card) =>
                                                              card.title ==
                                                              _currentLocation,
                                                          orElse:
                                                              () => LocationCardData(
                                                                title:
                                                                    _currentLocation,
                                                                imagePath:
                                                                    'lib/images/fallback.jpg',
                                                                tag: '',
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                            transitionDuration: const Duration(
                                              milliseconds: 400,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'More Details',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
