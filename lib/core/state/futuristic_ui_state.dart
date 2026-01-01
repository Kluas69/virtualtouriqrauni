import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../animation/animation_config.dart';

/// Enhanced state management for futuristic UI components
class FuturisticUIState extends ChangeNotifier {
  // Search state
  String _searchQuery = '';
  List<SearchSuggestion> _suggestions = [];
  bool _isSearchExpanded = false;
  bool _isVoiceListening = false;
  List<String> _searchHistory = [];
  
  // Language state
  Language _currentLanguage = Language.english;
  bool _isLanguageDropdownOpen = false;
  
  // 3D Carousel state
  int _selectedCarouselIndex = 0;
  bool _isCarouselInteracting = false;
  double _carouselPerspective = 0.0;
  
  // Quick Actions state
  int _hoveredActionIndex = -1;
  bool _isActionAnimating = false;
  
  // Social proof state
  int _currentTestimonialIndex = 0;
  Timer? _testimonialTimer;
  bool _isTestimonialExpanded = false;
  
  // Floating shapes state
  List<FloatingShape> _shapes = [];
  Offset _mousePosition = Offset.zero;
  double _scrollOffset = 0.0;
  bool _isIdleMode = false;
  Timer? _idleTimer;
  
  // Performance state
  double _currentFPS = AnimationConfig.targetFPS.toDouble();
  bool _isReducedMotion = false;
  bool _isHighPerformanceMode = true;
  
  // Getters
  String get searchQuery => _searchQuery;
  List<SearchSuggestion> get suggestions => _suggestions;
  bool get isSearchExpanded => _isSearchExpanded;
  bool get isVoiceListening => _isVoiceListening;
  List<String> get searchHistory => _searchHistory;
  
  Language get currentLanguage => _currentLanguage;
  bool get isLanguageDropdownOpen => _isLanguageDropdownOpen;
  
  int get selectedCarouselIndex => _selectedCarouselIndex;
  bool get isCarouselInteracting => _isCarouselInteracting;
  double get carouselPerspective => _carouselPerspective;
  
  int get hoveredActionIndex => _hoveredActionIndex;
  bool get isActionAnimating => _isActionAnimating;
  
  int get currentTestimonialIndex => _currentTestimonialIndex;
  bool get isTestimonialExpanded => _isTestimonialExpanded;
  
  List<FloatingShape> get shapes => _shapes;
  Offset get mousePosition => _mousePosition;
  double get scrollOffset => _scrollOffset;
  bool get isIdleMode => _isIdleMode;
  
  double get currentFPS => _currentFPS;
  bool get isReducedMotion => _isReducedMotion;
  bool get isHighPerformanceMode => _isHighPerformanceMode;
  
  // Search methods
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _updateSearchSuggestions();
    notifyListeners();
  }
  
  void toggleSearchExpanded() {
    _isSearchExpanded = !_isSearchExpanded;
    notifyListeners();
  }
  
  void setVoiceListening(bool listening) {
    _isVoiceListening = listening;
    notifyListeners();
  }
  
  void addToSearchHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
      notifyListeners();
    }
  }
  
  void _updateSearchSuggestions() {
    // Enhanced AI suggestions with more comprehensive data
    if (_searchQuery.isEmpty) {
      _suggestions = [];
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    final allSuggestions = [
      // Location suggestions
      SearchSuggestion(
        title: 'Library',
        subtitle: 'Study spaces, books, and digital resources',
        icon: Icons.library_books_rounded,
        type: SearchType.location,
        route: '/library',
      ),
      SearchSuggestion(
        title: 'Auditorium',
        subtitle: 'Events, seminars, and presentations',
        icon: Icons.theater_comedy_rounded,
        type: SearchType.location,
        route: '/auditorium',
      ),
      SearchSuggestion(
        title: 'Class Rooms',
        subtitle: 'Modern learning spaces with smart boards',
        icon: Icons.school_rounded,
        type: SearchType.location,
        route: '/classrooms',
      ),
      SearchSuggestion(
        title: 'Cafeteria',
        subtitle: 'Dining area with diverse food options',
        icon: Icons.restaurant_rounded,
        type: SearchType.location,
        route: '/cafeteria',
      ),
      SearchSuggestion(
        title: 'Swimming Pool',
        subtitle: 'Olympic-standard aquatic facility',
        icon: Icons.pool_rounded,
        type: SearchType.location,
        route: '/pool',
      ),
      SearchSuggestion(
        title: 'Playground',
        subtitle: 'Sports courts and recreational areas',
        icon: Icons.sports_soccer_rounded,
        type: SearchType.location,
        route: '/playground',
      ),
      
      // Feature suggestions
      SearchSuggestion(
        title: 'Virtual Tour',
        subtitle: 'Start interactive campus exploration',
        icon: Icons.explore_rounded,
        type: SearchType.action,
        route: '/tour',
      ),
      SearchSuggestion(
        title: 'Admissions',
        subtitle: 'Application process and requirements',
        icon: Icons.assignment_rounded,
        type: SearchType.information,
        route: '/admissions',
      ),
      SearchSuggestion(
        title: 'Contact Information',
        subtitle: 'Phone, email, and office locations',
        icon: Icons.contact_phone_rounded,
        type: SearchType.information,
        route: '/contact',
      ),
      SearchSuggestion(
        title: 'Events Calendar',
        subtitle: 'Upcoming activities and important dates',
        icon: Icons.event_rounded,
        type: SearchType.information,
        route: '/events',
      ),
      SearchSuggestion(
        title: 'Downloads',
        subtitle: 'Brochures, forms, and resources',
        icon: Icons.download_rounded,
        type: SearchType.information,
        route: '/downloads',
      ),
    ];
    
    // Smart filtering with multiple criteria
    _suggestions = allSuggestions.where((suggestion) {
      final titleMatch = suggestion.title.toLowerCase().contains(query);
      final subtitleMatch = suggestion.subtitle.toLowerCase().contains(query);
      final typeMatch = suggestion.type.toString().toLowerCase().contains(query);
      
      return titleMatch || subtitleMatch || typeMatch;
    }).take(6).toList(); // Limit to 6 suggestions like Google
  }
  
  // Language methods
  void setCurrentLanguage(Language language) {
    _currentLanguage = language;
    notifyListeners();
  }
  
  void toggleLanguageDropdown() {
    _isLanguageDropdownOpen = !_isLanguageDropdownOpen;
    notifyListeners();
  }
  
  // Carousel methods
  void setSelectedCarouselIndex(int index) {
    _selectedCarouselIndex = index;
    notifyListeners();
  }
  
  void setCarouselInteracting(bool interacting) {
    _isCarouselInteracting = interacting;
    notifyListeners();
  }
  
  void updateCarouselPerspective(double perspective) {
    _carouselPerspective = perspective;
    notifyListeners();
  }
  
  // Quick Actions methods
  void setHoveredActionIndex(int index) {
    _hoveredActionIndex = index;
    notifyListeners();
  }
  
  void setActionAnimating(bool animating) {
    _isActionAnimating = animating;
    notifyListeners();
  }
  
  // Social proof methods
  void startTestimonialRotation() {
    _testimonialTimer?.cancel();
    _testimonialTimer = Timer.periodic(AnimationConfig.testimonialRotation, (timer) {
      _currentTestimonialIndex = (_currentTestimonialIndex + 1) % 5; // Assuming 5 testimonials
      notifyListeners();
    });
  }
  
  void stopTestimonialRotation() {
    _testimonialTimer?.cancel();
  }
  
  void setTestimonialExpanded(bool expanded) {
    _isTestimonialExpanded = expanded;
    notifyListeners();
  }
  
  // Floating shapes methods
  void initializeShapes(Size screenSize) {
    final random = Random();
    final shapeCount = _isReducedMotion ? AnimationConfig.reducedMotionShapes : AnimationConfig.maxShapes;
    
    _shapes = List.generate(shapeCount, (index) {
      return FloatingShape(
        position: Offset(
          random.nextDouble() * screenSize.width,
          random.nextDouble() * screenSize.height,
        ),
        size: random.nextDouble() * 60 + 20,
        color: _generateRandomColor(),
        type: ShapeType.values[random.nextInt(ShapeType.values.length)],
        opacity: AnimationConfig.shapeBaseOpacity + random.nextDouble() * 0.1,
        rotationSpeed: random.nextDouble() * 0.02 + 0.005,
      );
    });
    notifyListeners();
  }
  
  Color _generateRandomColor() {
    final colors = [
      Colors.blue.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
      Colors.teal.withOpacity(0.3),
      Colors.indigo.withOpacity(0.3),
      Colors.cyan.withOpacity(0.3),
    ];
    return colors[Random().nextInt(colors.length)];
  }
  
  void updateMousePosition(Offset position) {
    _mousePosition = position;
    _resetIdleTimer();
    notifyListeners();
  }
  
  void updateScrollOffset(double offset) {
    _scrollOffset = offset;
    _resetIdleTimer();
    notifyListeners();
  }
  
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _isIdleMode = false;
    _idleTimer = Timer(AnimationConfig.floatingShapeIdle, () {
      _isIdleMode = true;
      notifyListeners();
    });
  }
  
  // Performance methods
  void updateFPS(double fps) {
    _currentFPS = fps;
    
    // Auto-adjust performance based on FPS
    if (fps < AnimationConfig.minFPS && _isHighPerformanceMode) {
      _isHighPerformanceMode = false;
      _reduceShapeCount();
      notifyListeners();
    } else if (fps > AnimationConfig.targetFPS * 0.9 && !_isHighPerformanceMode) {
      _isHighPerformanceMode = true;
      notifyListeners();
    }
  }
  
  void setReducedMotion(bool reduced) {
    _isReducedMotion = reduced;
    if (reduced) {
      _reduceShapeCount();
    }
    notifyListeners();
  }
  
  void _reduceShapeCount() {
    if (_shapes.length > AnimationConfig.reducedMotionShapes) {
      _shapes = _shapes.take(AnimationConfig.reducedMotionShapes).toList();
    }
  }
  
  @override
  void dispose() {
    _testimonialTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }
}

// Supporting classes
class SearchSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final SearchType type;
  final String route;
  
  const SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.route,
  });
}

enum SearchType {
  location,
  feature,
  information,
  action,
}

class Language {
  final String code;
  final String name;
  final String flag;
  final bool isRTL;
  
  const Language({
    required this.code,
    required this.name,
    required this.flag,
    required this.isRTL,
  });
  
  static const english = Language(
    code: 'en',
    name: 'English',
    flag: '🇺🇸',
    isRTL: false,
  );
  
  static const urdu = Language(
    code: 'ur',
    name: 'اردو',
    flag: '🇵🇰',
    isRTL: true,
  );
  
  static const arabic = Language(
    code: 'ar',
    name: 'العربية',
    flag: '🇸🇦',
    isRTL: true,
  );
  
  static const chinese = Language(
    code: 'zh',
    name: '中文',
    flag: '🇨🇳',
    isRTL: false,
  );
  
  static const List<Language> supportedLanguages = [
    english,
    urdu,
    arabic,
    chinese,
  ];
}

class FloatingShape {
  Offset position;
  final double size;
  final Color color;
  final ShapeType type;
  final double opacity;
  final double rotationSpeed;
  double rotation;
  
  FloatingShape({
    required this.position,
    required this.size,
    required this.color,
    required this.type,
    required this.opacity,
    required this.rotationSpeed,
    this.rotation = 0.0,
  });
}

enum ShapeType {
  circle,
  triangle,
  square,
  hexagon,
}