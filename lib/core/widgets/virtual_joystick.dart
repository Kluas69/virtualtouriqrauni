import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Type of joystick for different control purposes
enum JoystickType { movement, camera }

/// Virtual joystick widget for mobile gaming controls
class VirtualJoystick extends StatefulWidget {
  final double size;
  final Color baseColor;
  final Color knobColor;
  final Function(Offset) onChanged;
  final bool enableHaptic;
  final JoystickType type;
  final double deadZone;
  final bool showDirections;

  const VirtualJoystick({
    super.key,
    this.size = 120.0,
    this.baseColor = const Color(0xFF2C2C2C),
    this.knobColor = const Color(0xFF4CAF50),
    required this.onChanged,
    this.enableHaptic = true,
    this.type = JoystickType.movement,
    this.deadZone = 0.1,
    this.showDirections = false,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;
  double _knobRadius = 0;
  double _baseRadius = 0;

  @override
  void initState() {
    super.initState();
    _baseRadius = widget.size / 2;
    _knobRadius = _baseRadius * 0.4;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
    
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(_baseRadius, _baseRadius);
    final delta = details.localPosition - center;
    final distance = delta.distance;
    
    if (distance <= _baseRadius - _knobRadius) {
      _knobPosition = delta;
    } else {
      // Constrain knob to circle boundary
      final angle = math.atan2(delta.dy, delta.dx);
      final maxDistance = _baseRadius - _knobRadius;
      _knobPosition = Offset(
        math.cos(angle) * maxDistance,
        math.sin(angle) * maxDistance,
      );
    }
    
    setState(() {});
    
    // Calculate normalized output (-1 to 1)
    final normalizedX = _knobPosition.dx / (_baseRadius - _knobRadius);
    final normalizedY = _knobPosition.dy / (_baseRadius - _knobRadius);
    
    // Apply dead zone
    final magnitude = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
    if (magnitude > widget.deadZone) {
      widget.onChanged(Offset(normalizedX, normalizedY));
    } else {
      widget.onChanged(Offset.zero);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _knobPosition = Offset.zero;
    });
    
    _animationController.reverse();
    widget.onChanged(Offset.zero);
    
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _JoystickPainter(
                  baseColor: widget.baseColor,
                  knobColor: widget.knobColor,
                  knobPosition: _knobPosition,
                  isDragging: _isDragging,
                  baseRadius: _baseRadius,
                  knobRadius: _knobRadius,
                  type: widget.type,
                  showDirections: widget.showDirections,
                ),
                size: Size(widget.size, widget.size),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Color baseColor;
  final Color knobColor;
  final Offset knobPosition;
  final bool isDragging;
  final double baseRadius;
  final double knobRadius;
  final JoystickType type;
  final bool showDirections;

  _JoystickPainter({
    required this.baseColor,
    required this.knobColor,
    required this.knobPosition,
    required this.isDragging,
    required this.baseRadius,
    required this.knobRadius,
    required this.type,
    required this.showDirections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(baseRadius, baseRadius);
    
    // Draw base circle with gradient
    final baseGradient = RadialGradient(
      colors: [
        baseColor.withValues(alpha: 0.3),
        baseColor.withValues(alpha: 0.8),
      ],
    );
    
    final basePaint = Paint()
      ..shader = baseGradient.createShader(
        Rect.fromCircle(center: center, radius: baseRadius),
      );
    
    canvas.drawCircle(center, baseRadius, basePaint);
    
    // Draw base border
    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, baseRadius, borderPaint);
    
    // Draw directional indicators if enabled
    if (showDirections) {
      _drawDirectionalIndicators(canvas, center);
    }
    
    // Draw knob
    final knobCenter = center + knobPosition;
    
    // Knob shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(knobCenter + const Offset(2, 2), knobRadius, shadowPaint);
    
    // Knob gradient
    final knobGradient = RadialGradient(
      colors: [
        knobColor.withValues(alpha: 0.9),
        knobColor,
      ],
    );
    
    final knobPaint = Paint()
      ..shader = knobGradient.createShader(
        Rect.fromCircle(center: knobCenter, radius: knobRadius),
      );
    
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);
    
    // Knob border
    final knobBorderPaint = Paint()
      ..color = isDragging ? Colors.white : knobColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDragging ? 3.0 : 2.0;
    
    canvas.drawCircle(knobCenter, knobRadius, knobBorderPaint);
    
    // Draw type-specific icon
    _drawTypeIcon(canvas, knobCenter);
  }

  void _drawDirectionalIndicators(Canvas canvas, Offset center) {
    final indicatorPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    
    final indicatorRadius = baseRadius * 0.7;
    
    // Draw cross lines
    canvas.drawLine(
      center + Offset(-indicatorRadius, 0),
      center + Offset(indicatorRadius, 0),
      indicatorPaint,
    );
    canvas.drawLine(
      center + Offset(0, -indicatorRadius),
      center + Offset(0, indicatorRadius),
      indicatorPaint,
    );
  }

  void _drawTypeIcon(Canvas canvas, Offset center) {
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final iconSize = knobRadius * 0.6;
    
    switch (type) {
      case JoystickType.movement:
        // Draw movement arrows
        _drawArrow(canvas, center, iconPaint, iconSize, 0); // Right
        _drawArrow(canvas, center, iconPaint, iconSize, math.pi / 2); // Down
        _drawArrow(canvas, center, iconPaint, iconSize, math.pi); // Left
        _drawArrow(canvas, center, iconPaint, iconSize, -math.pi / 2); // Up
        break;
      case JoystickType.camera:
        // Draw eye icon
        final eyeRect = Rect.fromCenter(
          center: center,
          width: iconSize * 1.5,
          height: iconSize,
        );
        canvas.drawOval(eyeRect, iconPaint);
        
        final pupilPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, iconSize * 0.3, pupilPaint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset center, Paint paint, double size, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final path = Path();
    path.moveTo(size * 0.3, 0);
    path.lineTo(0, -size * 0.3);
    path.moveTo(size * 0.3, 0);
    path.lineTo(0, size * 0.3);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}