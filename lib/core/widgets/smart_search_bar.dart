import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/futuristic_ui_state.dart';
import 'unified_glassmorphic_container.dart';

/// Smart search bar with AI suggestions and voice input
class SmartSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(SearchSuggestion) onSuggestionSelected;
  final bool isDark;
  final double? width;
  final String hintText;
  final bool enableVoiceInput;

  const SmartSearchBar({
    super.key,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.isDark,
    this.width,
    this.hintText = 'Search locations, facilities...',
    this.enableVoiceInput = true,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  bool _isExpanded = false;
  bool _isFocused = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AnimationConfig.searchExpand,
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.materialCurve,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.emphasizedCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.materialCurve,
    ));
  }

  void _setupListeners() {
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _expandSearchBar();
    } else {
      _collapseSearchBar();
    }
  }

  void _onTextChange() {
    final query = _controller.text;
    
    // Update state
    context.read<FuturisticUIState>().updateSearchQuery(query);
    
    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestionsOverlay();
      }
      widget.onSearch(query);
    });
  }

  void _expandSearchBar() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    context.read<FuturisticUIState>().toggleSearchExpanded();
  }

  void _collapseSearchBar() {
    if (_controller.text.isEmpty) {
      setState(() {
        _isExpanded = false;
      });
      _animationController.reverse();
      context.read<FuturisticUIState>().toggleSearchExpanded();
    }
    _hideSuggestionsOverlay();
  }

  void _showSuggestionsOverlay() {
    _hideSuggestionsOverlay();
    
    final suggestions = context.read<FuturisticUIState>().suggestions;
    if (suggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: widget.width ?? 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: _buildSuggestionsDropdown(suggestions),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showSuggestions = false;
    });
  }

  Widget _buildSuggestionsDropdown(List<SearchSuggestion> suggestions) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark 
              ? Colors.grey[850]?.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return _buildSuggestionItem(suggestion, index);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(SearchSuggestion suggestion, int index) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon with Google-like styling
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSuggestionIconColor(suggestion.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                suggestion.icon,
                size: 18,
                color: _getSuggestionIconColor(suggestion.type),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (suggestion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSuggestionIconColor(suggestion.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypeLabel(suggestion.type),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getSuggestionIconColor(suggestion.type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSuggestionIconColor(SearchType type) {
    switch (type) {
      case SearchType.location:
        return const Color(0xFF4285F4); // Google Blue
      case SearchType.action:
        return const Color(0xFF34A853); // Google Green
      case SearchType.information:
        return const Color(0xFFFF9800); // Material Orange
      case SearchType.feature:
        return const Color(0xFF9C27B0); // Material Purple
    }
  }

  String _getTypeLabel(SearchType type) {
    switch (type) {
      case SearchType.location:
        return 'Location';
      case SearchType.action:
        return 'Action';
      case SearchType.information:
        return 'Info';
      case SearchType.feature:
        return 'Feature';
    }
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _controller.text = suggestion.title;
    _focusNode.unfocus();
    _hideSuggestionsOverlay();
    
    // Add to search history
    context.read<FuturisticUIState>().addToSearchHistory(suggestion.title);
    
    widget.onSuggestionSelected(suggestion);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _startVoiceInput() {
    // Set voice listening state
    context.read<FuturisticUIState>().setVoiceListening(true);
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // TODO: Implement actual voice-to-text functionality
    // For now, simulate voice input
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<FuturisticUIState>().setVoiceListening(false);
        _controller.text = 'Library'; // Simulated voice result
        _onTextChange();
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    _hideSuggestionsOverlay();
    context.read<FuturisticUIState>().updateSearchQuery('');
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideSuggestionsOverlay();
    _animationController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuturisticUIState>(
      builder: (context, state, child) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return UnifiedGlassmorphicContainer.searchBar(
                isDark: widget.isDark,
                isFocused: _isFocused,
                child: SizedBox(
                  width: widget.width,
                  height: 50,
                  child: Row(
                    children: [
                      // Search icon
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: AnimatedContainer(
                          duration: AnimationConfig.quickActionHover,
                          child: Icon(
                            Icons.search_rounded,
                            color: _isFocused
                                ? Theme.of(context).primaryColor
                                : (widget.isDark ? Colors.white70 : Colors.black54),
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: widget.isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              color: widget.isDark ? Colors.white54 : Colors.black54,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              context.read<FuturisticUIState>().addToSearchHistory(value);
                              widget.onSearch(value);
                            }
                          },
                        ),
                      ),
                      
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Clear button
                          if (_controller.text.isNotEmpty)
                            _buildActionButton(
                              icon: Icons.clear_rounded,
                              onTap: _clearSearch,
                            ),
                          
                          // Voice input button
                          if (widget.enableVoiceInput)
                            _buildActionButton(
                              icon: state.isVoiceListening 
                                  ? Icons.mic_rounded 
                                  : Icons.mic_none_rounded,
                              onTap: state.isVoiceListening ? null : _startVoiceInput,
                              isActive: state.isVoiceListening,
                            ),
                        ],
                      ),
                      
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedContainer(
            duration: AnimationConfig.quickActionHover,
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : (widget.isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}