// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../models/schedule_task.dart';

// class TaskCard extends StatelessWidget {
//   final ScheduleTask task;
//   final VoidCallback onTap;

//   const TaskCard({
//     super.key,
//     required this.task,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(task.title,
//                     style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
//                 Text(task.subtitle),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: onTap,
//             child: Icon(
//               task.completed ? Icons.check_circle : Icons.circle_outlined,
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/schedule_task.dart';

class TaskCard extends StatelessWidget {
  final ScheduleTask task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: task.completed ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: task.tagColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    task.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.tagColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: task.completed
                          ? AppColor.kSecondColor.withOpacity(0.65)
                          : AppColor.kSecondColor,
                      decoration: task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.kTextStyleColorGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColor.kPrimaryColor : AppColor.kbgColor2,
                  border: Border.all(
                    color: task.completed ? AppColor.kPrimaryColor : AppColor.borderSecondary,
                  ),
                ),
                child: Center(
                  child: task.completed
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Icon(Icons.circle_outlined, color: AppColor.kTextStyleColorGray, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}