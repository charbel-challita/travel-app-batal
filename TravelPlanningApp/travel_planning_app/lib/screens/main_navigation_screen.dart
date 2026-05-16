import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'ai_planner_screen.dart';
import 'trips_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String selectedMode = 'Casual';

  List<Widget> get _screens => [
    HomeScreen(
      selectedMode: selectedMode,
      onModeChanged: (mode) {
        setState(() {
          selectedMode = mode;
        });
      },
      onOpenAiPlanner: () {
        setState(() {
          _currentIndex = 2;
        });
      },
    ),
    ExploreScreen(
      selectedMode: selectedMode,
    ),
    AiPlannerScreen(
      selectedMode: selectedMode,
    ),
    TripsScreen(
      selectedMode: selectedMode,
    ),
    ProfileScreen(
      selectedMode: selectedMode,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLuxury = selectedMode == 'Luxury';
    final isNight = selectedMode == 'Night';
    final isDarkMode = isLuxury || isNight;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: isDarkMode ? const Color(0xFF050818) : Colors.white,
        selectedItemColor: isLuxury
            ? const Color(0xFFE8C766)
            : isNight
                ? const Color(0xFFA855F7)
                : const Color(0xFF2563EB),
        unselectedItemColor:
            isDarkMode ? const Color(0xFFB8B8D1) : const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 34),
            label: 'AI Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
