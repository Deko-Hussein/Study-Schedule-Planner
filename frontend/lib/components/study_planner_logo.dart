import 'package:flutter/material.dart';

import '../utils/color.dart';

class StudyPlannerLogoBadge extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const StudyPlannerLogoBadge({
    super.key,
    required this.size,
    required this.backgroundColor,
    required this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkBackground =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final paperColor =
        isDarkBackground ? Colors.white : const Color(0xFFF8FAFC);
    final topBarColor =
        isDarkBackground ? const Color(0xFFDBEAFE) : AppColor.kPrimaryColor;
    final ringColor = isDarkBackground ? paperColor : AppColor.kPrimaryColor;
    final lineColor = isDarkBackground
        ? const Color(0xFF93C5FD)
        : AppColor.kPrimaryColor.withValues(alpha: 0.18);
    final checkBackground =
        isDarkBackground ? const Color(0xFF1D4ED8) : AppColor.kPrimaryColor;
    final glyphSize = size * 0.58;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: SizedBox.square(
        dimension: glyphSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: glyphSize * 0.08,
              right: glyphSize * 0.08,
              top: glyphSize * 0.12,
              bottom: glyphSize * 0.04,
              child: Container(
                decoration: BoxDecoration(
                  color: paperColor,
                  borderRadius: BorderRadius.circular(glyphSize * 0.18),
                ),
              ),
            ),
            Positioned(
              left: glyphSize * 0.20,
              top: 0,
              child: _binderRing(glyphSize, ringColor),
            ),
            Positioned(
              right: glyphSize * 0.20,
              top: 0,
              child: _binderRing(glyphSize, ringColor),
            ),
            Positioned(
              left: glyphSize * 0.18,
              right: glyphSize * 0.18,
              top: glyphSize * 0.20,
              child: Container(
                height: glyphSize * 0.16,
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(glyphSize * 0.10),
                ),
              ),
            ),
            Positioned(
              left: glyphSize * 0.22,
              right: glyphSize * 0.32,
              top: glyphSize * 0.44,
              child: Column(
                children: [
                  _plannerLine(glyphSize, lineColor),
                  SizedBox(height: glyphSize * 0.08),
                  _plannerLine(glyphSize, lineColor),
                  SizedBox(height: glyphSize * 0.08),
                  _plannerLine(glyphSize, lineColor),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: glyphSize * 0.34,
                height: glyphSize * 0.34,
                decoration: BoxDecoration(
                  color: checkBackground,
                  borderRadius: BorderRadius.circular(glyphSize * 0.12),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: glyphSize * 0.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _binderRing(double glyphSize, Color color) {
    return Container(
      width: glyphSize * 0.10,
      height: glyphSize * 0.16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(glyphSize * 0.08),
      ),
    );
  }

  Widget _plannerLine(double glyphSize, Color color) {
    return Container(
      height: glyphSize * 0.06,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(glyphSize * 0.04),
      ),
    );
  }
}
