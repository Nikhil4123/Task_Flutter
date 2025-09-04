import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/task_filter_chip.dart';
import 'add_task_screen.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
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
        title: const Text('Filter Tasks'),
        content: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
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
          appBar: AppBar(
            title: const Text('Task Manager'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      // TODO: Navigate to profile screen
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
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sign Out'),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundImage: user.photoUrl != null 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: user.photoUrl == null 
                        ? Text(user.displayName.isNotEmpty 
                            ? user.displayName[0].toUpperCase() 
                            : 'U')
                        : null,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Pending'),
                      Tab(text: 'In Progress'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(taskProvider.tasks),
              _buildTaskList(taskProvider.getTasksByStatus(TaskStatus.pending)),
              _buildTaskList(taskProvider.getTasksByStatus(TaskStatus.inProgress)),
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
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user.displayName),
                  accountEmail: Text(user.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: user.photoUrl != null 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: user.photoUrl == null 
                        ? Text(user.displayName.isNotEmpty 
                            ? user.displayName[0].toUpperCase() 
                            : 'U')
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Overdue Tasks'),
                  subtitle: Text('${taskProvider.overdueTasks.length} tasks'),
                  onTap: () {
                    // TODO: Show overdue tasks
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Due Today'),
                  subtitle: Text('${taskProvider.tasksDueToday.length} tasks'),
                  onTap: () {
                    // TODO: Show tasks due today
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warning),
                  title: const Text('Due Soon'),
                  subtitle: Text('${taskProvider.tasksDueSoon.length} tasks'),
                  onTap: () {
                    // TODO: Show tasks due soon
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Statistics'),
                  onTap: () {
                    // TODO: Show statistics screen
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    // TODO: Show settings screen
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          );
        }
        
        if (taskProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error: ${taskProvider.error}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                    if (authProvider.user != null) {
                      taskProvider.loadTasks(authProvider.user!.id);
                    }
                  },
                  child: Text('Retry'),
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
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
          child: TaskItem(task: task),
        );
      },
      // Add physics for better scrolling performance
      physics: const BouncingScrollPhysics(),
      // Cache extent for better performance
      cacheExtent: 500,
    );
  }
}