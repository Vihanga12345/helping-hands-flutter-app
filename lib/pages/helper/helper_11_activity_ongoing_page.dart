import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import 'helper_10_activity_pending_page.dart';

class Helper11ActivityOngoingPage extends StatefulWidget {
  const Helper11ActivityOngoingPage({super.key});

  @override
  State<Helper11ActivityOngoingPage> createState() =>
      _Helper11ActivityOngoingPageState();
}

class _Helper11ActivityOngoingPageState
    extends State<Helper11ActivityOngoingPage> {
  @override
  void initState() {
    super.initState();
    // Redirect to main activity page with ongoing tab selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HelperActivityPendingPage(),
          settings: const RouteSettings(
              arguments: {'initialTab': 1}), // 1 = Ongoing tab
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while redirecting
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Activities',
            showMenuButton: true,
            showNotificationButton: true,
            onMenuPressed: () {
              context.push('/helper/menu');
            },
            onNotificationPressed: () {
              context.push('/helper/notifications');
            },
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.50, 0.00),
                  end: Alignment(0.50, 1.00),
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.activity,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }
}
