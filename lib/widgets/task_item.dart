import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_task_screen.dart';
import 'package:intl/intl.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showTaskDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: task.status == TaskStatus.completed 
                            ? TextDecoration.lineThrough 
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      if (task.status != TaskStatus.completed)
                        const PopupMenuItem(
                          value: 'complete',
                          child: ListTile(
                            leading: Icon(Icons.check_circle),
                            title: Text('Mark Complete'),
                          ),
                        ),
                      if (task.status == TaskStatus.completed)
                        const PopupMenuItem(
                          value: 'reopen',
                          child: ListTile(
                            leading: Icon(Icons.replay),
                            title: Text('Reopen'),
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Description
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer with priority, due date, and tags
              Row(
                children: [
                  _buildPriorityChip(),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 8),
                    _buildDueDateChip(),
                  ],
                  const Spacer(),
                  if (task.tags.isNotEmpty) ...[
                    Flexible(
                      child: Wrap(
                        spacing: 4,
                        children: task.tags.take(2).map((tag) => _buildTagChip(tag)).toList(),
                      ),
                    ),
                    if (task.tags.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '+${task.tags.length - 2}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    
    switch (task.status) {
      case TaskStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        label = 'In Progress';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    Color color;
    IconData icon;
    
    switch (task.priority) {
      case TaskPriority.low:
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case TaskPriority.high:
        color = Colors.red;
        icon = Icons.keyboard_arrow_up;
        break;
      case TaskPriority.urgent:
        color = Colors.purple;
        icon = Icons.priority_high;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            task.priority.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip() {
    final isOverdue = task.isOverdue;
    final isDueSoon = task.isDueSoon;
    
    Color color = Colors.grey;
    IconData icon = Icons.schedule;
    
    if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning;
    } else if (isDueSoon) {
      color = Colors.orange;
      icon = Icons.schedule;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            DateFormat('MMM dd').format(task.dueDate!),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 10,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(task: task),
          ),
        );
        break;
      case 'complete':
        taskProvider.completeTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as completed')),
        );
        break;
      case 'reopen':
        taskProvider.updateTaskStatus(task.id, TaskStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task reopened')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description.isNotEmpty) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.description),
                const SizedBox(height: 16),
              ],
              
              const Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.priority.toString().split('.').last.toUpperCase()),
              const SizedBox(height: 16),
              
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.status.toString().split('.').last),
              const SizedBox(height: 16),
              
              if (task.dueDate != null) ...[
                const Text('Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(task.dueDate!)),
                const SizedBox(height: 16),
              ],
              
              if (task.tags.isNotEmpty) ...[
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: task.tags.map((tag) => _buildTagChip(tag)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text('Created:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(DateFormat('MMM dd, yyyy HH:mm').format(task.createdAt)),
              
              if (task.completedAt != null) ...[
                const SizedBox(height: 16),
                const Text('Completed:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(task.completedAt!)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTaskScreen(task: task),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}