import 'package:flutter/material.dart';
import '../../utils/color.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: Center(
        child: Text(
          'Add Task Screen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.kSecondColor,
          ),
        ),
      ),
    );
  }
}