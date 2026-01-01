import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/app_logger.dart';
import '../design/app_spacing.dart';

class ChatbotWidget extends StatefulWidget {
  final Function(String)? onNavigate;

  const ChatbotWidget({super.key, this.onNavigate});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Exact location titles from your app_data.json
  final List<String> _locations = [
    'Library',
    'Play Area',
    'Auditorium',
    'Class Rooms',
    'Amphitheater',
    'Cafeteria',
    'Common Room',
    'Playground',
    'Swimming Pool',
    'Webinar Room',
  ];

  final List<String> _quickActions = [
    'Show me campus facilities',
    'Where is the library?',
    'Tell me about departments',
    'Take me on a tour',
  ];

  final String openAiApiKey =
      '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';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    // Keep fade animation for smooth appearance
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Slide animation (minimal for subtle effect)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Welcome message
    _messages.add(
      ChatMessage(
        text:
            'Welcome to IQRA University Virtual Tour! 🎓\n\nI can help you explore our H-9 Islamabad campus. Ask me about any facility like Library, Cafeteria, Auditorium, or say "Take me to the Swimming Pool"!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = text.trim();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final aiResponse = await _callChatAPI(userMessage);
      final navigationButtons = _detectNavigation(userMessage, aiResponse);

      setState(() {
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            navigationButtons: navigationButtons,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'I\'m having trouble connecting right now. Please check your internet and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<String> _callChatAPI(String userMessage) async {
    const universityContext = '''
You are a friendly and knowledgeable virtual tour guide for IQRA University's H-9 Islamabad Campus.

Available locations:
- Library
- Play Area
- Auditorium
- Class Rooms
- Amphitheater
- Cafeteria
- Common Room
- Playground
- Swimming Pool
- Webinar Room

When the user asks to visit, go to, see, or explore a location, clearly mention the exact location name so navigation buttons can appear.

Be helpful, concise, and engaging. Encourage exploration!
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'max_tokens': 800,
          'temperature': 0.7,
          'messages': [
            {'role': 'system', 'content': universityContext},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Sorry, I encountered an error. Please try again.';
      }
    } catch (e) {
      return 'Here are some places you can explore: Library, Cafeteria, Auditorium, Swimming Pool, and more! What would you like to see?';
    }
  }

  List<String> _detectNavigation(String userMessage, String aiResponse) {
    final combinedText =
        '${userMessage.toLowerCase()} ${aiResponse.toLowerCase()}';
    final keywords = [
      'visit',
      'go to',
      'show',
      'take me',
      'tour',
      'where',
      'navigate',
      'see',
      'explore',
    ];

    if (keywords.any((k) => combinedText.contains(k))) {
      return _locations
          .where((loc) => combinedText.contains(loc.toLowerCase()))
          .toList();
    }
    return [];
  }

  void _handleNavigation(String location) {
    AppLogger.debug('Navigation button clicked',
      component: 'ChatbotWidget',
      metadata: {'location': location});

    // Call the parent's navigation handler
    if (widget.onNavigate != null) {
      widget.onNavigate!(location);
      AppLogger.debug('onNavigate called successfully',
        component: 'ChatbotWidget');
    } else {
      AppLogger.warning('onNavigate callback is null',
        component: 'ChatbotWidget');
    }

    // Close the chatbot after a short delay to allow navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isOpen = false;
          _animationController.reverse();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Floating Chat Button
        if (!_isOpen)
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildChatButton(isDark, size),
          ),

        // Chat Window
        if (_isOpen)
          Positioned(
            bottom: 24,
            right: 24,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildChatWindow(isDark, size),
            ),
          ),
      ],
    );
  }

  Widget _buildChatButton(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    final buttonSize = isMobile ? 56.0 : 64.0;
    final iconSize = isMobile ? 28.0 : 32.0;
    
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      color: Colors.transparent,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          // Material Design 3 primary color
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4285F4), // Google Blue
              const Color(0xFF4285F4).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          // Material Design 3 shadows
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: isMobile ? 8 : 12,
              offset: Offset(0, isMobile ? 4 : 6),
            ),
            BoxShadow(
              color: const Color(0xFF4285F4).withValues(alpha: 0.2),
              blurRadius: isMobile ? 12 : 16,
              spreadRadius: 0,
              offset: Offset(0, isMobile ? 2 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleChat();
            },
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    final isTablet = size.width < AppSpacing.tabletBreakpoint;
    final isSmallMobile = size.width < 360;
    
    // Responsive dimensions similar to your reference but with better mobile support
    double windowWidth;
    double windowHeight;
    double borderRadius;
    
    if (isSmallMobile) {
      // Very small mobile: Compact size
      windowWidth = size.width - 48;
      windowHeight = size.height * 0.7;
      borderRadius = 20;
    } else if (isMobile) {
      // Mobile: Medium size
      windowWidth = (size.width - 48).clamp(300, 380);
      windowHeight = (size.height * 0.75).clamp(400, 600);
      borderRadius = 24;
    } else if (isTablet) {
      // Tablet: Similar to reference
      windowWidth = 400;
      windowHeight = 620;
      borderRadius = 24;
    } else {
      // Desktop: Exact reference size
      windowWidth = 380;
      windowHeight = 620;
      borderRadius = 24;
    }
    
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.transparent,
      child: Container(
        width: windowWidth,
        height: windowHeight,
        decoration: BoxDecoration(
          // Material Design 3 surface colors
          color: isDark 
              ? const Color(0xFF1C1B1F) // Material Design 3 dark surface
              : const Color(0xFFFFFBFE), // Material Design 3 light surface
          borderRadius: BorderRadius.circular(borderRadius),
          // Material Design 3 shadows
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
          // Material Design 3 border
          border: Border.all(
            color: isDark 
                ? const Color(0xFF49454F).withValues(alpha: 0.12)
                : const Color(0xFF79747E).withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark, size),
            Expanded(child: _buildMessageList(isDark, size)),
            if (_messages.length <= 1) _buildQuickActions(isDark, size),
            if (_isLoading) _buildTypingIndicator(isDark, size),
            _buildInputArea(isDark, size),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    final borderRadius = isMobile ? 20.0 : size.width < AppSpacing.tabletBreakpoint ? 24.0 : 28.0;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        // Material Design 3 primary container
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4285F4), // Google Blue
            const Color(0xFF4285F4).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IQRA Virtual Guide',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853), // Google Green
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online • Ready to help',
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _toggleChat();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    final isSmallMobile = size.width < 360;
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 12 : 16)),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: isSmallMobile ? 3 : (isMobile ? 4 : 6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser) ...[
                  Container(
                    width: isSmallMobile ? 24 : (isMobile ? 28 : 32),
                    height: isSmallMobile ? 24 : (isMobile ? 28 : 32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isSmallMobile ? 12 : (isMobile ? 14 : 16)),
                    ),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      size: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
                ],
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(isSmallMobile ? 10 : (isMobile ? 12 : 16)),
                    constraints: BoxConstraints(
                      maxWidth: isSmallMobile 
                          ? size.width * 0.75 
                          : isMobile 
                              ? size.width * 0.7 
                              : 280,
                      minWidth: isSmallMobile ? 80 : 100,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFF4285F4) // Google Blue for user messages
                          : (isDark
                              ? const Color(0xFF2D2D30) // Dark surface variant
                              : const Color(0xFFF7F2FA)), // Light surface variant
                      borderRadius: BorderRadius.circular(isSmallMobile ? 14 : (isMobile ? 16 : 20)),
                      // Material Design 3 subtle shadows for message bubbles
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: GoogleFonts.roboto(
                            color: message.isUser 
                                ? Colors.white 
                                : (isDark 
                                    ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                                    : const Color(0xFF1C1B1F)),
                            fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 15),
                            height: 1.4,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (message.navigationButtons.isNotEmpty) ...[
                          SizedBox(height: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
                          Wrap(
                            spacing: isSmallMobile ? 4 : (isMobile ? 6 : 8),
                            runSpacing: isSmallMobile ? 4 : (isMobile ? 6 : 8),
                            children: message.navigationButtons.map((location) {
                              return Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _handleNavigation(location);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallMobile ? 8 : (isMobile ? 12 : 16),
                                      vertical: isSmallMobile ? 4 : (isMobile ? 6 : 8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34A853), // Google Green
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF34A853).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.navigation_rounded,
                                          size: isSmallMobile ? 12 : (isMobile ? 14 : 16),
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: isSmallMobile ? 3 : (isMobile ? 4 : 6)),
                                        Text(
                                          location,
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 13),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2D2D30) // Dark surface variant
            : const Color(0xFFF7F2FA), // Light surface variant
        border: Border(
          top: BorderSide(
            color: isDark 
                ? const Color(0xFF49454F).withValues(alpha: 0.12)
                : const Color(0xFF79747E).withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: isMobile ? 4 : 8, bottom: isMobile ? 6 : 8),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isDark 
                    ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                    : const Color(0xFF49454F),
                letterSpacing: 0.4,
              ),
            ),
          ),
          Wrap(
            spacing: isMobile ? 6 : 8,
            runSpacing: isMobile ? 6 : 8,
            children: _quickActions.map((action) {
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _sendMessage(action);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF49454F).withValues(alpha: 0.08)
                          : const Color(0xFF79747E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark 
                            ? const Color(0xFF49454F).withValues(alpha: 0.12)
                            : const Color(0xFF79747E).withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      action,
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 12 : 13,
                        color: isDark 
                            ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                            : const Color(0xFF1C1B1F),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: isMobile ? 4 : 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 28 : 32,
            height: isMobile ? 28 : 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: isMobile ? 16 : 18,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2D2D30) // Dark surface variant
                  : const Color(0xFFF7F2FA), // Light surface variant
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isMobile ? 14 : 16,
                  height: isMobile ? 14 : 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4285F4)),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 10),
                Text(
                  'Thinking...',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 13 : 14,
                    color: isDark 
                        ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                        : const Color(0xFF1C1B1F),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark, Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1B1F) // Material Design 3 dark surface
            : const Color(0xFFFFFBFE), // Material Design 3 light surface
        border: Border(
          top: BorderSide(
            color: isDark 
                ? const Color(0xFF49454F).withValues(alpha: 0.12)
                : const Color(0xFF79747E).withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF2D2D30) // Dark surface variant
                    : const Color(0xFFF7F2FA), // Light surface variant
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF49454F).withValues(alpha: 0.12)
                      : const Color(0xFF79747E).withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 15,
                  color: isDark 
                      ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                      : const Color(0xFF1C1B1F),
                  letterSpacing: 0.1,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about campus facilities...',
                  hintStyle: GoogleFonts.roboto(
                    color: isDark 
                        ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                        : const Color(0xFF49454F),
                    fontSize: isMobile ? 14 : 15,
                    letterSpacing: 0.1,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(_controller.text),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _sendMessage(_controller.text);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF4285F4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> navigationButtons;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.navigationButtons = const [],
  });
}
