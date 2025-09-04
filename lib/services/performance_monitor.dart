import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Performance monitoring service for the TaskManager app
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, dynamic> _memoryStats = {};

  /// Start tracking an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End tracking an operation and record duration
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      _operationDurations.putIfAbsent(operationName, () => []);
      _operationDurations[operationName]!.add(duration);
      
      _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
      
      // Keep only last 100 measurements to prevent memory leaks
      if (_operationDurations[operationName]!.length > 100) {
        _operationDurations[operationName]!.removeAt(0);
      }
      
      _operationStartTimes.remove(operationName);
      
      if (kDebugMode) {
        debugPrint('⏱️ $operationName completed in ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Record memory usage statistics
  void recordMemoryUsage(String category, {
    int? objectCount,
    int? memoryBytes,
    Map<String, dynamic>? customMetrics,
  }) {
    _memoryStats[category] = {
      'objectCount': objectCount,
      'memoryBytes': memoryBytes,
      'timestamp': DateTime.now(),
      ...?customMetrics,
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final operation in _operationDurations.keys) {
      final durations = _operationDurations[operation]!;
      final avgDuration = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) / durations.length;
      final maxDuration = durations.fold<Duration>(Duration.zero, (max, d) => d > max ? d : max);
      final minDuration = durations.fold<Duration>(const Duration(days: 1), (min, d) => d < min ? d : min);
      
      stats[operation] = {
        'count': _operationCounts[operation],
        'avgMs': avgDuration.round(),
        'maxMs': maxDuration.inMilliseconds,
        'minMs': minDuration.inMilliseconds,
        'recent10AvgMs': durations.length >= 10 
            ? (durations.skip(durations.length - 10).fold<int>(0, (sum, d) => sum + d.inMilliseconds) / 10).round()
            : avgDuration.round(),
      };
    }
    
    return {
      'operations': stats,
      'memory': _memoryStats,
      'generatedAt': DateTime.now(),
    };
  }

  /// Check if any operation is performing poorly
  List<String> getPerformanceWarnings() {
    final warnings = <String>[];
    
    for (final operation in _operationDurations.keys) {
      final durations = _operationDurations[operation]!;
      if (durations.isNotEmpty) {
        final avgMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) / durations.length;
        
        // Define performance thresholds
        final thresholds = {
          'database_query': 1000,
          'ui_render': 16, // 60fps = 16ms per frame
          'image_load': 2000,
          'api_call': 5000,
        };
        
        final threshold = thresholds.entries
            .where((e) => operation.toLowerCase().contains(e.key))
            .map((e) => e.value)
            .firstOrNull ?? 1000;
        
        if (avgMs > threshold) {
          warnings.add('$operation is slow (${avgMs.round()}ms avg, threshold: ${threshold}ms)');
        }
      }
    }
    
    return warnings;
  }

  /// Reset all performance data
  void reset() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    _memoryStats.clear();
  }

  /// Log performance summary
  void logPerformanceSummary() {
    if (!kDebugMode) return;
    
    final stats = getPerformanceStats();
    final warnings = getPerformanceWarnings();
    
    debugPrint('📊 Performance Summary:');
    
    final operations = stats['operations'] as Map<String, dynamic>;
    for (final entry in operations.entries) {
      final data = entry.value as Map<String, dynamic>;
      debugPrint('  ${entry.key}: ${data['count']} calls, ${data['avgMs']}ms avg');
    }
    
    if (warnings.isNotEmpty) {
      debugPrint('⚠️ Performance Warnings:');
      for (final warning in warnings) {
        debugPrint('  $warning');
      }
    }
    
    final memory = stats['memory'] as Map<String, dynamic>;
    if (memory.isNotEmpty) {
      debugPrint('💾 Memory Usage:');
      for (final entry in memory.entries) {
        final data = entry.value as Map<String, dynamic>;
        if (data['objectCount'] != null) {
          debugPrint('  ${entry.key}: ${data['objectCount']} objects');
        }
        if (data['memoryBytes'] != null) {
          debugPrint('  ${entry.key}: ${(data['memoryBytes'] / 1024 / 1024).toStringAsFixed(2)} MB');
        }
      }
    }
  }
}

/// Performance monitoring mixin for easy integration
mixin PerformanceTrackingMixin {
  final PerformanceMonitor _perfMonitor = PerformanceMonitor();
  
  /// Track an operation with automatic cleanup
  T trackOperation<T>(String operationName, T Function() operation) {
    _perfMonitor.startOperation(operationName);
    try {
      return operation();
    } finally {
      _perfMonitor.endOperation(operationName);
    }
  }
  
  /// Track an async operation
  Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation) async {
    _perfMonitor.startOperation(operationName);
    try {
      return await operation();
    } finally {
      _perfMonitor.endOperation(operationName);
    }
  }
  
  /// Record custom metric
  void recordMetric(String category, {
    int? objectCount,
    int? memoryBytes,
    Map<String, dynamic>? customMetrics,
  }) {
    _perfMonitor.recordMemoryUsage(
      category,
      objectCount: objectCount,
      memoryBytes: memoryBytes,
      customMetrics: customMetrics,
    );
  }
}

/// Widget performance tracker
class PerformanceTracker extends StatefulWidget {
  final Widget child;
  final String operationName;
  
  const PerformanceTracker({
    super.key,
    required this.child,
    required this.operationName,
  });
  
  @override
  State<PerformanceTracker> createState() => _PerformanceTrackerState();
}

class _PerformanceTrackerState extends State<PerformanceTracker> {
  final PerformanceMonitor _perfMonitor = PerformanceMonitor();
  
  @override
  void initState() {
    super.initState();
    _perfMonitor.startOperation(widget.operationName);
  }
  
  @override
  void dispose() {
    _perfMonitor.endOperation(widget.operationName);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}