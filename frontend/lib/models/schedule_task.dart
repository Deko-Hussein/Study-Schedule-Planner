import 'package:flutter/material.dart';

class ScheduleTask {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String category;
  final Color tagColor;
  bool completed;

  ScheduleTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.category,
    required this.tagColor,
    this.completed = false,
  });
}