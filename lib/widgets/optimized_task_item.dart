import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_task_screen.dart';

/// Optimized TaskItem widget with performance improvements
class OptimizedTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  
  const OptimizedTaskItem({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _showTaskDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDescription(context),
              ],
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Status checkbox - optimized with direct callback
        _OptimizedCheckbox(
          value: task.status == TaskStatus.completed,
          onChanged: (value) => _toggleTaskStatus(context),
        ),
        const SizedBox(width: 12),
        
        // Title and status chip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  decoration: task.status == TaskStatus.completed 
                      ? TextDecoration.lineThrough 
                      : null,
                  color: task.status == TaskStatus.completed 
                      ? Colors.grey 
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _OptimizedStatusChip(status: task.status),
            ],
          ),
        ),
        
        // Menu button
        _OptimizedMenuButton(task: task),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      task.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _OptimizedPriorityChip(priority: task.priority),
        if (task.dueDate != null) ...[
          const SizedBox(width: 8),
          _OptimizedDueDateChip(dueDate: task.dueDate!),
        ],
        const Spacer(),
        if (task.tags.isNotEmpty) ...[
          _OptimizedTagsWidget(tags: task.tags),
        ],
      ],
    );
  }

  void _toggleTaskStatus(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final newStatus = task.status == TaskStatus.completed 
        ? TaskStatus.pending 
        : TaskStatus.completed;
    
    if (newStatus == TaskStatus.completed) {
      taskProvider.completeTask(task.id);
    } else {
      taskProvider.updateTaskStatus(task.id, newStatus);
    }
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _TaskDetailsDialog(task: task),
    );
  }
}

/// Optimized checkbox that doesn't rebuild the entire widget
class _OptimizedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _OptimizedCheckbox({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Cached status chip to avoid rebuilding
class _OptimizedStatusChip extends StatelessWidget {
  final TaskStatus status;

  const _OptimizedStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return (Colors.orange, 'Pending');
      case TaskStatus.inProgress:
        return (Colors.blue, 'In Progress');
      case TaskStatus.completed:
        return (Colors.green, 'Completed');
      case TaskStatus.cancelled:
        return (Colors.red, 'Cancelled');
    }
  }
}

/// Cached priority chip
class _OptimizedPriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const _OptimizedPriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _getPriorityInfo(priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
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

  (Color, IconData, String) _getPriorityInfo(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return (Colors.green, Icons.keyboard_arrow_down, 'LOW');
      case TaskPriority.medium:
        return (Colors.orange, Icons.remove, 'MED');
      case TaskPriority.high:
        return (Colors.red, Icons.keyboard_arrow_up, 'HIGH');
      case TaskPriority.urgent:
        return (Colors.purple, Icons.priority_high, 'URG');
    }
  }
}

/// Optimized due date chip with caching
class _OptimizedDueDateChip extends StatelessWidget {
  final DateTime dueDate;

  const _OptimizedDueDateChip({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = now.isAfter(dueDate);
    final isDueSoon = !isOverdue && dueDate.difference(now).inHours <= 24;
    
    Color color = Colors.grey;
    IconData icon = Icons.schedule;
    
    if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning;
    } else if (isDueSoon) {
      color = Colors.orange;
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            DateFormat('MMM dd').format(dueDate),
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
}

/// Optimized tags widget with limited display
class _OptimizedTagsWidget extends StatelessWidget {
  final List<String> tags;

  const _OptimizedTagsWidget({required this.tags});

  @override
  Widget build(BuildContext context) {
    const maxTags = 2;
    final displayTags = tags.take(maxTags).toList();
    final hasMore = tags.length > maxTags;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayTags.map((tag) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
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
          ),
        )),
        if (hasMore)
          Text(
            '+${tags.length - maxTags}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}

/// Optimized menu button
class _OptimizedMenuButton extends StatelessWidget {
  final Task task;

  const _OptimizedMenuButton({required this.task});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: task.status == TaskStatus.completed ? 'reopen' : 'complete',
          child: ListTile(
            leading: Icon(task.status == TaskStatus.completed 
                ? Icons.refresh 
                : Icons.check),
            title: Text(task.status == TaskStatus.completed 
                ? 'Reopen' 
                : 'Complete'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
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
          const SnackBar(content: Text('Task completed!')),
        );
        break;
      case 'reopen':
        taskProvider.updateTaskStatus(task.id, TaskStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task reopened!')),
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
        content: Text('Delete "${task.title}"?'),
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
                const SnackBar(content: Text('Task deleted!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Optimized task details dialog
class _TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const _TaskDetailsDialog({required this.task});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            
            _buildDetailRow('Priority', task.priority.toString().split('.').last.toUpperCase()),
            _buildDetailRow('Status', task.status.toString().split('.').last),
            
            if (task.dueDate != null)
              _buildDetailRow('Due Date', DateFormat('MMM dd, yyyy HH:mm').format(task.dueDate!)),
            
            if (task.tags.isNotEmpty) ...[
              const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: task.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(task.createdAt)),
            
            if (task.completedAt != null)
              _buildDetailRow('Completed', DateFormat('MMM dd, yyyy HH:mm').format(task.completedAt!)),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}