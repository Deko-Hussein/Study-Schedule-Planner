import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class WeekTimeline extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const WeekTimeline({super.key, this.onDateSelected});

  @override
  State<WeekTimeline> createState() => _WeekTimelineState();
}

class _WeekTimelineState extends State<WeekTimeline> {
  late int selectedDateIndex;
  late List<DateTime> weekDates;

  @override
  void initState() {
    super.initState();
    weekDates = _generateWeekDates();
    // Find today's index or default to first day
    selectedDateIndex = _getTodayIndex();
  }

  List<DateTime> _generateWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  int _getTodayIndex() {
    final now = DateTime.now();
    return weekDates.indexWhere((date) =>
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
  }

  String _getDayLabel(int weekday) {
    final labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(weekDates.length, (index) {
            final date = weekDates[index];
            final isActive = index == selectedDateIndex;
            final dayLabel = _getDayLabel(date.weekday);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDateIndex = index;
                });
                widget.onDateSelected?.call(date);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2563EB) : AppColor.kbgColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColor.kTextStyleColorGray,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date.day.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppColor.kSecondColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}