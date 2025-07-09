import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';

class Helpee10ProfilePage extends StatefulWidget {
  const Helpee10ProfilePage({super.key});

  @override
  State<Helpee10ProfilePage> createState() => _Helpee10ProfilePageState();
}

class _Helpee10ProfilePageState extends State<Helpee10ProfilePage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Profile'.tr(),
            showBackButton: false,
            showMenuButton: true,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: () => context.go('/helpee/profile/edit'),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF8FD89F),
                  size: 18,
                ),
              ),
            ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _userDataService.getCurrentUserProfile(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      final userProfile = userSnapshot.data;
                      if (userProfile == null) {
                        return _buildErrorState();
                      }

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _userDataService
                            .getUserStatistics(userProfile['user_id']),
                        builder: (context, statsSnapshot) {
                          final stats = statsSnapshot.data ??
                              {
                                'total_jobs': 0,
                                'rating': 0.0,
                                'total_reviews': 0,
                                'member_since': 'Dec 2024',
                              };

                          return Column(
                            children: [
                              // Profile Header
                              _buildProfileHeader(userProfile, stats),

                              const SizedBox(height: 20),

                              // Personal Information
                              _buildPersonalInformation(userProfile),

                              const SizedBox(height: 16),

                              // Emergency Contact
                              _buildEmergencyContact(userProfile),

                              const SizedBox(height: 16),

                              // Preferences
                              _buildPreferences(userProfile),

                              const SizedBox(height: 20),

                              // Action Buttons
                              _buildActionButtons(),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.profile,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      Map<String, dynamic> userProfile, Map<String, dynamic> stats) {
    final firstName = userProfile['first_name'] ?? '';
    final lastName = userProfile['last_name'] ?? '';
    final displayName = userProfile['display_name'] ?? '$firstName $lastName';
    final memberSince = stats['member_since'] ?? 'Dec 2024';

    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName.isNotEmpty ? displayName : 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Helpee since $memberSince',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Jobs', '${stats['total_jobs']}'),
              _buildStatItem('Rating', '${stats['rating'].toStringAsFixed(1)}'),
              _buildStatItem('Reviews', '${stats['total_reviews']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Personal Information',
      items: [
        _buildInfoItem('Email', userProfile['email'] ?? 'Not provided'),
        _buildInfoItem('Phone', userProfile['phone'] ?? 'Not provided'),
        _buildInfoItem(
            'Address', userProfile['location_address'] ?? 'Not provided'),
        _buildInfoItem(
            'Date of Birth', _formatDateOfBirth(userProfile['date_of_birth'])),
      ],
    );
  }

  Widget _buildEmergencyContact(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Emergency Contact',
      items: [
        _buildInfoItem(
            'Name', userProfile['emergency_contact_name'] ?? 'Not provided'),
        _buildInfoItem(
            'Phone', userProfile['emergency_contact_phone'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildPreferences(Map<String, dynamic> userProfile) {
    return _buildInfoSection(
      title: 'Preferences',
      items: [
        _buildInfoItem(
            'Language', userProfile['preferred_language'] ?? 'English'),
        _buildInfoItem('Currency', userProfile['preferred_currency'] ?? 'LKR'),
        _buildInfoItem(
            'Notifications',
            userProfile['notifications_enabled'] == true
                ? 'Enabled'
                : 'Disabled'),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/helpee/profile/edit'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateOfBirth(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'Not provided';

    try {
      DateTime date;
      if (dateOfBirth is String) {
        date = DateTime.parse(dateOfBirth);
      } else if (dateOfBirth is DateTime) {
        date = dateOfBirth;
      } else {
        return 'Not provided';
      }

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final day = date.day;
      final suffix = _getDaySuffix(day);
      return '${day}${suffix} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Not provided';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (context.mounted) {
                  context.go('/user-selection');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
