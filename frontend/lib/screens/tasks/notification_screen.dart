import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_task.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/color.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const List<String> _reminderOptions = <String>[
    'Exact Time',
    '15 Mins',
    '1 Hour',
  ];
  static const List<String> _soundOptions = <String>[
    'Classic Chime',
    'Crystal',
    'Minimalist',
  ];

  bool _loading = true;
  bool _saving = false;
  bool _authRequired = false;
  String? _error;
  String _reminderTime = '15 Mins';
  String _alertSound = 'Classic Chime';
  List<ScheduleTask> _pendingTasks = <ScheduleTask>[];
  List<ScheduleTask> _completedTasks = <ScheduleTask>[];

  @override
  void initState() {
    super.initState();
    _hydrateFromAuth();
    _loadNotifications();
  }

  void _hydrateFromAuth() {
    final defaults = context.read<AuthProvider>().notifications;
    _reminderTime = defaults['reminderTime']?.toString() ?? _reminderTime;
    _alertSound = defaults['alertSound']?.toString() ?? _alertSound;
  }

  Future<void> _loadNotifications() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _authRequired = true;
          _loading = false;
        });
        return;
      }

      final responses = await Future.wait(<Future<Map<String, dynamic>>>[
        ApiService.getTasks(),
        ApiService.getTaskHistory(),
        ApiService.getReminders(),
      ]);

      final activeTasksData = responses[0]['tasks'];
      final historyTasksData = responses[1]['tasks'];
      final reminderData = responses[2]['reminders'] as Map<String, dynamic>?;

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingTasks = activeTasksData is List
            ? activeTasksData
                .whereType<Map<String, dynamic>>()
                .map(ScheduleTask.fromApi)
                .where((task) => !task.completed)
                .toList()
            : <ScheduleTask>[];
        _completedTasks = historyTasksData is List
            ? historyTasksData
                .whereType<Map<String, dynamic>>()
                .map(ScheduleTask.fromApi)
                .where((task) => task.completed)
                .toList()
            : <ScheduleTask>[];
        _reminderTime =
            reminderData?['reminderTime']?.toString() ?? _reminderTime;
        _alertSound = reminderData?['alertSound']?.toString() ?? _alertSound;
        _authRequired = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    setState(() {
      if (key == 'reminderTime') {
        _reminderTime = value;
      } else if (key == 'alertSound') {
        _alertSound = value;
      }
      _saving = true;
    });

    try {
      await ApiService.updateReminders(<String, dynamic>{
        'reminderTime': _reminderTime,
        'alertSound': _alertSound,
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update notification settings right now.',
            style: GoogleFonts.inter(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<ScheduleTask> get _overdueTasks {
    final now = DateTime.now();
    final tasks = _pendingTasks
        .where((task) => task.dueDate != null && task.dueDate!.isBefore(now))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasks;
  }

  List<ScheduleTask> get _todayTasks {
    final now = DateTime.now();
    final tasks = _pendingTasks
        .where(
          (task) =>
              task.dueDate != null && DateUtils.isSameDay(task.dueDate, now),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasks;
  }

  List<ScheduleTask> get _upcomingTasks {
    final now = DateTime.now();
    final tasks = _pendingTasks
        .where((task) {
          final dueDate = task.dueDate;
          return dueDate != null &&
              !DateUtils.isSameDay(dueDate, now) &&
              dueDate.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasks.take(4).toList();
  }

  List<ScheduleTask> get _recentlyCompleted {
    final tasks = _completedTasks
        .where((task) => task.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return tasks.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final requiresStateCard = _loading || _authRequired || _error != null;

    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _Header(
                onRefresh: _loadNotifications,
                saving: _saving,
              ),
              const SizedBox(height: 24),
              _HeroCard(
                urgentCount: _overdueTasks.length,
                todayCount: _todayTasks.length,
                nextReminder: _reminderTime,
                alertSound: _alertSound,
              ),
              const SizedBox(height: 18),
              _SettingsCard(
                reminderTime: _reminderTime,
                alertSound: _alertSound,
                saving: _saving,
                reminderOptions: _reminderOptions,
                soundOptions: _soundOptions,
                onReminderSelected: (value) =>
                    _updateSetting('reminderTime', value),
                onSoundSelected: (value) =>
                    _updateSetting('alertSound', value),
              ),
              const SizedBox(height: 18),
              if (requiresStateCard)
                _buildStateCard()
              else ...[
                _NotificationSection(
                  title: 'Needs Attention',
                  subtitle: 'Overdue tasks that should be handled first.',
                  emptyMessage: 'Nothing overdue. You are caught up.',
                  items: _overdueTasks,
                  tone: _NotificationTone.alert,
                ),
                const SizedBox(height: 18),
                _NotificationSection(
                  title: 'Due Today',
                  subtitle: 'Tasks scheduled for today.',
                  emptyMessage: 'No tasks are due today.',
                  items: _todayTasks,
                  tone: _NotificationTone.primary,
                ),
                const SizedBox(height: 18),
                _NotificationSection(
                  title: 'Coming Next',
                  subtitle: 'The next upcoming study reminders.',
                  emptyMessage: 'Add a task with a due time to see reminders here.',
                  items: _upcomingTasks,
                  tone: _NotificationTone.neutral,
                ),
                const SizedBox(height: 18),
                _CompletedSection(tasks: _recentlyCompleted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateCard() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: AppColor.kPrimaryColor),
        ),
      );
    }

    if (_authRequired) {
      return const _StateCard(
        icon: Icons.lock_outline_rounded,
        title: 'Login required',
        message: 'Sign in to see reminders created from your saved tasks.',
      );
    }

    return _StateCard(
      icon: Icons.wifi_tethering_error_rounded,
      title: 'Notifications unavailable',
      message: 'We could not load task reminders right now.',
      actionLabel: 'Try again',
      onAction: _loadNotifications,
    );
  }
}

class _Header extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool saving;

  const _Header({
    required this.onRefresh,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColor.kSecondColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kSecondColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                saving ? 'Saving reminder settings...' : 'Task reminders and recent updates',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColor.kTextStyleColorGray,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onRefresh(),
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.refresh_rounded,
                size: 22,
                color: AppColor.kPrimaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int urgentCount;
  final int todayCount;
  final String nextReminder;
  final String alertSound;

  const _HeroCard({
    required this.urgentCount,
    required this.todayCount,
    required this.nextReminder,
    required this.alertSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColor.kSecondColor,
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimaryColor.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('EEE, MMM d').format(DateTime.now()),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            urgentCount > 0
                ? '$urgentCount task${urgentCount == 1 ? '' : 's'} need attention.'
                : 'All clear for now.',
            style: GoogleFonts.inter(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You have $todayCount task${todayCount == 1 ? '' : 's'} due today. Reminders are set for $nextReminder with $alertSound.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Urgent',
                  value: '$urgentCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Today',
                  value: '$todayCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String reminderTime;
  final String alertSound;
  final bool saving;
  final List<String> reminderOptions;
  final List<String> soundOptions;
  final ValueChanged<String> onReminderSelected;
  final ValueChanged<String> onSoundSelected;

  const _SettingsCard({
    required this.reminderTime,
    required this.alertSound,
    required this.saving,
    required this.reminderOptions,
    required this.soundOptions,
    required this.onReminderSelected,
    required this.onSoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reminder Defaults',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kSecondColor,
                ),
              ),
              const Spacer(),
              if (saving)
                Text(
                  'Saving',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These defaults are used for task reminder timing and sound.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColor.kTextStyleColorGray,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'REMINDER TIME',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColor.kTextStyleColorGray,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: reminderOptions.map((option) {
              final active = reminderTime == option;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == reminderOptions.last ? 0 : 8,
                  ),
                  child: InkWell(
                    onTap: () => onReminderSelected(option),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColor.kPrimaryColor
                            : AppColor.kbgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active
                              ? AppColor.kPrimaryColor
                              : AppColor.borderPrimary,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : AppColor.kTextStyleColorGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'ALERT SOUND',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColor.kTextStyleColorGray,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...soundOptions.map((sound) {
            final active = alertSound == sound;
            return InkWell(
              onTap: () => onSoundSelected(sound),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColor.kPrimaryColor.withValues(alpha: 0.06)
                      : AppColor.kbgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: active
                          ? AppColor.kPrimaryColor
                          : AppColor.kTextStyleColorGray,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sound,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kSecondColor,
                        ),
                      ),
                    ),
                    if (active)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColor.kPrimaryColor,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<ScheduleTask> items;
  final _NotificationTone tone;

  const _NotificationSection({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.items,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColor.kTextStyleColorGray,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _InlineEmptyState(message: emptyMessage)
          else
            ...items.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskNotificationTile(
                  task: task,
                  tone: tone,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletedSection extends StatelessWidget {
  final List<ScheduleTask> tasks;

  const _CompletedSection({
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Completed',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quick look at tasks you recently finished.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColor.kTextStyleColorGray,
            ),
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            const _InlineEmptyState(
              message: 'Completed tasks will appear here once you start finishing work.',
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskNotificationTile(
                  task: task,
                  tone: _NotificationTone.success,
                  completed: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskNotificationTile extends StatelessWidget {
  final ScheduleTask task;
  final _NotificationTone tone;
  final bool completed;

  const _TaskNotificationTile({
    required this.task,
    required this.tone,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _toneScheme(tone);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.alarm_rounded,
              color: scheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kSecondColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? _formatCompletedTime(task.completedAt)
                      : _formatDueTime(task.dueDate),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColor.kTextStyleColorGray,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: scheme.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueTime(DateTime? dueDate) {
    if (dueDate == null) {
      return 'No due time has been added yet.';
    }

    final localDate = dueDate.toLocal();
    final now = DateTime.now();

    if (DateUtils.isSameDay(localDate, now)) {
      return 'Due today at ${DateFormat('hh:mm a').format(localDate)}';
    }

    if (localDate.isBefore(now)) {
      return 'Was due ${DateFormat('MMM d, hh:mm a').format(localDate)}';
    }

    return 'Due ${DateFormat('EEE, MMM d • hh:mm a').format(localDate)}';
  }

  String _formatCompletedTime(DateTime? completedAt) {
    if (completedAt == null) {
      return 'Completed recently';
    }

    return 'Completed ${DateFormat('EEE, MMM d • hh:mm a').format(completedAt.toLocal())}';
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColor.kbgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColor.kTextStyleColorGray,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: AppColor.kPrimaryColor,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColor.kTextStyleColorGray,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onAction!.call(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

enum _NotificationTone {
  primary,
  alert,
  success,
  neutral,
}

class _NotificationScheme {
  final Color background;
  final Color border;
  final Color accent;

  const _NotificationScheme({
    required this.background,
    required this.border,
    required this.accent,
  });
}

_NotificationScheme _toneScheme(_NotificationTone tone) {
  switch (tone) {
    case _NotificationTone.alert:
      return const _NotificationScheme(
        background: Color(0xFFFFF4F4),
        border: Color(0xFFFECACA),
        accent: AppColor.kCheckOutActiveTextColor,
      );
    case _NotificationTone.success:
      return const _NotificationScheme(
        background: Color(0xFFF0FDF4),
        border: Color(0xFFBBF7D0),
        accent: AppColor.kCheckInActiveTextColor,
      );
    case _NotificationTone.neutral:
      return const _NotificationScheme(
        background: Color(0xFFF8FAFC),
        border: AppColor.borderPrimary,
        accent: AppColor.kSecondColor,
      );
    case _NotificationTone.primary:
      return const _NotificationScheme(
        background: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        accent: AppColor.kPrimaryColor,
      );
  }
}
 
