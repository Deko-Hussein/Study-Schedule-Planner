import 'package:flutter/material.dart';
import '../../utils/exports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ScheduleTask> tasks = [
    ScheduleTask(
      title: 'Flutter UI Practice',
      subtitle: 'Complete the study planner screen',
      time: '04:00 PM',
      category: 'Study',
      tagColor: AppColor.kPrimaryColor, id: '',
    ),
    ScheduleTask(
      title: 'Math Assignment',
      subtitle: 'Finish chapter 5 problems',
      time: '06:00 PM',
      category: 'Assignment',
      tagColor: AppColor.kCheckOutActiveTextColor, id: '',
    ),
    ScheduleTask(
      title: 'Exam Review',
      subtitle: 'Practice past papers',
      time: '07:30 PM',
      category: 'Exam',
      tagColor: AppColor.kCheckInActiveTextColor, id: '',
    ),
  ];

  final List<String> categories = ['All', 'Study', 'Assignment', 'Exam', 'Reading'];
  int selectedFilter = 0;
  int selectedCategory = 0;

  List<ScheduleTask> get filteredTasks {
    return tasks.where((task) {
      final matchesCategory =
          selectedCategory == 0 || task.category == categories[selectedCategory];
      final matchesFilter = selectedFilter == 0 ||
          (selectedFilter == 1 ? !task.completed : task.completed);
      return matchesCategory && matchesFilter;
    }).toList();
  }

  void _toggleTask(ScheduleTask task) {
    setState(() {
      task.completed = !task.completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(),
              const SizedBox(height: 24),
              const MonthCard(),
              const SizedBox(height: 18),
              const WeekTimeline(),
              const SizedBox(height: 24),
              ScheduleHeader(
                selected: selectedFilter,
                onChanged: (index) => setState(() => selectedFilter = index),
              ),
              const SizedBox(height: 18),
              CategoryChips(
                selected: selectedCategory,
                onChanged: (index) => setState(() => selectedCategory = index),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upcoming Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kSecondColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks match this filter.',
                          style: TextStyle(
                            color: AppColor.kTextStyleColorGray,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return TaskCard(
                            task: filteredTasks[index],
                            onTap: () => _toggleTask(filteredTasks[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
