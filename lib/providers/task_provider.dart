import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String? _filterCategory;
  String _searchQuery = '';
  Map<String, dynamic> _analytics = {};

  // Getters
  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskStatus? get filterStatus => _filterStatus;
  TaskPriority? get filterPriority => _filterPriority;
  String? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get analytics => _analytics;

  // Get filtered tasks based on current filters
  List<Task> _getFilteredTasks() {
    List<Task> filteredTasks = List.from(_tasks);

    // Filter by status
    if (_filterStatus != null) {
      filteredTasks = filteredTasks.where((task) => task.status == _filterStatus).toList();
    }

    // Filter by priority
    if (_filterPriority != null) {
      filteredTasks = filteredTasks.where((task) => task.priority == _filterPriority).toList();
    }

    // Filter by category
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) => task.category == _filterCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final titleMatch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final descriptionMatch = task.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final tagMatch = task.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        return titleMatch || descriptionMatch || tagMatch;
      }).toList();
    }

    return filteredTasks;
  }

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Get overdue tasks
  List<Task> get overdueTasks {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  // Get tasks due today
  List<Task> get tasksDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  // Get tasks due soon (within 24 hours)
  List<Task> get tasksDueSoon {
    return _tasks.where((task) => task.isDueSoon).toList();
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

  // Load tasks for user using enhanced database service
  void loadTasks(String userId) {
    _setLoading(true);
    _setError(null);
    
    debugPrint('Loading tasks for user: $userId');
    
    _databaseService.getUserTasks(userId).listen(
      (tasks) {
        debugPrint('Received ${tasks.length} tasks from database');
        _tasks = tasks;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading tasks: $error');
        _setError('Failed to load tasks: ${error.toString()}');
        _setLoading(false);
      },
    );
    
    // Also load analytics
    _loadAnalytics(userId);
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
      _tasks = searchResults;
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _filterCategory = null;
    _searchQuery = '';
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
      _tasks.clear();
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