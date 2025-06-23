import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper8ViewRequestsPrivatePage extends StatefulWidget {
  const Helper8ViewRequestsPrivatePage({super.key});

  @override
  State<Helper8ViewRequestsPrivatePage> createState() =>
      _Helper8ViewRequestsPrivatePageState();
}

class _Helper8ViewRequestsPrivatePageState
    extends State<Helper8ViewRequestsPrivatePage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Urgent', 'High Pay', 'Nearby'];

  final List<Map<String, dynamic>> _privateRequests = [
    {
      'id': 'PR001',
      'title': 'House Cleaning - Luxury Villa',
      'location': 'Colombo 07, 0.8 km away',
      'pay': 'LKR 5,000',
      'duration': '6 hours',
      'date': 'Dec 25, 2024',
      'time': '9:00 AM',
      'description': 'Deep cleaning of 5-bedroom villa with pool area',
      'helpeeRating': 4.9,
      'isUrgent': true,
    },
    {
      'id': 'PR002',
      'title': 'Kitchen Deep Clean',
      'location': 'Dehiwala, 1.2 km away',
      'pay': 'LKR 3,500',
      'duration': '4 hours',
      'date': 'Dec 26, 2024',
      'time': '2:00 PM',
      'description': 'Post-party kitchen cleaning, grease removal',
      'helpeeRating': 4.7,
      'isUrgent': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Private Requests',
              showBackButton: true,
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
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Private requests sent directly to you',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Requests List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _privateRequests.length,
                        itemBuilder: (context, index) {
                          final request = _privateRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppNavigationBar(
              currentTab: NavigationTab.home,
              userType: UserType.helper,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Column(
      children: [
        // Job Tile - Clickable
        GestureDetector(
          onTap: () {
            // Navigate to job detail page
            context.push('/helper/job-detail');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: request['isUrgent']
                  ? Border.all(color: AppColors.error, width: 2)
                  : null,
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
                // Header with Job Type and Hourly Rate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request['title'],
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request['pay'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Pill
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    request['date'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Time Pill
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    request['time'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Location Pill
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    request['location'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Status Badge (if needed)
                if (request['isUrgent']) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons - Inside the tile
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Accepted ${request['id']}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Accept',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rejected ${request['id']}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
