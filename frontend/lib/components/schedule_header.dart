import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleHeader extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const ScheduleHeader({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Pending', 'Completed'];

    return Row(
      children: [
        Expanded(
          child: Text(
            'My Schedule',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
        ),
        Row(
          children: List.generate(filters.length, (index) {
            final isActive = selected == index;

            return GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColor.kPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? AppColor.kPrimaryColor
                        : AppColor.borderSecondary,
                  ),
                ),
                child: Text(
                  filters[index],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : AppColor.kTextStyleColorGray,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}