import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/home_screen_sections.dart';
import '../../utils/exports.dart';

class HomeScreen extends StatefulWidget {
  final ValueListenable<int>? refreshListenable;
  final VoidCallback? onTaskChanged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  const HomeScreen({
    super.key,
    this.refreshListenable,
    this.onTaskChanged,
    this.onProfileTap,
    this.onNotificationTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedFilter = 0;
  int selectedCategory = 0;
  bool _loading = true;
  bool _authRequired = false;
  String? _error;
  final Set<String> _updatingTaskIds = <String>{};
  List<ScheduleTask> _tasks = <ScheduleTask>[];

  final List<String> _categories = const [
    'All',
    'Study',
    'Assignment',
    'Exam',
    'Reading',
    'Personal',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    widget.refreshListenable?.addListener(_loadTasks);
    _loadTasks();
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_loadTasks);
    super.dispose();
  }

  List<ScheduleTask> get _filteredTasks {
    return _tasks.where((task) {
      final matchesCategory = selectedCategory == 0 ||
          task.category == _categories[selectedCategory];

      final matchesFilter = selectedFilter == 0 ||
          selectedFilter == 1 && !task.completed ||
          selectedFilter == 2 && task.completed;

      return matchesCategory && matchesFilter;
    }).toList();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _tasks = [];
          _authRequired = true;
          _loading = false;
        });
        return;
      }

      final res = await ApiService.getTasks();
      final data = res['tasks'];
      final tasks = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(ScheduleTask.fromApi)
              .toList()
          : <ScheduleTask>[];

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _authRequired = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleTask(ScheduleTask task) async {
    if (_updatingTaskIds.contains(task.id)) return;

    setState(() => _updatingTaskIds.add(task.id));

    try {
      final res = await ApiService.toggleTaskComplete(task.id);
      final rawTask = res['task'];
      if (rawTask is! Map<String, dynamic>) return;

      final updatedTask = ScheduleTask.fromApi(rawTask);

      if (!mounted) return;
      setState(() {
        if (!task.completed && updatedTask.completed) {
          // Just completed, remove from tasks
          _tasks = _tasks.where((item) => item.id != updatedTask.id).toList();
        } else {
          // Update or uncomplete, keep in tasks
          _tasks = _tasks.map((item) {
            return item.id == updatedTask.id ? updatedTask : item;
          }).toList();
        }
      });

      widget.onTaskChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update task: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColor.kCheckOutActiveTextColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingTaskIds.remove(task.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final completedCount = _tasks.where((task) => task.completed).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              HomeOverviewSliver(
                onProfileTap: widget.onProfileTap,
                onNotificationTap: widget.onNotificationTap,
                selectedFilter: selectedFilter,
                onFilterChanged: (index) {
                  setState(() => selectedFilter = index);
                },
                selectedCategory: selectedCategory,
                onCategoryChanged: (index) {
                  setState(() => selectedCategory = index);
                },
                completedCount: completedCount,
                totalCount: _tasks.length,
              ),
              ..._buildTaskSlivers(filteredTasks),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskSlivers(List<ScheduleTask> filteredTasks) {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColor.kPrimaryColor),
          ),
        ),
      ];
    }

    if (_authRequired) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: HomeMessageCard(
              message: 'Log in to see your saved tasks.',
              actionLabel: null,
              onTap: null,
            ),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: HomeMessageCard(
              message: 'Could not load tasks.',
              actionLabel: 'Retry',
              onTap: _loadTasks,
            ),
          ),
        ),
      ];
    }

    if (filteredTasks.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 72, 20, 28),
            child: Center(child: HomeEmptyStateCard()),
          ),
        ),
      ];
    }

    return [
      HomeTaskListSliver(
        tasks: filteredTasks,
        onTaskTap: _toggleTask,
      ),
    ];
  }
}
