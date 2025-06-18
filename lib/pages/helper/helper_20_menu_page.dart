import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper20MenuPage extends StatelessWidget {
  const Helper20MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Menu',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Smith',
                                    style: TextStyle(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified Helper • 4.8 ⭐',
                                    style: TextStyle().copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Opening profile')),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Menu Items
                      _buildMenuSection(
                        context,
                        'Work & Earnings',
                        [
                          _MenuItem('My Jobs', Icons.work,
                              () => _handleMenuTap(context, 'My Jobs')),
                          _MenuItem('Earnings', Icons.account_balance_wallet,
                              () => _handleMenuTap(context, 'Earnings')),
                          _MenuItem('Calendar', Icons.calendar_today,
                              () => _handleMenuTap(context, 'Calendar')),
                          _MenuItem('Job History', Icons.history,
                              () => _handleMenuTap(context, 'Job History')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildMenuSection(
                        context,
                        'Profile & Settings',
                        [
                          _MenuItem('Edit Profile', Icons.person_outline,
                              () => _handleMenuTap(context, 'Edit Profile')),
                          _MenuItem('Resume & Skills', Icons.description,
                              () => _handleMenuTap(context, 'Resume & Skills')),
                          _MenuItem('Verification', Icons.verified_user,
                              () => _handleMenuTap(context, 'Verification')),
                          _MenuItem('Preferences', Icons.settings,
                              () => _handleMenuTap(context, 'Preferences')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildMenuSection(
                        context,
                        'Support & Information',
                        [
                          _MenuItem('Help & Support', Icons.help_outline,
                              () => _handleMenuTap(context, 'Help & Support')),
                          _MenuItem('About Us', Icons.info_outline,
                              () => _handleMenuTap(context, 'About Us')),
                          _MenuItem(
                              'Terms & Conditions',
                              Icons.article,
                              () => _handleMenuTap(
                                  context, 'Terms & Conditions')),
                          _MenuItem('Privacy Policy', Icons.privacy_tip,
                              () => _handleMenuTap(context, 'Privacy Policy')),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon:
                              const Icon(Icons.logout, color: AppColors.error),
                          label: Text(
                            'Logout',
                            style: TextStyle().copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              AppNavigationBar(
                currentTab: NavigationTab.home,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<_MenuItem> items) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: TextStyle().copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: AppColors.textSecondary),
                  title: Text(item.title, style: TextStyle()),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: item.onTap,
                ),
                if (index < items.length - 1)
                  const Divider(height: 1, indent: 72),
              ],
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $title')),
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem(this.title, this.icon, this.onTap);
}
