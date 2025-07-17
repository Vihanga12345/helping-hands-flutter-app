import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../common/report_page.dart';

class Helpee6MenuPage extends StatefulWidget {
  const Helpee6MenuPage({super.key});

  @override
  State<Helpee6MenuPage> createState() => _Helpee6MenuPageState();
}

class _Helpee6MenuPageState extends State<Helpee6MenuPage> {
  bool _isDarkMode = false;
  final _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Menu',
            showMenuButton: false,
          ),

          // Content
          Expanded(
            child: Container(
              color: AppColors.backgroundLight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryGreen,
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _authService.currentUser != null
                                    ? '${_authService.currentUser!['first_name'] ?? ''} ${_authService.currentUser!['last_name'] ?? ''}'
                                        .trim()
                                    : 'User'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Helpee Account'.tr(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu Items
                    Expanded(
                      child: ListView(
                        children: [
                          _buildMenuItem(
                            icon: Icons.notifications,
                            title: 'Notifications'.tr(),
                            onTap: () => context.go('/helpee/notifications'),
                          ),
                          _buildDarkModeMenuItem(),
                          _buildLanguageMenuItem(),
                          _buildMenuItem(
                            icon: Icons.help,
                            title: 'Help & Support'.tr(),
                            onTap: () => context.go('/helpee/help-support'),
                          ),
                          _buildMenuItem(
                            icon: Icons.payment,
                            title: 'Payments'.tr(),
                            onTap: () => context.go('/helpee/payments'),
                          ),
                          _buildMenuItem(
                            icon: Icons.info,
                            title: 'About Us'.tr(),
                            onTap: () => context.go('/helpee/about-us'),
                          ),
                          _buildMenuItem(
                            icon: Icons.report_problem,
                            title: 'Report Issue'.tr(),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReportPage(userType: 'helpee'),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Logout'.tr(),
                            onTap: () {
                              _showLogoutDialog(context);
                            },
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primaryGreen,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppColors.white,
      ),
    );
  }

  Widget _buildDarkModeMenuItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.dark_mode,
          color: AppColors.primaryGreen,
        ),
        title: Text(
          'Dark Mode'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
          },
          activeColor: AppColors.primaryGreen,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppColors.white,
      ),
    );
  }

  Widget _buildLanguageMenuItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.language,
          color: AppColors.primaryGreen,
        ),
        title: Text(
          'Language'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: DropdownButton<String>(
          value: LocalizationService().currentLanguage,
          underline: Container(),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primaryGreen,
          ),
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: 'si',
              child: Text('සිංහල'),
            ),
            DropdownMenuItem(
              value: 'ta',
              child: Text('தமிழ්'),
            ),
          ],
          onChanged: (String? newLanguage) {
            if (newLanguage != null) {
              LocalizationService().changeLanguage(newLanguage);
              setState(() {}); // Refresh the menu page immediately
            }
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppColors.white,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'.tr()),
          content: Text('Are you sure you want to logout?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: Text(
                'Logout'.tr(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
