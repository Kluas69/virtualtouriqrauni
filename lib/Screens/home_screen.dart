import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/core/widgets/header_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/widgets/language_selector.dart';
import 'package:virtualtouriu/core/widgets/professional_home_content.dart';
import 'package:virtualtouriu/core/state/ui_state.dart';
import 'package:virtualtouriu/core/performance/performance_monitor.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/core/error/error_boundary.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with AutomaticKeepAliveClientMixin, PerformanceOptimizedWidget {
  
  late ScrollController _scrollController;
  late UIState _uiState;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;

  // Static future to prevent recreation on rebuilds
  static final Future<void> _initializationFuture = AppConstants.initializationFuture.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      AppLogger.warning('AppConstants initialization timed out, continuing anyway',
        component: 'HomeScreen');
    },
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _uiState = UIState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final pos = _scrollController.offset;
    final shouldHide = pos > _lastScrollPosition && pos > 100;

    if (_isHeaderVisible == shouldHide) {
      setState(() => _isHeaderVisible = !shouldHide);
    }
    _lastScrollPosition = pos;
  }

  void _handleChatbotNavigation(String location) {
    // Handle chatbot navigation
    AppLogger.info('Chatbot navigation requested', 
      component: 'HomeScreen',
      metadata: {'location': location});
  }

  void _handleLanguageChanged(Language language) {
    _uiState.setCurrentLanguage(language);
    LanguagePreferences.saveLanguage(language.code);
    
    if (language.isRTL) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _uiState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(isDark);
        }

        if (snapshot.hasError) {
          AppLogger.error('Error in AppConstants initialization',
            component: 'HomeScreen',
            error: snapshot.error);
          return _buildErrorScreen(isDark, snapshot.error.toString());
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          body: ChangeNotifierProvider.value(
            value: _uiState,
            child: Stack(
              children: [
                ProfessionalHomeContent(
                  scrollController: _scrollController,
                  onChatbotNavigation: _handleChatbotNavigation,
                ),
                _buildAnimatedHeader(isDark),
                ChatbotWidget(onNavigate: _handleChatbotNavigation),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
              isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                child: const Text('Preparing your virtual tour...'),
              ),
              const SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
                child: const Text('Loading assets and initializing services'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark, String error) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
              isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.red.shade300 : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                  child: const Text('Oops! Something went wrong'),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  child: Text('Error: $error'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isDark) {
    final theme = Theme.of(context);
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _isHeaderVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _uiState,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FadeInLeft(
                  duration: const Duration(milliseconds: 600),
                  child: HeaderBadge(
                    isDark: isDark,
                    text: 'IQRA Virtual Tour',
                    icon: Icons.school,
                  ),
                ),
                const Spacer(),
                FadeInRight(
                  duration: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageSelector(
                        currentLanguage: _uiState.currentLanguage,
                        onLanguageChanged: _handleLanguageChanged,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      ThemeToggleButton(
                        isDark: isDark,
                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
