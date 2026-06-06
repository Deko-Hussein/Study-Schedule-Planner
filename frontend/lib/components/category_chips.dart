import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Study',
      'Assignment',
      'Exam',
      'Reading',
      'Personal',
      'Other',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isActive = selected == index;

          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              margin: EdgeInsets.only(
                right: index == categories.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColor.kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? AppColor.kPrimaryColor
                      : AppColor.borderSecondary,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColor.kPrimaryColor.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                categories[index],
                style: GoogleFonts.inter(
                  fontSize: 12,
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
    );
  }
}
