import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/color.dart';

class ScheduleHeader extends StatelessWidget {
  final int selected;
  final Function(int) onChanged;

  const ScheduleHeader({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['All', 'Pending', 'Completed'];

    return Row(
      children: List.generate(options.length, (index) {
        final isActive = index == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppColor.kPrimaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  options[index],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColor.kPrimaryColor : AppColor.kTextStyleColorGray,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
