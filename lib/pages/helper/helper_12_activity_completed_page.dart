import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import 'helper_10_activity_pending_page.dart';

class Helper12ActivityCompletedPage extends StatefulWidget {
  const Helper12ActivityCompletedPage({super.key});

  @override
  State<Helper12ActivityCompletedPage> createState() =>
      _Helper12ActivityCompletedPageState();
}

class _Helper12ActivityCompletedPageState
    extends State<Helper12ActivityCompletedPage> {
  @override
  void initState() {
    super.initState();
    // Redirect to main activity page with completed tab selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Helper10ActivityPendingPage(),
          settings: const RouteSettings(
              arguments: {'initialTab': 2}), // 2 = Completed tab
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
