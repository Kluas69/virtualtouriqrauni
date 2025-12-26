import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  final String openAiApiKey = '';

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
    print('🔥 CHATBOT: Navigation button clicked for: "$location"');
    print('🔥 CHATBOT: Calling onNavigate callback...');

    // Call the parent's navigation handler
    if (widget.onNavigate != null) {
      widget.onNavigate!(location);
      print('✅ CHATBOT: onNavigate called successfully');
    } else {
      print('❌ CHATBOT: onNavigate is null!');
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

    return Stack(
      children: [
        // Floating Chat Button
        if (!_isOpen)
          Positioned(bottom: 24, right: 24, child: _buildChatButton(isDark)),

        // Chat Window
        if (_isOpen)
          Positioned(
            bottom: 24,
            right: 24,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildChatWindow(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildChatButton(bool isDark) {
    return Material(
      elevation: 12,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: _toggleChat,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(bool isDark) {
    return Material(
      elevation: 20,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        width: 380,
        height: 620,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildMessageList(isDark)),
            if (_messages.length <= 1) _buildQuickActions(isDark),
            if (_isLoading) _buildTypingIndicator(isDark),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IQRA Virtual Guide',
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Online • Ready to help',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: _toggleChat,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
                  ),
                if (!message.isUser) const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color:
                          message.isUser
                              ? Theme.of(context).primaryColor
                              : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: GoogleFonts.roboto(
                            color: message.isUser ? Colors.white : null,
                            fontSize: 15,
                          ),
                        ),
                        if (message.navigationButtons.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                message.navigationButtons.map((location) {
                                  return ElevatedButton.icon(
                                    onPressed:
                                        () => _handleNavigation(location),
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                    ),
                                    label: Text(location),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
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

  Widget _buildQuickActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _quickActions.map((action) {
                  return ActionChip(
                    label: Text(
                      action,
                      style: GoogleFonts.roboto(fontSize: 13),
                    ),
                    backgroundColor:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    onPressed: () => _sendMessage(action),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Thinking...', style: GoogleFonts.roboto(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.roboto(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask about campus facilities...',
                hintStyle: GoogleFonts.roboto(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _sendMessage(_controller.text),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(30),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
