import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/exports.dart';

class HomeScreen extends StatefulWidget {
  final ValueListenable<int>? refreshListenable;
  final VoidCallback? onTaskChanged;

  const HomeScreen({
    super.key,
    this.refreshListenable,
    this.onTaskChanged,
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

  final List<String> categories = const [
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

  List<ScheduleTask> get filteredTasks {
    return _tasks.where((task) {
      final matchesCategory =
          selectedCategory == 0 || task.category == categories[selectedCategory];

      final matchesFilter =
          selectedFilter == 0 ||
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

  Future<void> toggleTask(ScheduleTask task) async {
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
    final completedCount = _tasks.where((task) => task.completed).length;

    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(),
              const SizedBox(height: 24),
              const MonthCard(),
              const SizedBox(height: 18),
              const WeekTimeline(),
              const SizedBox(height: 24),
              ScheduleHeader(
                selected: selectedFilter,
                onChanged: (index) {
                  setState(() {
                    selectedFilter = index;
                  });
                },
              ),
              const SizedBox(height: 18),
              CategoryChips(
                selected: selectedCategory,
                onChanged: (index) {
                  setState(() {
                    selectedCategory = index;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Upcoming Tasks',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kSecondColor,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/${_tasks.length} done',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildTaskBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.kPrimaryColor),
      );
    }

    if (_authRequired) {
      return const _StatusMessage(
        message: 'Log in to see your saved tasks.',
        actionLabel: null,
        onTap: null,
      );
    }

    if (_error != null) {
      return _StatusMessage(
        message: 'Could not load tasks.',
        actionLabel: 'Retry',
        onTap: _loadTasks,
      );
    }

    if (filteredTasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: _EmptyMessage()),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: filteredTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final task = filteredTasks[index];

          return TaskCard(
            task: task,
            onTap: () => toggleTask(task),
          );
        },
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onTap;

  const _StatusMessage({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColor.kTextStyleColorGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap == null ? null : () => onTap!.call(),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No tasks match this filter.',
      style: GoogleFonts.inter(
        color: AppColor.kTextStyleColorGray,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}
