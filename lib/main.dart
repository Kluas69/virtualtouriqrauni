import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'core/error/error_handler.dart';
import 'core/error/error_boundary.dart';
import 'core/memory/memory_manager.dart';
import 'core/state/app_state_manager.dart';
import 'core/assets/asset_manager.dart';
import 'core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core systems
  await _initializeCoreServices();
  
  // Configure global error handling
  ErrorHandler.initialize();
  ErrorBoundaryConfig.configure();
  
  runApp(const MyApp());
}

/// Initialize all core services before app starts
Future<void> _initializeCoreServices() async {
  try {
    AppLogger.info('Initializing core services', component: 'Main');
    
    // Add timeout to prevent hanging
    await Future.wait([
      MemoryManager().initialize(),
      AppStateManager().initialize(),
      AssetManager().initialize(),
    ]).timeout(const Duration(seconds: 10), onTimeout: () {
      AppLogger.warning('Core services initialization timed out, continuing with defaults', 
        component: 'Main');
      return [];
    });
    
    // Configure image cache
    ImageCacheConfig.configure();
    
    AppLogger.info('Core services initialized successfully', component: 'Main');
  } catch (e) {
    AppLogger.error('Failed to initialize core services',
      component: 'Main',
      error: e);
    
    // Continue anyway to prevent app from hanging
    AppLogger.warning('Continuing with partial initialization', component: 'Main');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire app with error boundary and providers
    return ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => AppStateManager()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AnimatedTheme(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              data: themeProvider.theme,
              child: MaterialApp(
                title: 'IQRA Virtual Tour',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.theme,
                themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
                home: ErrorBoundary(
                  errorMessage: 'Failed to load home screen',
                  child: const HomeScreen(),
                ),
                builder: (context, child) {
                  // Add global error handling wrapper
                  return ErrorBoundary(
                    errorMessage: 'Application error occurred',
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
