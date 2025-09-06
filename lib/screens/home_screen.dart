import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/simple_task_item.dart';
import '../widgets/task_filter_chip.dart';
import '../widgets/app_logo.dart';
import '../screens/add_task_screen.dart';
import '../screens/task_details_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Performance optimization: Limit items per page
  static const int _itemsPerPage = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  
  // Store reference to ScaffoldMessengerState for safe access
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to ScaffoldMessengerState for safe access
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Setup scroll controller for lazy loading
    _scrollController.addListener(_onScroll);
    
    // Load tasks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        taskProvider.loadTasks(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _scaffoldMessenger = null; // Clear reference
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTasks();
    }
  }
  
  void _loadMoreTasks() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      
      // Simulate loading delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.setSearchQuery(value);
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Filter Tasks',
          style: TextStyle(color: Colors.white),
        ),
        content: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TaskFilterChip(
                      label: 'All',
                      isSelected: taskProvider.filterStatus == null,
                      onTap: () => taskProvider.setStatusFilter(null),
                    ),
                    ...TaskStatus.values.map((status) => TaskFilterChip(
                      label: status.toString().split('.').last,
                      isSelected: taskProvider.filterStatus == status,
                      onTap: () => taskProvider.setStatusFilter(status),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TaskFilterChip(
                      label: 'All',
                      isSelected: taskProvider.filterPriority == null,
                      onTap: () => taskProvider.setPriorityFilter(null),
                    ),
                    ...TaskPriority.values.map((priority) => TaskFilterChip(
                      label: priority.toString().split('.').last,
                      isSelected: taskProvider.filterPriority == priority,
                      onTap: () => taskProvider.setPriorityFilter(priority),
                    )),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<app_auth.AuthProvider, TaskProvider>(
      builder: (context, authProvider, taskProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const LoginScreen();
        }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Task Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                  break;
                case 'theme':
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  break;
                case 'settings':
                  // TODO: Navigate to settings screen
                  break;
                case 'logout':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text('Profile', style: TextStyle(color: Colors.white)),
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      title: Text(
                        themeProvider.isDarkMode ? 'Light Theme' : 'Dark Theme',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text('Settings', style: TextStyle(color: Colors.white)),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text('Sign Out', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.purple,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ],
            ),
          ),
        ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(taskProvider.tasks),
              _buildTaskList(taskProvider.getTasksByStatus(TaskStatus.pending)),
              _buildTaskList(taskProvider.getTasksByStatus(TaskStatus.completed)),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Debug button to create a test task
              if (taskProvider.tasks.isEmpty)
                FloatingActionButton.extended(
                  onPressed: () async {
                    final testTask = Task.create(
                      title: 'Test Task ${DateTime.now().millisecondsSinceEpoch}',
                      description: 'This is a test task created for debugging',
                      userId: user.id,
                      priority: TaskPriority.medium,
                      tags: ['test', 'debug'],
                    );
                    
                    final success = await taskProvider.createTask(testTask);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test task created!')),
                      );
                    }
                  },
                  label: const Text('Create Test Task'),
                  icon: const Icon(Icons.bug_report),
                  heroTag: 'test',
                ),
              const SizedBox(height: 8),
              FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AddTaskScreen()),
                  );
                },
                heroTag: 'add',
                child: const Icon(Icons.add),
              ),
            ],
          ),
          // Bottom navigation or drawer for additional features
          drawer: Drawer(
            backgroundColor: Colors.black,
            child: Column(
              children: [
                // Enhanced Header
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.withValues(alpha: 0.8),
                        Colors.blue.withValues(alpha: 0.6),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.purple, Colors.blue],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            user.photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${taskProvider.completedCount}/${taskProvider.totalTasks} Tasks Completed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.schedule,
                        title: 'Overdue Tasks',
                        subtitle: '${taskProvider.overdueTasks.length} tasks',
                        color: Colors.red,
                        onTap: () {
                          // TODO: Show overdue tasks
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.today,
                        title: 'Due Today',
                        subtitle: '${taskProvider.tasksDueToday.length} tasks',
                        color: Colors.blue,
                        onTap: () {
                          // TODO: Show tasks due today
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.warning,
                        title: 'Due Soon',
                        subtitle: '${taskProvider.tasksDueSoon.length} tasks',
                        color: Colors.orange,
                        onTap: () {
                          // TODO: Show tasks due soon
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(color: Colors.grey, height: 32),
                      _buildDrawerItem(
                        icon: Icons.analytics,
                        title: 'Statistics',
                        subtitle: 'View your progress',
                        color: Colors.green,
                        onTap: () {
                          // TODO: Show statistics screen
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person,
                        title: 'Profile',
                        subtitle: 'Manage your account',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'App preferences',
                        color: Colors.grey,
                        onTap: () {
                          // TODO: Show settings screen
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircularAppLogo(size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'TaskManager',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 16),
                Text(
                  'Loading tasks...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }
        
        if (taskProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${taskProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                    if (authProvider.user != null) {
                      taskProvider.loadTasks(authProvider.user!.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first task by tapping the + button',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
            
            if (authProvider.user != null) {
              taskProvider.loadTasks(authProvider.user!.id);
              // Wait a bit to ensure the data is refreshed
              await Future.delayed(const Duration(milliseconds: 500));
            }
          },
          child: _buildOptimizedListView(tasks),
        );
      },
    );
  }
  
  Widget _buildOptimizedListView(List<Task> tasks) {
    // Implement pagination for better performance
    final itemsToShow = _currentPage * _itemsPerPage;
    final displayTasks = tasks.take(itemsToShow).toList();
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayTasks.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= displayTasks.length) {
          // Loading indicator
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final task = displayTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SimpleTaskItem(
            task: task,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(task: task),
                ),
              );
            },
            onToggleComplete: (value) async {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              
              // Show immediate optimistic UI feedback
              HapticFeedback.lightImpact();
              
              try {
                bool success = false;
                if (value) {
                  success = await taskProvider.completeTask(task.id);
                  if (success && mounted && _scaffoldMessenger != null) {
                    _scaffoldMessenger!.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('"${task.title}" completed!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: Colors.white,
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await taskProvider.updateTaskStatus(task.id, TaskStatus.pending);
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  success = await taskProvider.updateTaskStatus(task.id, TaskStatus.pending);
                  if (success && mounted && _scaffoldMessenger != null) {
                    _scaffoldMessenger!.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.refresh, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('"${task.title}" reopened'),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
                
                if (!success) {
                  throw Exception('Operation failed');
                }
                
              } catch (e) {
                debugPrint('Error updating task status: $e');
                if (mounted && _scaffoldMessenger != null) {
                  _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Failed to update task. Please try again.'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'RETRY',
                        textColor: Colors.white,
                        onPressed: () async {
                          // Retry the operation
                          if (value) {
                            await taskProvider.completeTask(task.id);
                          } else {
                            await taskProvider.updateTaskStatus(task.id, TaskStatus.pending);
                          }
                        },
                      ),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
      // Add physics for better scrolling performance
      physics: const BouncingScrollPhysics(),
      // Cache extent for better performance
      cacheExtent: 500,
    );
  }
}