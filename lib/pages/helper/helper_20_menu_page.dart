import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/language_switcher.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../common/report_page.dart';

class Helper20MenuPage extends StatefulWidget {
  const Helper20MenuPage({super.key});

  @override
  State<Helper20MenuPage> createState() => _Helper20MenuPageState();
}

class _Helper20MenuPageState extends State<Helper20MenuPage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStatistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }

      final results = await Future.wait([
        _userDataService.getCurrentUserProfile(),
        _userDataService.getHelperStatistics(currentUser['user_id']),
      ]);

      setState(() {
        _userProfile = results[0] as Map<String, dynamic>?;
        _userStatistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });

      print('✅ Menu profile data loaded successfully');
    } catch (e) {
      print('❌ Error loading menu profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                title: 'Menu'.tr(),
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
                        child: _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: ClipOval(
                                      child:
                                          _userProfile?['profile_image_url'] !=
                                                  null
                                              ? Image.network(
                                                  _userProfile![
                                                      'profile_image_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                    Icons.person,
                                                    size: 30,
                                                    color:
                                                        AppColors.primaryGreen,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: AppColors.primaryGreen,
                                                ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_userProfile?['first_name'] ?? ''} ${_userProfile?['last_name'] ?? ''}'
                                              .trim(),
                                          style:
                                              AppTextStyles.heading3.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${'Verified Helper'.tr()} • ${(_userStatistics?['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      context.push('/helper/profile/edit');
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Menu Items
                      _buildMenuSection(
                        context,
                        'Analytics'.tr(),
                        [
                          _MenuItem('Earnings'.tr(), Icons.analytics,
                              () => context.push('/helper/earnings')),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Settings Section with Language Switcher
                      Container(
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
                                'Settings'.tr(),
                                style: TextStyle().copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const LanguageSwitcher(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildMenuSection(
                        context,
                        'Support & Information'.tr(),
                        [
                          _MenuItem('Help & Support'.tr(), Icons.help_outline,
                              () => context.push('/helper/help-support')),
                          _MenuItem(
                              'Report Issue'.tr(),
                              Icons.report_problem,
                              () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReportPage(userType: 'helper'),
                                    ),
                                  )),
                          _MenuItem('About Us'.tr(), Icons.info_outline,
                              () => context.push('/helper/about-us')),
                          _MenuItem('Terms & Conditions'.tr(), Icons.article,
                              () => context.push('/helper/terms-conditions')),
                          _MenuItem('Privacy Policy'.tr(), Icons.privacy_tip,
                              () => context.push('/helper/privacy-policy')),
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
                            'Logout'.tr(),
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

                      const SizedBox(height: 32),

                      // Footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.shadowColorLight.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'by your friend and neighbour',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vihanga',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
      SnackBar(content: Text('Opening $title'.tr())),
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged out successfully'.tr())),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text('Logout'.tr()),
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
