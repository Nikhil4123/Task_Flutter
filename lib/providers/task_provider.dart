import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  
  // Optimization: Use separate lists for different views
  List<Task> _allTasks = [];
  List<Task> _pendingTasks = [];
  List<Task> _inProgressTasks = [];
  List<Task> _completedTasks = [];
  
  // Caching and performance
  final Map<String, List<Task>> _cachedFilteredTasks = {};
  Timer? _debounceTimer;
  StreamSubscription<List<Task>>? _tasksSubscription;
  
  bool _isLoading = false;
  String? _error;
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String? _filterCategory;
  String _searchQuery = '';
  Map<String, dynamic> _analytics = {};
  
  // Performance optimization: Cache last query to avoid unnecessary rebuilds
  String _lastUserId = '';
  DateTime _lastLoadTime = DateTime(1970);

  // Optimized getters with caching
  List<Task> get tasks => _getFilteredTasksOptimized();
  List<Task> get allTasks => List.unmodifiable(_allTasks);
  List<Task> get pendingTasks => List.unmodifiable(_pendingTasks);
  List<Task> get inProgressTasks => List.unmodifiable(_inProgressTasks);
  List<Task> get completedTasks => List.unmodifiable(_completedTasks);
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskStatus? get filterStatus => _filterStatus;
  TaskPriority? get filterPriority => _filterPriority;
  String? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get analytics => _analytics;
  
  // Performance counters
  int get totalTasks => _allTasks.length;
  int get pendingCount => _pendingTasks.length;
  int get inProgressCount => _inProgressTasks.length;
  int get completedCount => _completedTasks.length;

  // Optimized filtered tasks with caching
  List<Task> _getFilteredTasksOptimized() {
    final cacheKey = '$_filterStatus-$_filterPriority-$_filterCategory-$_searchQuery';
    
    // Return cached result if available and valid
    if (_cachedFilteredTasks.containsKey(cacheKey)) {
      return _cachedFilteredTasks[cacheKey]!;
    }
    
    List<Task> filteredTasks = List.from(_allTasks);

    // Filter by status (use pre-sorted lists for better performance)
    if (_filterStatus != null) {
      switch (_filterStatus!) {
        case TaskStatus.pending:
          filteredTasks = List.from(_pendingTasks);
          break;
        case TaskStatus.inProgress:
          filteredTasks = List.from(_inProgressTasks);
          break;
        case TaskStatus.completed:
          filteredTasks = List.from(_completedTasks);
          break;
        case TaskStatus.cancelled:
          filteredTasks = _allTasks.where((task) => task.status == TaskStatus.cancelled).toList();
          break;
      }
    }

    // Filter by priority
    if (_filterPriority != null) {
      filteredTasks = filteredTasks.where((task) => task.priority == _filterPriority).toList();
    }

    // Filter by category
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) => task.category == _filterCategory).toList();
    }

    // Filter by search query (optimized with early exit)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
               task.description.toLowerCase().contains(query) ||
               task.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Cache the result
    _cachedFilteredTasks[cacheKey] = filteredTasks;
    
    // Limit cache size to prevent memory leaks
    if (_cachedFilteredTasks.length > 10) {
      _cachedFilteredTasks.clear();
    }

    return filteredTasks;
  }

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _allTasks.where((task) => task.status == status).toList();
  }

  // Get overdue tasks
  List<Task> get overdueTasks {
    return _allTasks.where((task) => task.isOverdue).toList();
  }

  // Get tasks due today
  List<Task> get tasksDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  // Get tasks due soon (within 24 hours)
  List<Task> get tasksDueSoon {
    return _allTasks.where((task) => task.isDueSoon).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Optimized task loading with deduplication and caching
  void loadTasks(String userId) {
    // Avoid duplicate loads
    if (_lastUserId == userId && 
        DateTime.now().difference(_lastLoadTime).inSeconds < 5 && 
        !_allTasks.isEmpty) {
      debugPrint('Skipping task reload - recent data available');
      return;
    }
    
    _setLoading(true);
    _setError(null);
    _lastUserId = userId;
    _lastLoadTime = DateTime.now();
    
    debugPrint('Loading tasks for user: $userId');
    
    // Cancel existing subscription to prevent memory leaks
    _tasksSubscription?.cancel();
    
    _tasksSubscription = _databaseService.getUserTasks(userId).listen(
      (tasks) {
        debugPrint('Received ${tasks.length} tasks from database');
        _updateTaskLists(tasks);
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading tasks: $error');
        _setError('Failed to load tasks: ${error.toString()}');
        _setLoading(false);
      },
    );
    
    // Load analytics in background
    _loadAnalytics(userId);
  }
  
  // Efficiently update task lists by status
  void _updateTaskLists(List<Task> newTasks) {
    _allTasks = newTasks;
    _pendingTasks = newTasks.where((task) => task.status == TaskStatus.pending).toList();
    _inProgressTasks = newTasks.where((task) => task.status == TaskStatus.inProgress).toList();
    _completedTasks = newTasks.where((task) => task.status == TaskStatus.completed).toList();
    
    // Clear cache when data changes
    _cachedFilteredTasks.clear();
  }

  // Load user analytics
  Future<void> _loadAnalytics(String userId) async {
    try {
      _analytics = await _databaseService.getUserAnalytics(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  // Create a new task using enhanced database service
  Future<bool> createTask(Task task) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _databaseService.createTask(task);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update a task
  Future<bool> updateTask(Task task) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.updateTask(task);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.deleteTask(taskId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Complete a task
  Future<bool> completeTask(String taskId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.completeTask(taskId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to complete task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.updateTaskStatus(taskId, status);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update task priority
  Future<bool> updateTaskPriority(String taskId, TaskPriority priority) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.updateTaskPriority(taskId, priority);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task priority: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Search tasks
  Future<void> searchTasks(String userId, String query) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final searchResults = await _taskService.searchTasks(userId, query);
      _allTasks = searchResults;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search tasks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Set filters
  void setStatusFilter(TaskStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  // Optimized search with debouncing
  void setSearchQuery(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _cachedFilteredTasks.clear(); // Clear cache when search changes
        notifyListeners();
      }
    });
  }

  // Memory management and cleanup
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tasksSubscription?.cancel();
    _cachedFilteredTasks.clear();
    super.dispose();
  }
  
  // Clear all filters with cache cleanup
  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _filterCategory = null;
    _searchQuery = '';
    _cachedFilteredTasks.clear();
    notifyListeners();
  }

  // Enhanced methods for file management and progress
  Future<bool> addTaskAttachment(String taskId, String filePath) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final downloadUrl = await _storageService.pickAndUploadTaskAttachment(taskId);
      if (downloadUrl != null) {
        final attachment = TaskAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: filePath.split('/').last,
          url: downloadUrl,
          type: _getFileType(filePath),
          size: 0, // Will be updated with actual size
          uploadedAt: DateTime.now(),
        );
        
        await _databaseService.addTaskAttachment(taskId, attachment);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to add attachment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTaskProgress(String taskId, double progress) async {
    try {
      await _databaseService.updateTaskProgress(taskId, progress);
      return true;
    } catch (e) {
      _setError('Failed to update progress: ${e.toString()}');
      return false;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return 'image';
    } else if (['pdf', 'doc', 'docx', 'txt'].contains(extension)) {
      return 'document';
    }
    return 'other';
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      return await _taskService.getTaskStatistics(userId);
    } catch (e) {
      _setError('Failed to get task statistics: ${e.toString()}');
      return {};
    }
  }

  // Bulk update tasks
  Future<bool> bulkUpdateTasks(List<String> taskIds, Map<String, dynamic> updates) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.bulkUpdateTasks(taskIds, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to bulk update tasks: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete all tasks for user
  Future<bool> deleteAllTasks(String userId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _taskService.deleteAllUserTasks(userId);
      _allTasks.clear();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete all tasks: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}