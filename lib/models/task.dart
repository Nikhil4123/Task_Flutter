import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { pending, inProgress, completed, cancelled }

class TaskAttachment {
  final String id;
  final String name;
  final String url;
  final String type; // 'image', 'document', 'other'
  final int size;
  final DateTime uploadedAt;

  TaskAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'other',
      size: map['size'] ?? 0,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String userId;
  final List<String> tags;
  final List<TaskAttachment> attachments;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final String? assignedTo; // For future team features
  final double? progress; // Task completion percentage (0.0 to 1.0)
  final String? category; // Task category for organization

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.userId,
    required this.tags,
    required this.attachments,
    this.completedAt,
    required this.updatedAt,
    this.assignedTo,
    this.progress,
    this.category,
  });

  // Create a new task
  factory Task.create({
    required String title,
    required String description,
    required String userId,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
    String? category,
    double? progress,
  }) {
    final now = DateTime.now();
    return Task(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      createdAt: now,
      dueDate: dueDate,
      priority: priority,
      status: TaskStatus.pending,
      userId: userId,
      tags: tags,
      attachments: [],
      updatedAt: now,
      category: category,
      progress: progress ?? 0.0,
    );
  }

  // Convert from Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == 'TaskPriority.${data['priority']}',
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${data['status']}',
        orElse: () => TaskStatus.pending,
      ),
      userId: data['userId'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) => TaskAttachment.fromMap(attachment as Map<String, dynamic>))
          .toList(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'],
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      category: data['category'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'userId': userId,
      'tags': tags,
      'attachments': attachments.map((attachment) => attachment.toMap()).toList(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedTo': assignedTo,
      'progress': progress ?? 0.0,
      'category': category,
    };
  }

  // Copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? userId,
    List<String>? tags,
    List<TaskAttachment>? attachments,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? assignedTo,
    double? progress,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      assignedTo: assignedTo ?? this.assignedTo,
      progress: progress ?? this.progress,
      category: category ?? this.category,
    );
  }

  // Mark task as completed
  Task markCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Check if task is due soon (within 24 hours)
  bool get isDueSoon {
    if (dueDate == null || status == TaskStatus.completed) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inHours <= 24 && difference.inHours > 0;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}