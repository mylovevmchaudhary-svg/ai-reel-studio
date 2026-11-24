import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../dashboard/screens/home_dashboard_screen.dart';
import '../projects/screens/my_projects_screen.dart';
import '../projects/screens/project_history_screen.dart';
import '../settings/screens/settings_storage_screen.dart';
import '../projects/screens/create_new_project_screen.dart';

class AppBottomNav extends StatefulWidget {
  final int initialIndex;

  const AppBottomNav({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    MyProjectsScreen(),
    ProjectHistoryScreen(),
    SettingsStorageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()),
          );
        },
        backgroundColor: AppColors.accentPink,
        elevation: 4,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.primaryDark,
          indicatorColor: AppColors.accentPurple.withOpacity(0.25),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11);
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: AppColors.accentPurple, size: 24);
            }
            return IconThemeData(color: Colors.white.withOpacity(0.5), size: 22);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library_rounded),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_toggle_off_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Exports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
