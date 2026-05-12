import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/exports.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const StudyPlannerApp(),
    ),
  );
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Schedule Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.kPrimaryColor,
        ),
        scaffoldBackgroundColor: AppColor.kbgColor,
      ),
      home: const SplashScreen(),
    );
  }
}