import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/futuristic_ui_state.dart';
import '../performance/performance_monitor.dart';

/// Floating shapes background with interactive response
class FloatingShapesBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool enableInteraction;
  final bool respectMotionPreferences;

  const FloatingShapesBackground({
    super.key,
    required this.child,
    required this.isDark,
    this.enableInteraction = true,
    this.respectMotionPreferences = true,
  });

  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _idleController;
  late Animation<double> _idleAnimation;
  
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  bool _isReducedMotion = false;
  bool _isHighPerformance = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupPerformanceMonitoring();
    _initializeShapes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _idleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _idleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupPerformanceMonitoring() {
    _performanceMonitor.addFpsCallback(_onFpsUpdate);
    _performanceMonitor.addStatusCallback(_onPerformanceStatusUpdate);
  }

  void _onFpsUpdate(double fps) {
    if (mounted) {
      final shouldReduce = fps < AnimationConfig.minFPS;
      if (shouldReduce != _isReducedMotion) {
        setState(() {
          _isReducedMotion = shouldReduce;
        });
        _updateShapesForPerformance();
      }
    }
  }

  void _onPerformanceStatusUpdate(PerformanceStatus status) {
    if (mounted) {
      final isHigh = status == PerformanceStatus.good;
      if (isHigh != _isHighPerformance) {
        setState(() {
          _isHighPerformance = isHigh;
        });
        _updateShapesForPerformance();
      }
    }
  }

  void _initializeShapes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      context.read<FuturisticUIState>().initializeShapes(size);
    });
  }

  void _updateShapesForPerformance() {
    final state = context.read<FuturisticUIState>();
    if (_isReducedMotion) {
      state.setReducedMotion(true);
    }
  }

  void _handleMouseMove(PointerEvent event) {
    if (!widget.enableInteraction) return;
    
    context.read<FuturisticUIState>().updateMousePosition(event.localPosition);
  }

  void _handleScroll(ScrollNotification notification) {
    if (!widget.enableInteraction) return;
    
    context.read<FuturisticUIState>().updateScrollOffset(notification.metrics.pixels);
  }

  @override
  void dispose() {
    _performanceMonitor.removeFpsCallback(_onFpsUpdate);
    _performanceMonitor.removeStatusCallback(_onPerformanceStatusUpdate);
    _animationController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuturisticUIState>(
      builder: (context, state, child) {
        // Start idle animation if in idle mode
        if (state.isIdleMode && !_idleController.isAnimating) {
          _idleController.repeat(reverse: true);
        } else if (!state.isIdleMode && _idleController.isAnimating) {
          _idleController.stop();
        }

        return MouseRegion(
          onHover: _handleMouseMove,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _handleScroll(notification);
              return false;
            },
            child: Stack(
              children: [
                // Floating shapes layer
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _animationController,
                      _idleController,
                    ]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: FloatingShapesPainter(
                          shapes: state.shapes,
                          mousePosition: state.mousePosition,
                          scrollOffset: state.scrollOffset,
                          animationValue: _animationController.value,
                          idleAnimationValue: state.isIdleMode ? _idleAnimation.value : 1.0,
                          isDark: widget.isDark,
                          isReducedMotion: _isReducedMotion,
                        ),
                      );
                    },
                  ),
                ),
                
                // Content layer
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for floating shapes
class FloatingShapesPainter extends CustomPainter {
  final List<FloatingShape> shapes;
  final Offset mousePosition;
  final double scrollOffset;
  final double animationValue;
  final double idleAnimationValue;
  final bool isDark;
  final bool isReducedMotion;

  FloatingShapesPainter({
    required this.shapes,
    required this.mousePosition,
    required this.scrollOffset,
    required this.animationValue,
    required this.idleAnimationValue,
    required this.isDark,
    required this.isReducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      _updateShapePosition(shape, size, i);
      _drawShape(canvas, shape, size, i);
    }
  }

  void _updateShapePosition(FloatingShape shape, Size size, int index) {
    if (isReducedMotion) return;

    // Base movement
    final baseSpeed = shape.rotationSpeed * 50;
    shape.position = Offset(
      (shape.position.dx + baseSpeed * animationValue) % size.width,
      (shape.position.dy + baseSpeed * 0.5 * animationValue) % size.height,
    );

    // Mouse parallax effect
    if (mousePosition != Offset.zero) {
      final parallaxOffset = AnimationUtils.calculateMouseParallax(
        mousePosition: mousePosition,
        screenSize: size,
        sensitivity: 20 + (index % 3) * 10,
      );
      
      shape.position = Offset(
        shape.position.dx + parallaxOffset.dx,
        shape.position.dy + parallaxOffset.dy,
      );
    }

    // Scroll effect
    if (scrollOffset > 0) {
      final scrollParallax = AnimationUtils.calculateParallaxOffset(
        scrollOffset: scrollOffset,
        sensitivity: 10 + (index % 2) * 5,
        screenSize: size,
      );
      
      shape.position = Offset(
        shape.position.dx + scrollParallax.dx,
        shape.position.dy + scrollParallax.dy,
      );
    }

    // Update rotation
    shape.rotation += shape.rotationSpeed * animationValue;
  }

  void _drawShape(Canvas canvas, FloatingShape shape, Size size, int index) {
    final paint = Paint()
      ..color = shape.color.withOpacity(
        shape.opacity * (isReducedMotion ? 0.5 : 1.0) * idleAnimationValue,
      )
      ..style = PaintingStyle.fill;

    // Add blur effect for depth
    final blurPaint = Paint()
      ..color = shape.color.withOpacity(shape.opacity * 0.3)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (shape.size * 0.1) + (index % 3) * 2,
      );

    canvas.save();
    canvas.translate(shape.position.dx, shape.position.dy);
    
    // Apply idle animation scale
    final scale = isReducedMotion ? 1.0 : idleAnimationValue;
    canvas.scale(scale);
    
    canvas.rotate(shape.rotation);

    // Draw blur layer first
    _drawShapeGeometry(canvas, shape, blurPaint);
    
    // Draw main shape
    _drawShapeGeometry(canvas, shape, paint);

    canvas.restore();
  }

  void _drawShapeGeometry(Canvas canvas, FloatingShape shape, Paint paint) {
    final radius = shape.size / 2;
    
    switch (shape.type) {
      case ShapeType.circle:
        canvas.drawCircle(Offset.zero, radius, paint);
        break;
        
      case ShapeType.triangle:
        _drawTriangle(canvas, shape.size, paint);
        break;
        
      case ShapeType.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: shape.size,
            height: shape.size,
          ),
          paint,
        );
        break;
        
      case ShapeType.hexagon:
        _drawHexagon(canvas, radius, paint);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final height = size * 0.866; // Equilateral triangle height
    
    path.moveTo(0, -height / 2);
    path.lineTo(-size / 2, height / 2);
    path.lineTo(size / 2, height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const angleStep = pi / 3; // 60 degrees
    
    for (int i = 0; i < 6; i++) {
      final angle = i * angleStep;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FloatingShapesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.mousePosition != mousePosition ||
           oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.idleAnimationValue != idleAnimationValue ||
           oldDelegate.shapes.length != shapes.length;
  }
}

/// Motion preferences detector
class MotionPreferences {
  static bool _reducedMotion = false;
  
  static bool get isReducedMotion => _reducedMotion;
  
  static void setReducedMotion(bool reduced) {
    _reducedMotion = reduced;
  }
  
  // In a real app, you would detect this from system preferences
  static Future<bool> detectReducedMotion() async {
    // TODO: Implement actual system preference detection
    // On web: window.matchMedia('(prefers-reduced-motion: reduce)').matches
    // On mobile: Use platform channels to check accessibility settings
    return _reducedMotion;
  }
}

/// Shape factory for creating different types of floating shapes
class ShapeFactory {
  static final Random _random = Random();
  
  static FloatingShape createRandomShape(Size screenSize, bool isDark) {
    final colors = isDark
        ? [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
            Colors.teal.withOpacity(0.3),
            Colors.indigo.withOpacity(0.3),
            Colors.cyan.withOpacity(0.3),
          ]
        : [
            Colors.blue.withOpacity(0.2),
            Colors.purple.withOpacity(0.2),
            Colors.teal.withOpacity(0.2),
            Colors.indigo.withOpacity(0.2),
            Colors.cyan.withOpacity(0.2),
          ];
    
    return FloatingShape(
      position: Offset(
        _random.nextDouble() * screenSize.width,
        _random.nextDouble() * screenSize.height,
      ),
      size: _random.nextDouble() * 60 + 20,
      color: colors[_random.nextInt(colors.length)],
      type: ShapeType.values[_random.nextInt(ShapeType.values.length)],
      opacity: AnimationConfig.shapeBaseOpacity + _random.nextDouble() * 0.1,
      rotationSpeed: _random.nextDouble() * 0.02 + 0.005,
    );
  }
  
  static List<FloatingShape> createShapeSet(Size screenSize, bool isDark, int count) {
    return List.generate(count, (_) => createRandomShape(screenSize, isDark));
  }
}