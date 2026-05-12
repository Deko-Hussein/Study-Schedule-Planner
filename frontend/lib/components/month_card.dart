import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'monthly_calendar.dart';

class MonthCard extends StatefulWidget {
  const MonthCard({super.key});

  @override
  State<MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<MonthCard> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  String getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  String getMonthName(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  void _showMonthlyCalendar() {
    showDialog(
      context: context,
      builder: (context) => MonthlyCalendar(initialDate: selectedDate),
    ).then((selectedDay) {
      if (selectedDay != null && selectedDay is DateTime) {
        setState(() {
          selectedDate = selectedDay;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthName = getMonthName(selectedDate);
    final dayName = getDayName(selectedDate);

    return GestureDetector(
      onTap: _showMonthlyCalendar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$monthName ${selectedDate.year}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColor.kSecondColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selectedDate.day} $dayName',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.kTextStyleColorGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.kbgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }
}