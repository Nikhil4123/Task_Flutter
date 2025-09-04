import 'package:flutter/foundation.dart';

/// Application configuration optimized for performance
class AppConfig {
  static const String appName = 'TaskManager';
  static const String version = '1.0.0';
  
  // Performance settings
  static const int maxCachedTasks = 1000;
  static const int taskLoadBatchSize = 20;
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // UI settings
  static const int maxTasksPerPage = 50;
  static const double listViewCacheExtent = 500.0;
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  // Firebase settings
  static const int firestoreTimeout = 10; // seconds
  static const bool enableFirestoreOffline = true;
  static const int maxFirestoreRetries = 3;
  
  // Memory management
  static const int maxImageCacheSize = 100;
  static const Duration memoryCheckInterval = Duration(minutes: 2);
  static const int memoryLeakThreshold = 50;
  
  // Debug settings
  static bool get isDebugMode => kDebugMode;
  static bool get enablePerformanceMonitoring => kDebugMode;
  static bool get enableMemoryTracking => kDebugMode;
  
  // Feature flags
  static const bool enableLazyLoading = true;
  static const bool enableImageCaching = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  
  // Thresholds and limits
  static const int searchMinLength = 2;
  static const int maxAttachmentsPerTask = 10;
  static const int maxFileSizeMB = 50;
  static const int maxTaskTitleLength = 100;
  static const int maxTaskDescriptionLength = 1000;
}

/// Environment-specific configurations
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment get current {
    if (kDebugMode) return Environment.development;
    // You can add logic here to detect staging vs production
    return Environment.production;
  }
  
  static Map<String, dynamic> get firebaseConfig {
    switch (current) {
      case Environment.development:
        return {
          'enableLogging': true,
          'persistenceEnabled': true,
          'cacheSizeBytes': 40000000, // 40MB
        };
      case Environment.staging:
        return {
          'enableLogging': false,
          'persistenceEnabled': true,
          'cacheSizeBytes': 100000000, // 100MB
        };
      case Environment.production:
        return {
          'enableLogging': false,
          'persistenceEnabled': true,
          'cacheSizeBytes': 100000000, // 100MB
        };
    }
  }
  
  static String get apiBaseUrl {
    switch (current) {
      case Environment.development:
        return 'https://dev-api.taskmanager.com';
      case Environment.staging:
        return 'https://staging-api.taskmanager.com';
      case Environment.production:
        return 'https://api.taskmanager.com';
    }
  }
}