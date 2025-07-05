import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

enum UserType { helpee, helper }

enum NavigationTab { home, calendar, activity, profile, search, requests }

class AppNavigationBar extends StatelessWidget {
  final NavigationTab currentTab;
  final UserType userType;

  const AppNavigationBar({
    super.key,
    required this.currentTab,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      child: Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Color(0xFF90D99F),
          borderRadius: BorderRadius.all(Radius.circular(45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              context: context,
              tab: NavigationTab.home,
              icon: Icons.home,
              label: 'Home',
            ),
            _buildNavButton(
              context: context,
              tab: NavigationTab.calendar,
              icon: Icons.calendar_today,
              label: 'Calendar',
            ),
            _buildNavButton(
              context: context,
              tab: NavigationTab.activity,
              icon: Icons.work_history,
              label: 'Activity',
            ),
            _buildNavButton(
              context: context,
              tab: NavigationTab.profile,
              icon: Icons.person,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required NavigationTab tab,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = currentTab == tab;

    return GestureDetector(
      onTap: () => _navigateToTab(context, tab),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF90D99F),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF90D99F) : Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF90D99F) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, NavigationTab tab) {
    String route;

    switch (userType) {
      case UserType.helpee:
        switch (tab) {
          case NavigationTab.home:
            route = '/helpee/home';
            break;
          case NavigationTab.calendar:
            route = '/helpee/calendar';
            break;
          case NavigationTab.activity:
            route = '/helpee/activity/pending';
            break;
          case NavigationTab.profile:
            route = '/helpee/profile';
            break;
          case NavigationTab.search:
            route = '/helpee/search-helper';
            break;
          case NavigationTab.requests:
            route = '/helpee/home'; // Default for helpees
            break;
        }
        break;
      case UserType.helper:
        switch (tab) {
          case NavigationTab.home:
            route = '/helper/home';
            break;
          case NavigationTab.calendar:
            route = '/helper/calendar';
            break;
          case NavigationTab.activity:
            route = '/helper/activity/pending';
            break;
          case NavigationTab.profile:
            route = '/helper/profile';
            break;
          case NavigationTab.search:
            route = '/helper/home'; // Default for helpers
            break;
          case NavigationTab.requests:
            route = '/helper/view-requests/private';
            break;
        }
        break;
    }

    if (currentTab != tab) {
      context.go(route);
    }
  }
}
