// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:iconly/iconly.dart';
// import '../utils/color.dart';
// import 'history/history_screen.dart';
// import 'profile/profile_screen.dart';
// import 'tasks/new_task_screen.dart';

// class AppIconly {
//   AppIconly._();

//   static const IconData calendar = IconlyLight.calendar;
//   static const IconData calendarBold = IconlyBold.calendar;
//   static const IconData plus = IconlyLight.plus;
//   static const IconData plusBold = IconlyBold.plus;
//   static const IconData history = IconlyLight.tick_square;
//   static const IconData historyBold = IconlyBold.tick_square;
//   static const IconData profile = IconlyLight.profile;
//   static const IconData profileBold = IconlyBold.profile;
// }

// class MainShell extends StatefulWidget {
//   const MainShell({super.key});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _index = 2;

//   final List<Widget> _pages = const [
//     _PlaceholderTab(title: 'Planner', icon: AppIconly.calendar),
//     NewTaskScreen(),
//     HistoryScreen(),
//     ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.kbgColor,
//       body: _pages[_index],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.06),
//               blurRadius: 16,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           top: false,
//           child: SizedBox(
//             height: 60,
//             child: Row(
//               children: [
//                 _NavItem(
//                   icon: AppIconly.calendar,
//                   activeIcon: AppIconly.calendarBold,
//                   label: 'Planner',
//                   active: _index == 0,
//                   onTap: () => setState(() => _index = 0),
//                 ),
//                 _NavItem(
//                   icon: AppIconly.plus,
//                   activeIcon: AppIconly.plusBold,
//                   label: 'Add',
//                   active: _index == 1,
//                   onTap: () => setState(() => _index = 1),
//                 ),
//                 _NavItem(
//                   icon: AppIconly.history,
//                   activeIcon: AppIconly.historyBold,
//                   label: 'History',
//                   active: _index == 2,
//                   onTap: () => setState(() => _index = 2),
//                 ),
//                 _NavItem(
//                   icon: AppIconly.profile,
//                   activeIcon: AppIconly.profileBold,
//                   label: 'Profile',
//                   active: _index == 3,
//                   onTap: () => setState(() => _index = 3),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _PlaceholderTab extends StatelessWidget {
//   final String title;
//   final IconData icon;

//   const _PlaceholderTab({required this.title, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 34, color: AppColor.kTextStyleColorGray),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               style: GoogleFonts.inter(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: AppColor.kTextStyleColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   final bool active;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//     required this.active,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = active ? AppColor.kPrimaryColor : AppColor.kTextStyleColorGray;
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(active ? activeIcon : icon, size: 22, color: color),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 fontSize: 10,
//                 fontWeight: active ? FontWeight.w600 : FontWeight.w400,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../utils/color.dart';
import 'hom/home_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/add_task_screen.dart';

class AppIconly {
  AppIconly._();

  static const IconData calendar = IconlyLight.calendar;
  static const IconData calendarBold = IconlyBold.calendar;

  static const IconData plus = IconlyLight.plus;
  static const IconData plusBold = IconlyBold.plus;

  static const IconData history = IconlyLight.tick_square;
  static const IconData historyBold = IconlyBold.tick_square;

  static const IconData profile = IconlyLight.profile;
  static const IconData profileBold = IconlyBold.profile;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final ValueNotifier<int> _taskRefreshNotifier = ValueNotifier<int>(0);

  void _notifyTaskRefresh() {
    _taskRefreshNotifier.value++;
  }

  void _handleTaskSaved() {
    _notifyTaskRefresh();
    setState(() => _index = 0);
  }

  @override
  void dispose() {
    _taskRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        refreshListenable: _taskRefreshNotifier,
        onTaskChanged: _notifyTaskRefresh,
      ),
      AddTaskScreen(
        onTaskSaved: _handleTaskSaved,
      ),
      HistoryScreen(
        refreshListenable: _taskRefreshNotifier,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: AppIconly.calendar,
                  activeIcon: AppIconly.calendarBold,
                  label: 'Planner',
                  active: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: AppIconly.plus,
                  activeIcon: AppIconly.plusBold,
                  label: 'Add',
                  active: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: AppIconly.history,
                  activeIcon: AppIconly.historyBold,
                  label: 'History',
                  active: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: AppIconly.profile,
                  activeIcon: AppIconly.profileBold,
                  label: 'Profile',
                  active: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColor.kPrimaryColor : AppColor.kTextStyleColorGray;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
