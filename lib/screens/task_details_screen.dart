import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_task_screen.dart';

/// Task details screen showing progress, subtasks, and edit functionality (Image 2 design)
class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Get the updated task from provider
          final updatedTask = taskProvider.tasks.firstWhere(
            (t) => t.id == task.id,
            orElse: () => task,
          );
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskHeader(context, updatedTask),
                const SizedBox(height: 30),
                _buildProgressSection(context, updatedTask),
                const SizedBox(height: 30),
                _buildSubtasksSection(context, updatedTask, taskProvider),
                const SizedBox(height: 40),
                _buildEditButton(context, updatedTask),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskHeader(BuildContext context, Task task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(task.status),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(task.status),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              _getStatusIcon(task.status),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  task.dueDate != null 
                      ? DateFormat('MMM dd, yyyy').format(task.dueDate!)
                      : 'No due date',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(task.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(task.status),
              style: TextStyle(
                color: _getStatusColor(task.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task.completedSubtasksCount} of ${task.subtasks.length} subtasks complete',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(task.subtaskProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: task.subtaskProgress,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.subtaskProgress == 1.0 ? Colors.green : Colors.orange,
                ),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtasksSection(BuildContext context, Task task, TaskProvider taskProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.list,
              color: Colors.purple,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Subtasks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (task.subtasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No subtasks added',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...task.subtasks.map((subtask) => _buildSubtaskItem(
            context, 
            subtask, 
            task, 
            taskProvider,
          )),
      ],
    );
  }

  Widget _buildSubtaskItem(
    BuildContext context, 
    Subtask subtask, 
    Task task, 
    TaskProvider taskProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: subtask.isCompleted 
            ? Border.all(color: Colors.green.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleSubtask(context, subtask, task, taskProvider),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: subtask.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: subtask.isCompleted ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: subtask.isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                color: subtask.isCompleted ? Colors.grey[400] : Colors.white,
                fontSize: 16,
                decoration: subtask.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, Task task) {
    return Center(
      child: Container(
        width: 200, // Reduced width from double.infinity
        height: 48, // Reduced height from 56
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddTaskScreen(task: task),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Edit Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSubtask(BuildContext context, Subtask subtask, Task task, TaskProvider taskProvider) {
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtask.id) {
        return s.copyWith(
          isCompleted: !s.isCompleted,
          completedAt: !s.isCompleted ? DateTime.now() : null,
        );
      }
      return s;
    }).toList();

    // Check if all subtasks are completed
    final allSubtasksCompleted = updatedSubtasks.isNotEmpty && 
        updatedSubtasks.every((s) => s.isCompleted);
    
    // Auto-complete task if all subtasks are completed and task is not already completed
    TaskStatus newStatus = task.status;
    if (allSubtasksCompleted && task.status != TaskStatus.completed) {
      newStatus = TaskStatus.completed;
    }

    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : task.completedAt,
    );
    
    taskProvider.updateTask(updatedTask);
    
    // Show notification if task was auto-completed
    if (newStatus == TaskStatus.completed && task.status != TaskStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('🎉 Task "${task.title}" completed automatically!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}