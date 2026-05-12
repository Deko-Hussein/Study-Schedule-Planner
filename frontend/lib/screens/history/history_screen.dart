import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../../utils/color.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.kbgColor,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 28),
          children: [
            _appHeader(),
            const SizedBox(height: 28),
            _overviewHeader(),
            const SizedBox(height: 26),
            const Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: IconlyLight.time_circle,
                    iconColor: AppColor.kPrimaryColor,
                    label: 'STUDY HOURS',
                    value: '24.5 hrs',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: IconlyLight.tick_square,
                    iconColor: Color(0xFF10B981),
                    label: 'COMPLETED',
                    value: '18',
                    mutedValue: '/ 20',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _progressCard(),
            const SizedBox(height: 28),
            _sectionHeader(),
            const SizedBox(height: 14),
            const _CompletedTaskCard(
              title: 'Macroeconomics Essay Final Draft',
              tag: 'ASSIGNMENT',
              completedDate: 'Completed Oct 12',
            ),
            const SizedBox(height: 12),
            const _CompletedTaskCard(
              title: 'Midterm Statistics Review',
              tag: 'EXAM',
              completedDate: 'Completed Oct 10',
            ),
          ],
        ),
      ),
    );
  }

  Widget _appHeader() => Row(
        children: [
          Container(
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
            onPressed: () {},
            icon: Badge(
              smallSize: 6,
              backgroundColor: AppColor.kCheckOutActiveTextColor,
              child: const Icon(
                IconlyLight.notification,
                size: 24,
                color: AppColor.kPrimaryColor,
              ),
            ),
          ),
        ],
      );

  Widget _overviewHeader() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'October Overview',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColor.kSecondColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your productivity summary for this month.',
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
            onPressed: () {},
            icon: const Icon(
              IconlyLight.time_circle,
              color: Color(0xFFFF5B5B),
              size: 23,
            ),
          ),
        ],
      );

  Widget _progressCard() => Container(
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
                  '90% Done',
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
                value: 0.9,
                minHeight: 6,
                backgroundColor: AppColor.borderPrimary,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColor.kPrimaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('OCT 01', style: _dateStyle()),
                const Spacer(),
                Text('OCT 31', style: _dateStyle()),
              ],
            ),
          ],
        ),
      );

  Widget _sectionHeader() => Row(
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
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  'View All',
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

  static BoxDecoration _cardDecoration() => BoxDecoration(
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

  static TextStyle _labelStyle() => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColor.kTextStyleColorGray,
        letterSpacing: 1,
      );

  static TextStyle _dateStyle() => GoogleFonts.inter(
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
      decoration: HistoryScreen._cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(label, style: HistoryScreen._labelStyle()),
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
      decoration: HistoryScreen._cardDecoration(),
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
