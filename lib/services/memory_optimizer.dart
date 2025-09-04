import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

/// Memory optimization service for efficient resource management
class MemoryOptimizer {
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  factory MemoryOptimizer() => _instance;
  MemoryOptimizer._internal();

  Timer? _memoryCheckTimer;
  final List<WeakReference<Object>> _trackedObjects = [];
  final Map<Type, int> _objectCounts = {};
  
  /// Start memory monitoring
  void startMonitoring() {
    _memoryCheckTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _performMemoryCheck(),
    );
  }

  /// Stop memory monitoring
  void stopMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
  }

  /// Track an object for memory monitoring
  void trackObject(Object object) {
    if (kDebugMode) {
      _trackedObjects.add(WeakReference(object));
      final type = object.runtimeType;
      _objectCounts[type] = (_objectCounts[type] ?? 0) + 1;
    }
  }

  /// Perform periodic memory check and cleanup
  void _performMemoryCheck() {
    if (!kDebugMode) return;

    // Clean up null weak references
    _trackedObjects.removeWhere((ref) => ref.target == null);
    
    // Count current objects
    final currentCounts = <Type, int>{};
    for (final ref in _trackedObjects) {
      final target = ref.target;
      if (target != null) {
        final type = target.runtimeType;
        currentCounts[type] = (currentCounts[type] ?? 0) + 1;
      }
    }

    // Log memory statistics
    debugPrint('📊 Memory Statistics:');
    debugPrint('  Tracked objects: ${_trackedObjects.length}');
    
    for (final entry in currentCounts.entries) {
      debugPrint('  ${entry.key}: ${entry.value} instances');
    }

    // Check for potential memory leaks
    _checkForMemoryLeaks(currentCounts);
    
    // Force garbage collection if memory usage is high
    if (_shouldForceGC()) {
      forceGarbageCollection();
    }
  }

  /// Check for potential memory leaks
  void _checkForMemoryLeaks(Map<Type, int> currentCounts) {
    const int leakThreshold = 50;
    
    for (final entry in currentCounts.entries) {
      if (entry.value > leakThreshold) {
        debugPrint('⚠️ Potential memory leak detected: ${entry.key} has ${entry.value} instances');
      }
    }
  }

  /// Determine if garbage collection should be forced
  bool _shouldForceGC() {
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, be more aggressive about GC
      return _trackedObjects.length > 100;
    }
    return _trackedObjects.length > 500;
  }

  /// Force garbage collection
  void forceGarbageCollection() {
    debugPrint('🗑️ Forcing garbage collection...');
    
    // Clear weak references to help GC
    _trackedObjects.removeWhere((ref) => ref.target == null);
    
    // Suggest GC (not guaranteed)
    if (kDebugMode) {
      // Force a minor GC cycle
      List.generate(1000, (i) => Object()).clear();
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    final stats = <String, dynamic>{
      'trackedObjects': _trackedObjects.length,
      'objectCounts': Map.from(_objectCounts),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return stats;
  }

  /// Cleanup all tracking
  void dispose() {
    stopMonitoring();
    _trackedObjects.clear();
    _objectCounts.clear();
  }
}

/// Mixin for automatic memory tracking
mixin MemoryTrackingMixin {
  final MemoryOptimizer _memoryOptimizer = MemoryOptimizer();
  
  void trackMemoryUsage() {
    _memoryOptimizer.trackObject(this);
  }
}

/// Widget for tracking memory usage of specific widgets
class MemoryTrackingWidget extends StatefulWidget {
  final Widget child;
  final String? name;
  
  const MemoryTrackingWidget({
    super.key,
    required this.child,
    this.name,
  });
  
  @override
  State<MemoryTrackingWidget> createState() => _MemoryTrackingWidgetState();
}

class _MemoryTrackingWidgetState extends State<MemoryTrackingWidget> 
    with MemoryTrackingMixin {
  
  @override
  void initState() {
    super.initState();
    trackMemoryUsage();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Optimized image caching service
class OptimizedImageCache {
  static final OptimizedImageCache _instance = OptimizedImageCache._internal();
  factory OptimizedImageCache() => _instance;
  OptimizedImageCache._internal();

  final Map<String, WeakReference<Image>> _imageCache = {};
  Timer? _cleanupTimer;
  
  void startCacheCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredImages(),
    );
  }
  
  void _cleanupExpiredImages() {
    final keysToRemove = <String>[];
    
    for (final entry in _imageCache.entries) {
      if (entry.value.target == null) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _imageCache.remove(key);
    }
    
    debugPrint('🖼️ Cleaned up ${keysToRemove.length} expired images from cache');
  }
  
  Image? getCachedImage(String url) {
    return _imageCache[url]?.target;
  }
  
  void cacheImage(String url, Image image) {
    _imageCache[url] = WeakReference(image);
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
    _imageCache.clear();
  }
}

/// Efficient list view helper for large datasets
class EfficientListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final int? itemsPerPage;
  
  const EfficientListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.itemsPerPage = 50,
  });
  
  @override
  State<EfficientListView> createState() => _EfficientListViewState();
}

class _EfficientListViewState extends State<EfficientListView> {
  late ScrollController _controller;
  int _visibleItemCount = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _visibleItemCount = widget.itemsPerPage ?? 50;
    
    _controller.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      if (_visibleItemCount < widget.itemCount) {
        setState(() {
          _visibleItemCount = (_visibleItemCount + (widget.itemsPerPage ?? 50))
              .clamp(0, widget.itemCount).toInt();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: _visibleItemCount,
      itemBuilder: widget.itemBuilder,
      // Performance optimizations
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
}

/// Resource pool for reusing expensive objects
class ResourcePool<T> {
  final T Function() _factory;
  final void Function(T)? _reset;
  final List<T> _available = [];
  final Set<T> _inUse = {};
  final int _maxSize;
  
  ResourcePool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 10,
  }) : _factory = factory,
       _reset = reset,
       _maxSize = maxSize;
  
  T acquire() {
    if (_available.isNotEmpty) {
      final resource = _available.removeLast();
      _inUse.add(resource);
      return resource;
    }
    
    final resource = _factory();
    _inUse.add(resource);
    return resource;
  }
  
  void release(T resource) {
    if (_inUse.remove(resource)) {
      _reset?.call(resource);
      
      if (_available.length < _maxSize) {
        _available.add(resource);
      }
    }
  }
  
  void dispose() {
    _available.clear();
    _inUse.clear();
  }
}