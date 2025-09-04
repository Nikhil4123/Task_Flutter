import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/performance_monitor.dart';
import 'services/memory_optimizer.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for performance
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize performance monitoring
  if (AppConfig.enablePerformanceMonitoring) {
    PerformanceMonitor().reset();
  }
  
  // Initialize memory optimization
  if (AppConfig.enableMemoryTracking) {
    MemoryOptimizer().startMonitoring();
  }
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firebase with environment-specific settings
    await _configureFirebase();
    
    // Configure Firebase Auth settings
    await _configureFirebaseAuth();
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const TaskManagerApp());
}

// Configure Firebase for optimal performance
Future<void> _configureFirebase() async {
  try {
    final config = EnvironmentConfig.firebaseConfig;
    
    // Configure Firestore settings
    final firestore = FirebaseFirestore.instance;
    
    if (config['persistenceEnabled'] == true) {
      await firestore.enablePersistence();
    }
    
    // Set cache size
    firestore.settings = Settings(
      cacheSizeBytes: config['cacheSizeBytes'],
      persistenceEnabled: config['persistenceEnabled'],
    );
    
    debugPrint('Firebase configured for ${EnvironmentConfig.current}');
  } catch (e) {
    debugPrint('Firebase configuration error: $e');
  }
}

// Configure Firebase Auth for better compatibility
Future<void> _configureFirebaseAuth() async {
  try {
    // Set language code to avoid locale issues
    await FirebaseAuth.instance.setLanguageCode('en');
    
    // Configure Auth settings for Android
    if (!kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    debugPrint('Firebase Auth configuration error: $e');
  }
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        
        // Performance optimizations
        builder: (context, child) {
          return child!;
        },
        
        theme: _buildTheme(),
        home: Consumer<app_auth.AuthProvider>(
          builder: (context, authProvider, child) {
            // Show loading while checking authentication state
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Navigate based on authentication state
            return authProvider.isAuthenticated 
                ? const HomeScreen() 
                : const LoginScreen();
          },
        ),
      ),
    );
  }
  
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue[600],
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      
      // Performance optimizations
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          animationDuration: AppConfig.animationDuration,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
      ),
      
      // Optimize animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
