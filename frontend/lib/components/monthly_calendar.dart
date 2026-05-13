import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyCalendar extends StatefulWidget {
  final DateTime? initialDate;

  const MonthlyCalendar({super.key, this.initialDate});

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    currentDate = DateTime(date.year, date.month, 1);
  }

  void previousMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    });
  }

  List<DateTime> getDaysInMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    List<DateTime> days = [];

    // Add empty days before the month starts
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(date.year, date.month, 1 - i).subtract(Duration(days: i)));
    }

    // Add all days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(date.year, date.month, i));
    }

    // Add empty days after the month ends
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(date.year, date.month + 1, i));
    }

    return days;
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isCurrentMonth(DateTime date) {
    return date.month == currentDate.month && date.year == currentDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final days = getDaysInMonth(currentDate);
    final monthName =
        ['January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December'][currentDate.month - 1];
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: previousMonth,
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF2563EB)),
                ),
                Text(
                  '$monthName ${currentDate.year}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kSecondColor,
                  ),
                ),
                IconButton(
                  onPressed: nextMonth,
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Weekday headers
            Row(
              children: weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kTextStyleColorGray,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final inCurrentMonth = isCurrentMonth(day);
                final isCurrentDay = isToday(day);

                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCurrentDay
                        ? AppColor.kPrimaryColor
                        : inCurrentMonth
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: inCurrentMonth
                          ? () {
                              Navigator.pop(context, day);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isCurrentDay
                                ? Colors.white
                                : inCurrentMonth
                                    ? AppColor.kSecondColor
                                    : AppColor.kTextStyleColorGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kbgColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kSecondColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
