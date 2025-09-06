import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';

/// Simple task item widget for main task list (Image 1 design)
/// Shows only task title with icon and completion status
class SimpleTaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleComplete;

  const SimpleTaskItem({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
  });

  @override
  State<SimpleTaskItem> createState() => _SimpleTaskItemState();
}

class _SimpleTaskItemState extends State<SimpleTaskItem> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(context),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Task icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTaskIcon(),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Task title
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: widget.task.status == TaskStatus.completed 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: widget.task.status == TaskStatus.completed 
                                  ? Colors.grey 
                                  : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Completion checkbox
                        _buildCheckboxWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckboxWidget() {
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        _handleCheckboxTap();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.task.status == TaskStatus.completed 
                ? Colors.green 
                : Colors.transparent,
            border: Border.all(
              color: _isUpdating
                  ? Colors.blue
                  : widget.task.status == TaskStatus.completed 
                      ? Colors.green 
                      : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : widget.task.status == TaskStatus.completed
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
        ),
      ),
    );
  }

  void _handleCheckboxTap() async {
    if (_isUpdating || widget.onToggleComplete == null) return;
    
    // Add haptic feedback for better user experience
    HapticFeedback.lightImpact();
    
    setState(() {
      _isUpdating = true;
    });
    
    // Add visual feedback
    _fadeController.forward();
    
    try {
      final newValue = widget.task.status != TaskStatus.completed;
      widget.onToggleComplete!(newValue);
      
      // Provide additional haptic feedback on successful completion
      if (newValue) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          HapticFeedback.mediumImpact();
        }
      }
      
      // Wait a bit for the operation to complete
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        _fadeController.reverse();
      }
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (widget.task.status) {
      case TaskStatus.completed:
        return Colors.green.withValues(alpha: 0.3);
      case TaskStatus.inProgress:
        return Colors.orange.withValues(alpha: 0.3);
      case TaskStatus.pending:
        return Colors.grey.withValues(alpha: 0.2);
      case TaskStatus.cancelled:
        return Colors.red.withValues(alpha: 0.3);
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.task.priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  IconData _getTaskIcon() {
    if (widget.task.dueDate != null && widget.task.isOverdue) {
      return Icons.warning;
    }
    
    switch (widget.task.status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.pending:
        return Icons.radio_button_unchecked;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }
}