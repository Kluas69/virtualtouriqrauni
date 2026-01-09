import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/core/routing/app_routes.dart';
import 'core/error/error_handler.dart';
import 'core/error/error_boundary.dart';
import 'core/logging/app_logger.dart';
import 'core/state/app_state_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize only essential services to prevent hanging
  await _initializeEssentialServices();
  
  // Configure global error handling
  ErrorHandler.initialize();
  
  runApp(const MyApp());
}

/// Initialize only essential services to prevent app hanging
Future<void> _initializeEssentialServices() async {
  try {
    AppLogger.info('Initializing essential services', component: 'Main');
    
    // Initialize only critical services with shorter timeout
    await Future.wait([
      AppStateManager().initialize(),
    ]).timeout(const Duration(seconds: 3), onTimeout: () {
      AppLogger.warning('Essential services initialization timed out, continuing with defaults', 
        component: 'Main');
      return [];
    });
    
    AppLogger.info('Essential services initialized successfully', component: 'Main');
  } catch (e) {
    AppLogger.error('Failed to initialize essential services',
      component: 'Main',
      error: e);
    
    // Continue anyway to prevent app from hanging
    AppLogger.warning('Continuing with minimal initialization', component: 'Main');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Simplified app structure to prevent white screen
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AppStateManager()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'IQRA Virtual Tour',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: ErrorBoundary(
              errorMessage: 'Failed to load home screen',
              child: const HomeScreen(),
            ),
            // Use centralized route generator
            onGenerateRoute: AppRouteGenerator.generateRoute,
            // Handle unknown routes gracefully
            onUnknownRoute: (settings) {
              AppLogger.warning('Unknown route requested: ${settings.name}',
                component: 'Main',
                metadata: {'route': settings.name});
              
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
                settings: const RouteSettings(name: '/'),
              );
            },
          );
        },
      ),
    );
  }
}
