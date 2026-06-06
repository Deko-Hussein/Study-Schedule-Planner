import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_task.dart';
import '../../services/api_service.dart';
import '../tasks/notification_screen.dart';
import '../../utils/color.dart';

class HistoryScreen extends StatefulWidget {
  final ValueListenable<int>? refreshListenable;
  final VoidCallback? onProfileTap;

  const HistoryScreen({
    super.key,
    this.refreshListenable,
    this.onProfileTap,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  bool _authRequired = false;
  bool _showAll = false;
  String? _error;
  List<ScheduleTask> _allTasks = <ScheduleTask>[];
  List<ScheduleTask> _completedTasks = <ScheduleTask>[];

  @override
  void initState() {
    super.initState();
    widget.refreshListenable?.addListener(_loadHistory);
    _loadHistory();
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
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
          _allTasks = [];
          _completedTasks = [];
          _authRequired = true;
          _loading = false;
        });
        return;
      }

      final responses = await Future.wait([
        ApiService.getTasks(),
        ApiService.getTaskHistory(),
      ]);

      final allTasksData = responses[0]['tasks'];
      final historyData = responses[1]['tasks'];

      if (!mounted) return;
      setState(() {
        _allTasks = allTasksData is List
            ? allTasksData
                .whereType<Map<String, dynamic>>()
                .map(ScheduleTask.fromApi)
                .toList()
            : <ScheduleTask>[];
        _completedTasks = historyData is List
            ? historyData
                .whereType<Map<String, dynamic>>()
                .map(ScheduleTask.fromApi)
                .toList()
            : <ScheduleTask>[];
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

  @override
  Widget build(BuildContext context) {
    final totalTasks = _allTasks.length;
    final completedCount = _completedTasks.length;
    final pendingCount = totalTasks >= completedCount ? totalTasks - completedCount : 0;
    final progress = totalTasks == 0 ? 0.0 : completedCount / totalTasks;
    final monthLabel = DateFormat('MMMM').format(DateTime.now());

    final visibleTasks = _showAll ? _completedTasks : _completedTasks.take(5).toList();

    return ColoredBox(
      color: AppColor.kbgColor,
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColor.kPrimaryColor),
              )
            : RefreshIndicator(
                onRefresh: _loadHistory,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 28),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _appHeader(),
                    const SizedBox(height: 28),
                    _overviewHeader(monthLabel),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: IconlyLight.calendar,
                            iconColor: AppColor.kPrimaryColor,
                            label: 'TOTAL TASKS',
                            value: '$totalTasks',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            icon: IconlyLight.tick_square,
                            iconColor: const Color(0xFF10B981),
                            label: 'COMPLETED',
                            value: '$completedCount',
                            mutedValue: '/ $totalTasks',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: IconlyLight.close_square,
                            iconColor: AppColor.kCheckOutActiveTextColor,
                            label: 'PENDING',
                            value: '$pendingCount',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            icon: IconlyLight.chart,
                            iconColor: AppColor.kSecondColor,
                            label: 'SUCCESS RATE',
                            value: '${(progress * 100).round()}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    _progressCard(progress, monthLabel),
                    const SizedBox(height: 28),
                    _sectionHeader(
                      canToggle: _completedTasks.length > 5,
                      showAll: _showAll,
                      onToggle: () => setState(() => _showAll = !_showAll),
                    ),
                    const SizedBox(height: 14),
                    if (_authRequired)
                      const _HistoryMessage('Log in to see completed task history.')
                    else if (_error != null)
                      _RetryMessage(onRetry: _loadHistory)
                    else if (_completedTasks.isEmpty)
                      const _HistoryMessage('No completed tasks yet.')
                    else
                      ...visibleTasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CompletedTaskCard(
                            title: task.title,
                            tag: task.category.toUpperCase(),
                            completedDate: _formatCompletedDate(task.completedAt),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatCompletedDate(DateTime? date) {
    if (date == null) return 'Completed recently';
    return 'Completed ${DateFormat('MMM dd').format(date.toLocal())}';
  }

  Widget _appHeader() => Row(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onProfileTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.borderPrimary),
                ),
                child: const Icon(
                  IconlyBold.profile,
                  size: 17,
                  color: AppColor.kPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Study Planner',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            icon: const Badge(
              smallSize: 6,
              backgroundColor: AppColor.kCheckOutActiveTextColor,
              child: Icon(
                IconlyLight.notification,
                size: 24,
                color: AppColor.kPrimaryColor,
              ),
            ),
          ),
        ],
      );

  Widget _overviewHeader(String monthLabel) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthLabel Overview',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColor.kSecondColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed tasks move here automatically.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColor.kTextStyleColorGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(
              IconlyLight.time_circle,
              color: Color(0xFFFF5B5B),
              size: 23,
            ),
          ),
        ],
      );

  Widget _progressCard(double progress, String monthLabel) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'MONTHLY PROGRESS',
                  style: _labelStyle(),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}% Done',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColor.borderPrimary,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColor.kPrimaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${monthLabel.substring(0, 3).toUpperCase()} 01', style: _dateStyle()),
                const Spacer(),
                Text(
                  '${monthLabel.substring(0, 3).toUpperCase()} ${DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month)}',
                  style: _dateStyle(),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _sectionHeader({
    required bool canToggle,
    required bool showAll,
    required VoidCallback onToggle,
  }) =>
      Row(
        children: [
          Text(
            'Completed Tasks',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColor.kSecondColor,
            ),
          ),
          const Spacer(),
          if (canToggle)
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    showAll ? 'Show Less' : 'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColor.kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    IconlyLight.arrow_right_2,
                    size: 14,
                    color: AppColor.kPrimaryColor,
                  ),
                ],
              ),
            ),
        ],
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppColor.kSecondColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  TextStyle _labelStyle() => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColor.kTextStyleColorGray,
        letterSpacing: 1,
      );

  TextStyle _dateStyle() => GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        color: AppColor.kTextStyleColorGray,
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? mutedValue;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.mutedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColor.kTextStyleColorGray,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColor.kSecondColor,
              ),
              children: [
                if (mutedValue != null)
                  TextSpan(
                    text: ' $mutedValue',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColor.borderPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  final String title;
  final String tag;
  final String completedDate;

  const _CompletedTaskCard({
    required this.title,
    required this.tag,
    required this.completedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: AppColor.kPrimaryColor,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColor.kPrimaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              IconlyBold.tick_square,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColor.kSecondColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: AppColor.kPrimaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        completedDate,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kTextStyleColorGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final String message;

  const _HistoryMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kTextStyleColorGray,
          ),
        ),
      ),
    );
  }
}

class _RetryMessage extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _RetryMessage({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: TextButton(
          onPressed: () => onRetry(),
          child: const Text('Retry loading history'),
        ),
      ),
    );
  }
}
