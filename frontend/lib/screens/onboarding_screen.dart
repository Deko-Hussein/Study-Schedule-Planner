import 'package:flutter/material.dart';
import '../utils/exports.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 100, color: AppColor.kPrimaryColor),
            const SizedBox(height: 30),
            const Text(
              'Plan Your Study Schedule',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColor.kSecondColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create tasks, track your study progress, and manage your exams easily.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.kTextStyleColorGray),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (_) => const LoginScreen()),
                // );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
