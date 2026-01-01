import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../core/widgets/enhanced_glassmorphic_container.dart';
import '../core/design/visual_enhancements.dart';
import '../core/constants.dart';
import 'location_detail_screen.dart';

/// Interactive Campus Map screen with clickable locations
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  double _mapScale = 1.0;
  Offset _mapOffset = Offset.zero;
  String? _selectedLocation;
  bool _showLocationDetails = false;

  // Campus locations with coordinates (relative to map size)
  final List<MapLocation> _campusLocations = [
    MapLocation(
      id: 'library',
      name: 'Library',
      position: const Offset(0.3, 0.4),
      icon: Icons.local_library_rounded,
      color: Colors.blue,
      description: 'State-of-the-art learning hub with vast collections',
    ),
    MapLocation(
      id: 'auditorium',
      name: 'Auditorium',
      position: const Offset(0.7, 0.3),
      icon: Icons.theater_comedy_rounded,
      color: Colors.purple,
      description: 'Premium venue for seminars and events',
    ),
    MapLocation(
      id: 'classrooms',
      name: 'Class Rooms',
      position: const Offset(0.5, 0.2),
      icon: Icons.school_rounded,
      color: Colors.green,
      description: 'Modern learning spaces with advanced technology',
    ),
    MapLocation(
      id: 'cafeteria',
      name: 'Cafeteria',
      position: const Offset(0.2, 0.7),
      icon: Icons.restaurant_rounded,
      color: Colors.orange,
      description: 'Vibrant dining space with diverse cuisine',
    ),
    MapLocation(
      id: 'playground',
      name: 'Playground',
      position: const Offset(0.8, 0.6),
      icon: Icons.sports_soccer_rounded,
      color: Colors.red,
      description: 'Expansive facilities for sports and recreation',
    ),
    MapLocation(
      id: 'swimming',
      name: 'Swimming Pool',
      position: const Offset(0.6, 0.8),
      icon: Icons.pool_rounded,
      color: Colors.cyan,
      description: 'Olympic-standard swimming facility',
    ),
    MapLocation(
      id: 'amphitheater',
      name: 'Amphitheater',
      position: const Offset(0.4, 0.6),
      icon: Icons.event_seat_rounded,
      color: Colors.indigo,
      description: 'Open-air venue for outdoor events',
    ),
    MapLocation(
      id: 'commonroom',
      name: 'Common Room',
      position: const Offset(0.1, 0.5),
      icon: Icons.people_rounded,
      color: Colors.teal,
      description: 'Collaborative space for student interactions',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Campus Map',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _resetMapView,
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: 'Reset View',
          ),
          IconButton(
            onPressed: _showMapLegend,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Map Legend',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Map controls
            _buildMapControls(isDark, size),
            
            // Interactive map
            Expanded(
              child: _buildInteractiveMap(isDark, size),
            ),
            
            // Location details panel
            if (_showLocationDetails && _selectedLocation != null)
              _buildLocationDetailsPanel(isDark, size),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(bool isDark, Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: EnhancedGlassmorphicContainer(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Interactive Campus Map',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildZoomControls(isDark),
        ],
      ),
    );
  }

  Widget _buildZoomControls(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _zoomIn,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
              boxShadow: VisualEnhancements.getSubtleShadow(isDark),
            ),
            child: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: _zoomOut,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
              boxShadow: VisualEnhancements.getSubtleShadow(isDark),
            ),
            child: Icon(
              Icons.remove_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMap(bool isDark, Size size) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: EnhancedGlassmorphicContainer(
          isDark: isDark,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onScaleStart: (details) {
                // Handle scale start
              },
              onScaleUpdate: (details) {
                setState(() {
                  _mapScale = (_mapScale * details.scale).clamp(0.5, 3.0);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _mapOffset += details.delta;
                });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1F2937),
                            const Color(0xFF374151),
                          ]
                        : [
                            const Color(0xFFE5F3FF),
                            const Color(0xFFB3E5FC),
                          ],
                  ),
                ),
                child: Transform.scale(
                  scale: _mapScale,
                  child: Transform.translate(
                    offset: _mapOffset,
                    child: Stack(
                      children: [
                        // Campus background
                        _buildCampusBackground(isDark),
                        
                        // Location markers
                        ..._campusLocations.map((location) => 
                          _buildLocationMarker(location, isDark, size)
                        ).toList(),
                        
                        // Pathways
                        _buildCampusPathways(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampusBackground(bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: CampusBackgroundPainter(isDark),
      ),
    );
  }

  Widget _buildCampusPathways(bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: CampusPathwaysPainter(isDark),
      ),
    );
  }

  Widget _buildLocationMarker(MapLocation location, bool isDark, Size size) {
    final isSelected = _selectedLocation == location.id;
    
    return Positioned(
      left: location.position.dx * size.width - 25,
      top: location.position.dy * size.height - 25,
      child: GestureDetector(
        onTap: () => _selectLocation(location),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSelected ? 60 : 50,
          height: isSelected ? 60 : 50,
          decoration: BoxDecoration(
            color: location.color.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: location.color.withOpacity(0.4),
                blurRadius: isSelected ? 20 : 12,
                spreadRadius: isSelected ? 4 : 2,
              ),
              ...VisualEnhancements.getElevatedShadow(isDark),
            ],
          ),
          child: Icon(
            location.icon,
            color: Colors.white,
            size: isSelected ? 28 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetailsPanel(bool isDark, Size size) {
    final location = _campusLocations.firstWhere(
      (loc) => loc.id == _selectedLocation,
    );
    
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: EnhancedGlassmorphicContainer(
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: location.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        location.icon,
                        color: location.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            location.description,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showLocationDetails = false;
                          _selectedLocation = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToLocation(location),
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Explore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: location.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _getDirections(location),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: location.color,
                          side: BorderSide(color: location.color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _selectLocation(MapLocation location) {
    setState(() {
      _selectedLocation = location.id;
      _showLocationDetails = true;
    });
  }

  void _navigateToLocation(MapLocation location) {
    // Find matching location card data
    final locationCard = AppConstants.locationCards.firstWhere(
      (card) => card.name.toLowerCase().contains(location.name.toLowerCase()) ||
                location.name.toLowerCase().contains(card.name.toLowerCase()),
      orElse: () => AppConstants.locationCards.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailScreen(
          locationName: locationCard.name,
          imagePath: locationCard.imagePath,
          locationData: locationCard,
        ),
      ),
    );
  }

  void _getDirections(MapLocation location) {
    // Show directions dialog
    showDialog(
      context: context,
      builder: (context) => _buildDirectionsDialog(location),
    );
  }

  Widget _buildDirectionsDialog(MapLocation location) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: EnhancedGlassmorphicContainer(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_rounded,
                    color: location.color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Directions to ${location.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Walking Directions:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Enter through the main gate\n'
                      '2. Follow the main pathway\n'
                      '3. Look for the ${location.name} signage\n'
                      '4. Estimated walking time: 3-5 minutes',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToLocation(location);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: location.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Virtual Tour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _mapScale = (_mapScale * 1.2).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _mapScale = (_mapScale / 1.2).clamp(0.5, 3.0);
    });
  }

  void _resetMapView() {
    setState(() {
      _mapScale = 1.0;
      _mapOffset = Offset.zero;
      _selectedLocation = null;
      _showLocationDetails = false;
    });
  }

  void _showMapLegend() {
    showDialog(
      context: context,
      builder: (context) => _buildMapLegendDialog(),
    );
  }

  Widget _buildMapLegendDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: EnhancedGlassmorphicContainer(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Map Legend',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: _campusLocations.map((location) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: location.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          location.icon,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        location.name,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tap on any location marker to view details and start exploring!',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map location data model
class MapLocation {
  final String id;
  final String name;
  final Offset position;
  final IconData icon;
  final Color color;
  final String description;

  MapLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Custom painter for campus background
class CampusBackgroundPainter extends CustomPainter {
  final bool isDark;

  CampusBackgroundPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw campus buildings as rectangles
    final buildings = [
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.3, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.15, size.width * 0.25, size.height * 0.25),
      Rect.fromLTWH(size.width * 0.15, size.height * 0.6, size.width * 0.4, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.7, size.height * 0.5, size.width * 0.2, size.height * 0.3),
    ];

    paint.color = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    for (final building in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, const Radius.circular(8)),
        paint,
      );
    }

    // Draw green areas (gardens/lawns)
    paint.color = isDark ? Colors.green[800]! : Colors.green[200]!;
    final greenAreas = [
      Rect.fromLTWH(size.width * 0.45, size.height * 0.4, size.width * 0.1, size.height * 0.1),
      Rect.fromLTWH(size.width * 0.05, size.height * 0.35, size.width * 0.15, size.height * 0.2),
    ];

    for (final area in greenAreas) {
      canvas.drawOval(area, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for campus pathways
class CampusPathwaysPainter extends CustomPainter {
  final bool isDark;

  CampusPathwaysPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey[600]! : Colors.grey[400]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Main pathway
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.5);
    
    // Cross pathways
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    
    // Curved pathways
    path.moveTo(size.width * 0.3, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.4,
      size.width * 0.7, size.height * 0.3,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}