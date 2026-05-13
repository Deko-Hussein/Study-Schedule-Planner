import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/color.dart';

class ScheduleTask {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String category;
  final Color tagColor;
  final DateTime? dueDate;
  final DateTime? completedAt;
  bool completed;

  ScheduleTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.category,
    required this.tagColor,
    this.dueDate,
    this.completedAt,
    this.completed = false,
  });

  factory ScheduleTask.fromApi(Map<String, dynamic> json) {
    final dueDate = _parseDate(json['dueDate']);
    final completedAt = _parseDate(json['completedAt']);
    final category = _resolveCategory(json);

    return ScheduleTask(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled task',
      subtitle: _resolveSubtitle(json['description']),
      time: dueDate == null ? 'No time' : DateFormat('hh:mm a').format(dueDate.toLocal()),
      category: category,
      tagColor: _categoryColor(category),
      dueDate: dueDate,
      completedAt: completedAt,
      completed: json['completed'] == true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _resolveSubtitle(dynamic description) {
    final text = description?.toString().trim() ?? '';
    return text.isEmpty ? 'No description added.' : text;
  }

  static String _resolveCategory(Map<String, dynamic> json) {
    final rawCategory = json['category']?.toString().trim();
    if (rawCategory != null && rawCategory.isNotEmpty) return rawCategory;

    final subject = json['subject'];
    if (subject is Map<String, dynamic>) {
      final subjectName = subject['name']?.toString().trim();
      if (subjectName != null && subjectName.isNotEmpty) return subjectName;
    }

    switch (json['priority']) {
      case 'high':
        return 'Exam';
      case 'low':
        return 'Reading';
      default:
        return 'Study';
    }
  }

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'study':
        return AppColor.kPrimaryColor;
      case 'assignment':
        return AppColor.kCheckOutActiveTextColor;
      case 'exam':
        return AppColor.kCheckInActiveTextColor;
      case 'reading':
        return Colors.orange;
      case 'personal':
        return Colors.teal;
      default:
        return AppColor.kTextStyleColorGray;
    }
  }
}
