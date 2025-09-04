import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Get tasks stream for a user
  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks by status
  Stream<List<Task>> getUserTasksByStatus(String userId, TaskStatus status) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks by priority
  Stream<List<Task>> getUserTasksByPriority(String userId, TaskPriority priority) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('priority', isEqualTo: priority.toString().split('.').last)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get overdue tasks
  Stream<List<Task>> getUserOverdueTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .where('dueDate', isLessThan: Timestamp.now())
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks due today
  Stream<List<Task>> getUserTasksDueToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Create a new task
  Future<String> createTask(Task task) async {
    try {
      final docRef = await _firestore.collection(_collection).add(task.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(task.id)
          .update(task.toFirestore());
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Mark task as completed
  Future<void> completeTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'status': TaskStatus.completed.toString().split('.').last,
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error completing task: $e');
      rethrow;
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (status == TaskStatus.completed) {
        updateData['completedAt'] = Timestamp.now();
      }

      await _firestore.collection(_collection).doc(taskId).update(updateData);
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  // Update task priority
  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'priority': priority.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating task priority: $e');
      rethrow;
    }
  }

  // Search tasks by title or description
  Future<List<Task>> searchTasks(String userId, String searchTerm) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches for exact matches
      final titleResults = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final descriptionResults = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('description', isGreaterThanOrEqualTo: searchTerm)
          .where('description', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final Set<Task> allTasks = {};
      allTasks.addAll(titleResults.docs.map((doc) => Task.fromFirestore(doc)));
      allTasks.addAll(descriptionResults.docs.map((doc) => Task.fromFirestore(doc)));

      return allTasks.toList();
    } catch (e) {
      debugPrint('Error searching tasks: $e');
      return [];
    }
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

      return {
        'total': tasks.length,
        'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
        'inProgress': tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
        'overdue': tasks.where((t) => t.isOverdue).length,
        'dueSoon': tasks.where((t) => t.isDueSoon).length,
      };
    } catch (e) {
      debugPrint('Error getting task statistics: $e');
      return {};
    }
  }

  // Bulk update tasks
  Future<void> bulkUpdateTasks(List<String> taskIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (final taskId in taskIds) {
        final docRef = _firestore.collection(_collection).doc(taskId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error bulk updating tasks: $e');
      rethrow;
    }
  }

  // Delete all user tasks (for cleanup)
  Future<void> deleteAllUserTasks(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all user tasks: $e');
      rethrow;
    }
  }
}