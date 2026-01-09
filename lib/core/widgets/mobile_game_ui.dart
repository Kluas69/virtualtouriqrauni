import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../mobile/mobile_game_controller.dart';
import '../logging/app_logger.dart';

/// PUBG-style mobile game UI with landscape controls
class MobileGameUI extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onBackPressed;
  final VoidCallback? onFullscreenPressed;
  final Widget child;
  
  const MobileGameUI({
    super.key,
    this.onSettingsPressed,
    this.onBackPressed,
    this.onFullscreenPressed,
    required this.child,
  });

  @override
  State<MobileGameUI> createState() => _MobileGameUIState();
}

class _MobileGameUIState extends State<MobileGameUI> {
  final MobileGameController _gameController = MobileGameController.instance;
  bool _showSettings = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main game content
          widget.child,
          
          // Mobile game controls overlay
          if (_isMobileDevice(context))
            _buildMobileGameControls(context),
          
          // Settings panel
          if (_showSettings)
            _buildSettingsPanel(context),
        ],
      ),
    );
  }
  
  bool _isMobileDevice(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return screenSize.width < 1024; // Consider tablets as mobile for gaming
  }
  
  Widget _buildMobileGameControls(BuildContext context) {
    final buttonSize = _gameController.getOptimalButtonSize(context);
    final textSize = _gameController.getOptimalTextSize(context);
    
    return Stack(
      children: [
        // Top-left: Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 15,
          child: _buildGameButton(
            icon: Icons.arrow_back,
            onPressed: () async {
              await _gameController.provideFeedback();
              widget.onBackPressed?.call();
            },
            size: buttonSize,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        ),
        
        // Top-right: Settings and Fullscreen buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 15,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGameButton(
                icon: Icons.fullscreen,
                onPressed: () async {
                  await _gameController.provideFeedback();
                  await _gameController.toggleFullscreen();
                  widget.onFullscreenPressed?.call();
                },
                size: buttonSize,
                backgroundColor: Colors.blue.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 10),
              _buildGameButton(
                icon: Icons.settings,
                onPressed: () async {
                  await _gameController.provideFeedback();
                  setState(() {
                    _showSettings = !_showSettings;
                  });
                  widget.onSettingsPressed?.call();
                },
                size: buttonSize,
                backgroundColor: Colors.green.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
        
        // Bottom-center: Game info
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
              ),
              child: Text(
                'LANDSCAPE MODE • TOUCH TO PLAY',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGameButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    Color? backgroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsPanel(BuildContext context) {
    final textSize = _gameController.getOptimalTextSize(context);
    final titleSize = _gameController.getOptimalTextSize(context, isTitle: true);
    final padding = _gameController.getOptimalPadding(context);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyan.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.gamepad,
                        color: Colors.cyan,
                        size: titleSize + 4,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GAME SETTINGS',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showSettings = false;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: titleSize,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Settings content
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      children: [
                        _buildSettingsSection(
                          title: '🎮 CONTROLS',
                          textSize: textSize,
                          children: [
                            _buildSettingsButton(
                              'Landscape Mode',
                              _gameController.isLandscapeMode ? 'ON' : 'OFF',
                              () async {
                                if (_gameController.isLandscapeMode) {
                                  await _gameController.disableLandscapeMode();
                                } else {
                                  await _gameController.enableLandscapeMode();
                                }
                                setState(() {});
                              },
                              textSize,
                            ),
                            _buildSettingsButton(
                              'Fullscreen',
                              _gameController.isFullscreen ? 'ON' : 'OFF',
                              () async {
                                await _gameController.toggleFullscreen();
                                setState(() {});
                              },
                              textSize,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildSettingsSection(
                          title: '🎯 GAMEPLAY',
                          textSize: textSize,
                          children: [
                            _buildSettingsButton(
                              'Reset Position',
                              'RESET',
                              () {
                                // Send reset message to Three.js
                                _sendMessageToThreeJS('reset_player');
                              },
                              textSize,
                            ),
                            _buildSettingsButton(
                              'Quality',
                              'HIGH',
                              () {
                                // Send quality toggle message to Three.js
                                _sendMessageToThreeJS('cycle_quality');
                              },
                              textSize,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildSettingsSection(
                          title: '📱 MOBILE',
                          textSize: textSize,
                          children: [
                            _buildSettingsButton(
                              'Haptic Feedback',
                              'ON',
                              () {
                                _gameController.provideFeedback();
                              },
                              textSize,
                            ),
                            _buildSettingsButton(
                              'Touch Sensitivity',
                              'NORMAL',
                              () {
                                // Send sensitivity adjustment to Three.js
                                _sendMessageToThreeJS('adjust_sensitivity');
                              },
                              textSize,
                            ),
                          ],
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
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required double textSize,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.cyan,
            fontSize: textSize + 2,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
  
  Widget _buildSettingsButton(
    String label,
    String value,
    VoidCallback onPressed,
    double textSize,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _gameController.provideFeedback();
            onPressed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.cyan.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyan.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: textSize - 2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _sendMessageToThreeJS(String action) {
    try {
      AppLogger.info('Sending message to Three.js: $action', component: 'MobileGameUI');
      
      // Send message to iframe if available
      final iframe = html.document.querySelector('iframe');
      if (iframe != null && iframe is html.IFrameElement) {
        iframe.contentWindow?.postMessage({
          'type': 'mobile_action',
          'action': action,
          'source': 'flutter',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }, '*');
      }
      
      // Also try sending to parent window (for direct HTML embedding)
      html.window.postMessage({
        'type': 'mobile_action',
        'action': action,
        'source': 'flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
      
      AppLogger.info('Message sent to Three.js successfully', component: 'MobileGameUI');
    } catch (e) {
      AppLogger.error('Failed to send message to Three.js', 
        component: 'MobileGameUI', 
        error: e);
    }
  }
}