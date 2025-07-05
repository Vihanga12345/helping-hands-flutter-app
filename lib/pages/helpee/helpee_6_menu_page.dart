import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/custom_auth_service.dart';

class Helpee6MenuPage extends StatefulWidget {
  const Helpee6MenuPage({super.key});

  @override
  State<Helpee6MenuPage> createState() => _Helpee6MenuPageState();
}

class _Helpee6MenuPageState extends State<Helpee6MenuPage> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  final CustomAuthService _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Menu',
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),

          // Body Content
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
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 8,
                              offset: Offset(0, 4),
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
                                      : 'User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Helpee Account',
                                  style: TextStyle(
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
                              title: 'Notifications',
                              onTap: () => context.go('/helpee/notifications'),
                            ),
                            _buildDarkModeMenuItem(),
                            _buildLanguageMenuItem(),
                            _buildMenuItem(
                              icon: Icons.help,
                              title: 'Help & Support',
                              onTap: () => context.go('/helpee/help-support'),
                            ),
                            _buildMenuItem(
                              icon: Icons.payment,
                              title: 'Payments',
                              onTap: () => context.go('/helpee/payments'),
                            ),
                            _buildMenuItem(
                              icon: Icons.info,
                              title: 'About Us',
                              onTap: () => context.go('/helpee/about-us'),
                            ),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Logout',
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
          Icons.visibility,
          color: AppColors.primaryGreen,
        ),
        title: const Text(
          'Dark Mode',
          style: TextStyle(
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
        title: const Text(
          'Language',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: DropdownButton<String>(
          value: _selectedLanguage,
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue!;
            });
          },
          items: const [
            DropdownMenuItem<String>(
              value: 'English',
              child: Text('English'),
            ),
            DropdownMenuItem<String>(
              value: 'Sinhala',
              child: Text('Sinhala'),
            ),
            DropdownMenuItem<String>(
              value: 'Tamil',
              child: Text('Tamil'),
            ),
          ],
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
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/user-selection');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
