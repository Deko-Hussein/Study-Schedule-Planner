import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskDetailScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? time;
  final String? category;
  final bool completed;

  const TaskDetailScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.time,
    this.category,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      appBar: AppBar(
        backgroundColor: AppColor.kbgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Task Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColor.kSecondColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: AppColor.kPrimaryColor,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColor.kSecondColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  subtitle ?? 'No description added for this task.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColor.kTextStyleColorGray,
                  ),
                ),

                const SizedBox(height: 28),

                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: time ?? 'Not set',
                ),

                const SizedBox(height: 16),

                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: category ?? 'General',
                ),

                const SizedBox(height: 16),

                _DetailRow(
                  icon: completed
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  label: 'Status',
                  value: completed ? 'Completed' : 'Pending',
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Back to Planner',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColor.kbgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColor.kPrimaryColor,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.kTextStyleColorGray,
              ),
            ),
          ),

          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
        ],
      ),
    );
  }
}