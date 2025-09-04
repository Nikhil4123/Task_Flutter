import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/user.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'users';
  static const String _tasksCollection = 'tasks';
  static const String _categoriesCollection = 'categories';
  static const String _analyticsCollection = 'analytics';

  // User Management
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'version': 1,
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).update({
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'lastActive': FieldValue.serverTimestamp(),
        'isEmailVerified': user.isEmailVerified,
      });
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Stream<AppUser?> getUserProfile(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Task Management
  Future<String> createTask(Task task) async {
    try {
      final docRef = await _firestore.collection(_tasksCollection).add({
        ...task.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user analytics
      await _updateUserAnalytics(task.userId, 'tasksCreated', 1);
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection(_tasksCollection).doc(task.id).update({
        ...task.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final taskDoc = await _firestore.collection(_tasksCollection).doc(taskId).get();
      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final userId = taskData['userId'];
        
        // Delete the task
        await _firestore.collection(_tasksCollection).doc(taskId).delete();
        
        // Update user analytics
        await _updateUserAnalytics(userId, 'tasksDeleted', 1);
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Stream<List<Task>> getUserTasks(String userId) {
    debugPrint('DatabaseService: Getting tasks for user $userId');
    
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      debugPrint('DatabaseService: Received ${snapshot.docs.length} task documents');
      
      final tasks = snapshot.docs.map((doc) {
        try {
          final task = Task.fromFirestore(doc);
          debugPrint('Parsed task: ${task.title}');
          return task;
        } catch (e) {
          debugPrint('Error parsing task document ${doc.id}: $e');
          return null;
        }
      }).where((task) => task != null).cast<Task>().toList();
      
      // Sort by updatedAt in memory to avoid Firestore index issues
      tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      debugPrint('Successfully parsed ${tasks.length} tasks');
      return tasks;
    });
  }

  Stream<List<Task>> getTasksByStatus(String userId, TaskStatus status) {
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Task>> getTasksByCategory(String userId, String category) {
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Task>> getOverdueTasks(String userId) {
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .where('dueDate', isLessThan: Timestamp.now())
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Task>> getTasksDueToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection(_tasksCollection)
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

  Future<void> completeTask(String taskId) async {
    try {
      final taskDoc = await _firestore.collection(_tasksCollection).doc(taskId).get();
      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final userId = taskData['userId'];
        
        await _firestore.collection(_tasksCollection).doc(taskId).update({
          'status': TaskStatus.completed.toString().split('.').last,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'progress': 1.0,
        });
        
        // Update user analytics
        await _updateUserAnalytics(userId, 'tasksCompleted', 1);
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskProgress(String taskId, double progress) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Auto-complete if progress reaches 100%
      if (progress >= 1.0) {
        await completeTask(taskId);
      }
    } catch (e) {
      debugPrint('Error updating task progress: $e');
      rethrow;
    }
  }

  Future<void> addTaskAttachment(String taskId, TaskAttachment attachment) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'attachments': FieldValue.arrayUnion([attachment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding task attachment: $e');
      rethrow;
    }
  }

  Future<void> removeTaskAttachment(String taskId, TaskAttachment attachment) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'attachments': FieldValue.arrayRemove([attachment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing task attachment: $e');
      rethrow;
    }
  }

  // Category Management
  Future<void> createCategory(String userId, String categoryName, String color) async {
    try {
      await _firestore.collection(_categoriesCollection).add({
        'userId': userId,
        'name': categoryName,
        'color': color,
        'taskCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating category: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserCategories(String userId) {
    return _firestore
        .collection(_categoriesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Search and Filtering
  Future<List<Task>> searchTasks(String userId, String searchTerm) async {
    try {
      // Search in title
      final titleResults = await _firestore
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId)
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      // Search in description  
      final descriptionResults = await _firestore
          .collection(_tasksCollection)
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

  // Analytics and Statistics
  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final analyticsDoc = await _firestore
          .collection(_analyticsCollection)
          .doc(userId)
          .get();

      if (analyticsDoc.exists) {
        return analyticsDoc.data()!;
      } else {
        // Create initial analytics document
        final initialAnalytics = {
          'userId': userId,
          'tasksCreated': 0,
          'tasksCompleted': 0,
          'tasksDeleted': 0,
          'totalTimeSpent': 0,
          'streakDays': 0,
          'lastActivity': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection(_analyticsCollection)
            .doc(userId)
            .set(initialAnalytics);
            
        return initialAnalytics;
      }
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      return {};
    }
  }

  Future<void> _updateUserAnalytics(String userId, String field, int increment) async {
    try {
      await _firestore.collection(_analyticsCollection).doc(userId).set({
        'userId': userId,
        field: FieldValue.increment(increment),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user analytics: $e');
    }
  }

  Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      final now = DateTime.now();

      return {
        'total': tasks.length,
        'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
        'inProgress': tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
        'cancelled': tasks.where((t) => t.status == TaskStatus.cancelled).length,
        'overdue': tasks.where((t) => t.isOverdue).length,
        'dueSoon': tasks.where((t) => t.isDueSoon).length,
        'dueToday': tasks.where((t) {
          if (t.dueDate == null) return false;
          final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          final today = DateTime(now.year, now.month, now.day);
          return taskDate.isAtSameMomentAs(today);
        }).length,
      };
    } catch (e) {
      debugPrint('Error getting task statistics: $e');
      return {};
    }
  }

  // Batch Operations
  Future<void> bulkUpdateTasks(List<String> taskIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (final taskId in taskIds) {
        final docRef = _firestore.collection(_tasksCollection).doc(taskId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error bulk updating tasks: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteTasks(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final taskId in taskIds) {
        final docRef = _firestore.collection(_tasksCollection).doc(taskId);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error bulk deleting tasks: $e');
      rethrow;
    }
  }

  // Data Cleanup
  Future<void> deleteAllUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete all tasks
      final tasksSnapshot = await _firestore
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete all categories
      final categoriesSnapshot = await _firestore
          .collection(_categoriesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in categoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete analytics
      batch.delete(_firestore.collection(_analyticsCollection).doc(userId));
      
      // Delete user profile
      batch.delete(_firestore.collection(_usersCollection).doc(userId));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all user data: $e');
      rethrow;
    }
  }

  // Backup and Export
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final userData = <String, dynamic>{};
      
      // Export user profile
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (userDoc.exists) {
        userData['profile'] = userDoc.data();
      }
      
      // Export tasks
      final tasksSnapshot = await _firestore
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();
      userData['tasks'] = tasksSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Export categories
      final categoriesSnapshot = await _firestore
          .collection(_categoriesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      userData['categories'] = categoriesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Export analytics
      final analyticsDoc = await _firestore.collection(_analyticsCollection).doc(userId).get();
      if (analyticsDoc.exists) {
        userData['analytics'] = analyticsDoc.data();
      }
      
      userData['exportedAt'] = DateTime.now().toIso8601String();
      
      return userData;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      rethrow;
    }
  }

  // Connection monitoring
  Stream<bool> get connectionState {
    return _firestore
        .collection('.info')
        .doc('connected')
        .snapshots()
        .map((snapshot) => snapshot.exists && snapshot.data()?['connected'] == true);
  }
}