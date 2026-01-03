import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'virtual_joystick.dart';
import '../mobile/haptic_feedback_service.dart';

/// Mobile 3D controls overlay for gaming experience
class Mobile3DControls extends StatefulWidget {
  final Function(Offset) onMovementChanged;
  final Function(Offset) onCameraChanged;
  final VoidCallback? onJump;
  final VoidCallback? onInteract;
  final VoidCallback? onMenu;
  final VoidCallback? onGyroscopeToggle;
  final VoidCallback? onFullscreen;
  final bool showGyroscopeButton;
  final bool isGyroscopeEnabled;
  final bool isFullscreen;
  final double opacity;

  const Mobile3DControls({
    super.key,
    required this.onMovementChanged,
    required this.onCameraChanged,
    this.onJump,
    this.onInteract,
    this.onMenu,
    this.onGyroscopeToggle,
    this.onFullscreen,
    this.showGyroscopeButton = true,
    this.isGyroscopeEnabled = false,
    this.isFullscreen = false,
    this.opacity = 0.8,
  });

  @override
  State<Mobile3DControls> createState() => _Mobile3DControlsState();
}

class _Mobile3DControlsState extends State<Mobile3DControls>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _controlsVisible = true;
  bool _autoHideEnabled = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    // Auto-hide controls after 5 seconds of inactivity
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoHideTimer() {
    if (!_autoHideEnabled) return;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _controlsVisible) {
        _hideControls();
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() {
        _controlsVisible = true;
      });
      _fadeController.forward();
      _startAutoHideTimer();
    }
  }

  void _hideControls() {
    if (_controlsVisible) {
      setState(() {
        _controlsVisible = false;
      });
      _fadeController.reverse();
    }
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControls();
    } else {
      _showControls();
    }
  }

  void _onUserInteraction() {
    _showControls();
    HapticFeedbackService.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTap: _showControls,
      child: Container(
        width: size.width,
        height: size.height,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * widget.opacity,
              child: Stack(
                children: [
                  // Movement joystick (bottom left)
                  Positioned(
                    bottom: 40,
                    left: 30,
                    child: _buildMovementJoystick(),
                  ),
                  
                  // Camera joystick (bottom right)
                  Positioned(
                    bottom: 40,
                    right: 30,
                    child: _buildCameraJoystick(),
                  ),
                  
                  // Action buttons (right side)
                  Positioned(
                    right: 20,
                    top: size.height * 0.3,
                    child: _buildActionButtons(),
                  ),
                  
                  // Top controls (menu, settings, etc.)
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: _buildTopControls(),
                  ),
                  
                  // Bottom center controls
                  if (widget.showGyroscopeButton)
                    Positioned(
                      bottom: 20,
                      left: size.width * 0.4,
                      right: size.width * 0.4,
                      child: _buildBottomControls(),
                    ),
                  
                  // Controls toggle button (always visible)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: _buildControlsToggle(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovementJoystick() {
    return VirtualJoystick(
      size: 120,
      type: JoystickType.movement,
      baseColor: Colors.black.withValues(alpha: 0.6),
      knobColor: const Color(0xFF4CAF50),
      onChanged: (offset) {
        _onUserInteraction();
        widget.onMovementChanged(offset);
      },
      enableHaptic: true,
      showDirections: true,
    );
  }

  Widget _buildCameraJoystick() {
    return VirtualJoystick(
      size: 120,
      type: JoystickType.camera,
      baseColor: Colors.black.withValues(alpha: 0.6),
      knobColor: const Color(0xFF2196F3),
      onChanged: (offset) {
        _onUserInteraction();
        widget.onCameraChanged(offset);
      },
      enableHaptic: true,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onJump != null)
          _buildActionButton(
            icon: Icons.keyboard_arrow_up,
            label: 'Jump',
            color: const Color(0xFFFF9800),
            onPressed: () {
              _onUserInteraction();
              widget.onJump?.call();
              HapticFeedbackService.gameEvent(type: GameEventType.jump);
            },
          ),
        
        const SizedBox(height: 15),
        
        if (widget.onInteract != null)
          _buildActionButton(
            icon: Icons.touch_app,
            label: 'Interact',
            color: const Color(0xFF9C27B0),
            onPressed: () {
              _onUserInteraction();
              widget.onInteract?.call();
              HapticFeedbackService.gameEvent(type: GameEventType.interact);
            },
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.onMenu != null)
          _buildTopButton(
            icon: Icons.menu,
            onPressed: () {
              _onUserInteraction();
              widget.onMenu?.call();
            },
          ),
        
        if (widget.onFullscreen != null)
          _buildTopButton(
            icon: widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: () {
              _onUserInteraction();
              widget.onFullscreen?.call();
            },
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Center(
      child: _buildGyroscopeButton(),
    );
  }

  Widget _buildGyroscopeButton() {
    return GestureDetector(
      onTap: () {
        _onUserInteraction();
        widget.onGyroscopeToggle?.call();
        HapticFeedbackService.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isGyroscopeEnabled
              ? const Color(0xFF4CAF50).withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.screen_rotation,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.isGyroscopeEnabled ? 'Gyro ON' : 'Gyro OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildControlsToggle() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          _controlsVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}