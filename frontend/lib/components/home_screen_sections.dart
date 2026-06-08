import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/schedule_task.dart';
import '../utils/color.dart';
import 'category_chips.dart';
import 'month_card.dart';
import 'schedule_header.dart';
import 'task_card.dart';
import 'top_bar.dart';
import 'week_timeline.dart';

class HomeOverviewSliver extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;
  final int selectedCategory;
  final ValueChanged<int> onCategoryChanged;
  final int completedCount;
  final int totalCount;

  const HomeOverviewSliver({
    super.key,
    this.onProfileTap,
    this.onNotificationTap,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          TopBar(
            onProfileTap: onProfileTap,
            onNotificationTap: onNotificationTap,
          ),
          const SizedBox(height: 28),
          const MonthCard(),
          const SizedBox(height: 20),
          const WeekTimeline(),
          const SizedBox(height: 28),
          ScheduleHeader(
            selected: selectedFilter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 18),
          CategoryChips(
            selected: selectedCategory,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 28),
          _UpcomingTasksHeader(
            completedCount: completedCount,
            totalCount: totalCount,
          ),
          const SizedBox(height: 18),
        ]),
      ),
    );
  }
}

class HomeTaskListSliver extends StatelessWidget {
  final List<ScheduleTask> tasks;
  final ValueChanged<ScheduleTask> onTaskTap;

  const HomeTaskListSliver({
    super.key,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              return const SizedBox(height: 14);
            }

            final task = tasks[index ~/ 2];
            return TaskCard(
              task: task,
              onTap: () => onTaskTap(task),
            );
          },
          childCount: tasks.length * 2 - 1,
        ),
      ),
    );
  }
}

class HomeMessageCard extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onTap;

  const HomeMessageCard({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColor.kbgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColor.kPrimaryColor,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                color: AppColor.kTextStyleColorGray,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onTap == null ? null : () => onTap!.call(),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColor.kbgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'No tasks match this filter.',
        style: GoogleFonts.inter(
          color: AppColor.kTextStyleColorGray,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UpcomingTasksHeader extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _UpcomingTasksHeader({
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColor.kbgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$completedCount/$totalCount done',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColor.kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
