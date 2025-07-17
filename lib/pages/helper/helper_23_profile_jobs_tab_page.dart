import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper23ProfileJobsTabPage extends StatefulWidget {
  const Helper23ProfileJobsTabPage({super.key});

  @override
  State<Helper23ProfileJobsTabPage> createState() =>
      _Helper23ProfileJobsTabPageState();
}

class _Helper23ProfileJobsTabPageState
    extends State<Helper23ProfileJobsTabPage> {
  String _selectedFilter = 'All';

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
                title: 'My Jobs',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats Overview
                      Container(
                        width: double.infinity,
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
                          children: [
                            Text(
                              'Job Statistics',
                              style: TextStyle(),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('127', 'Total Jobs',
                                      AppColors.primaryGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                      '125', 'Completed', AppColors.success),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                      '98%', 'Success Rate', AppColors.warning),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('LKR 127K',
                                      'Total Earned', AppColors.primaryGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard('4.8★',
                                      'Average Rating', AppColors.warning),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                      '2', 'Active Jobs', AppColors.info),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Filter Tabs
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildFilterTab('All')),
                            Expanded(child: _buildFilterTab('Active')),
                            Expanded(child: _buildFilterTab('Completed')),
                            Expanded(child: _buildFilterTab('Cancelled')),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Job List
                      Container(
                        width: double.infinity,
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
                            Row(
                              children: [
                                Text(
                                  'Recent Jobs',
                                  style: TextStyle(),
                                ),
                                const Spacer(),
                                Text(
                                  _selectedFilter,
                                  style: TextStyle().copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildJobCard(
                              'House Deep Cleaning',
                              'Sarah Johnson',
                              'Dec 25, 2024',
                              'LKR 5,000',
                              'Completed',
                              AppColors.success,
                              4.9,
                            ),
                            _buildJobCard(
                              'Office Maintenance',
                              'ABC Company Ltd',
                              'Dec 23, 2024',
                              'LKR 3,500',
                              'Completed',
                              AppColors.success,
                              4.7,
                            ),
                            _buildJobCard(
                              'Villa Cleaning',
                              'Mike Wilson',
                              'Dec 20, 2024',
                              'LKR 6,000',
                              'Ongoing',
                              AppColors.warning,
                              null,
                            ),
                            _buildJobCard(
                              'Apartment Cleaning',
                              'Lisa Chen',
                              'Dec 18, 2024',
                              'LKR 2,500',
                              'Completed',
                              AppColors.success,
                              5.0,
                            ),
                            _buildJobCard(
                              'Garden Maintenance',
                              'John Davis',
                              'Dec 15, 2024',
                              'LKR 4,000',
                              'Cancelled',
                              AppColors.error,
                              null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Performance Insights
                      Container(
                        width: double.infinity,
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
                              'Performance Insights',
                              style: TextStyle(),
                            ),
                            const SizedBox(height: 16),
                            _buildInsightCard(
                              Icons.trending_up,
                              'Great Performance!',
                              'Your completion rate is 98% - above average',
                              AppColors.success,
                            ),
                            const SizedBox(height: 12),
                            _buildInsightCard(
                              Icons.star,
                              'Excellent Ratings',
                              'Average rating of 4.8★ from 95 reviews',
                              AppColors.warning,
                            ),
                            const SizedBox(height: 12),
                            _buildInsightCard(
                              Icons.schedule,
                              'On-Time Delivery',
                              '92% of jobs completed on schedule',
                              AppColors.info,
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
                currentTab: NavigationTab.profile,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle().copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle().copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle().copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildJobCard(String title, String client, String date, String amount,
      String status, Color statusColor, double? rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle().copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                client,
                style: TextStyle().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: TextStyle().copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  '$rating',
                  style: TextStyle().copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'rating',
                  style: TextStyle().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Show center popup instead of bottom sheet
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 340,
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Jobs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter options
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFilterOption('All', 'All Jobs', Icons.list_alt),
                        const SizedBox(height: 12),
                        _buildFilterOption(
                            'Active', 'Active Jobs', Icons.play_circle_outline),
                        const SizedBox(height: 12),
                        _buildFilterOption('Completed', 'Completed Jobs',
                            Icons.check_circle_outline),
                        const SizedBox(height: 12),
                        _buildFilterOption('Cancelled', 'Cancelled Jobs',
                            Icons.cancel_outlined),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.green : Colors.black,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
