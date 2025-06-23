import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class HelperEarningsPage extends StatefulWidget {
  const HelperEarningsPage({super.key});

  @override
  State<HelperEarningsPage> createState() => _HelperEarningsPageState();
}

class _HelperEarningsPageState extends State<HelperEarningsPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Year'
  ];

  // Mock earnings data
  final Map<String, dynamic> _earningsData = {
    'This Week': {
      'total': 45000.0,
      'jobs': 8,
      'hours': 32,
      'average': 5625.0,
      'dailyEarnings': [6000, 8000, 7500, 6500, 9000, 4000, 4000],
      'jobTypes': {
        'House Cleaning': 25000,
        'Deep Cleaning': 12000,
        'Organizing': 8000,
      }
    },
    'This Month': {
      'total': 185000.0,
      'jobs': 32,
      'hours': 128,
      'average': 5781.25,
      'dailyEarnings': [
        8000,
        12000,
        15000,
        18000,
        22000,
        25000,
        28000,
        26000,
        24000,
        20000,
        18000,
        16000,
        14000,
        12000,
        10000
      ],
      'jobTypes': {
        'House Cleaning': 95000,
        'Deep Cleaning': 48000,
        'Organizing': 25000,
        'Kitchen Cleaning': 17000,
      }
    },
    'Last Month': {
      'total': 178000.0,
      'jobs': 29,
      'hours': 116,
      'average': 6137.93,
      'dailyEarnings': [
        7000,
        11000,
        14000,
        17000,
        21000,
        24000,
        27000,
        25000,
        23000,
        19000,
        17000,
        15000,
        13000,
        11000,
        9000
      ],
      'jobTypes': {
        'House Cleaning': 89000,
        'Deep Cleaning': 45000,
        'Organizing': 24000,
        'Kitchen Cleaning': 20000,
      }
    },
    'This Year': {
      'total': 2200000.0,
      'jobs': 384,
      'hours': 1536,
      'average': 5729.17,
      'dailyEarnings': [], // Would be monthly data for year view
      'jobTypes': {
        'House Cleaning': 1100000,
        'Deep Cleaning': 580000,
        'Organizing': 320000,
        'Kitchen Cleaning': 200000,
      }
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentData = _earningsData[_selectedPeriod]!;

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
              const AppHeader(
                title: 'Earnings',
                showBackButton: true,
                showMenuButton: false,
                showNotificationButton: false,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Filter
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                            const Text(
                              'Time Period',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _periods.map((period) {
                                  final isSelected = period == _selectedPeriod;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(period),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedPeriod = period;
                                        });
                                      },
                                      backgroundColor:
                                          AppColors.lightGreen.withOpacity(0.1),
                                      selectedColor: AppColors.primaryGreen,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Summary Cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildSummaryCard(
                            'Total Earnings',
                            'LKR ${_formatCurrency(currentData['total'])}',
                            Icons.account_balance_wallet,
                            AppColors.primaryGreen,
                          ),
                          _buildSummaryCard(
                            'Jobs Completed',
                            '${currentData['jobs']}',
                            Icons.work_outline,
                            AppColors.warning,
                          ),
                          _buildSummaryCard(
                            'Hours Worked',
                            '${currentData['hours']}h',
                            Icons.access_time,
                            AppColors.info,
                          ),
                          _buildSummaryCard(
                            'Average per Job',
                            'LKR ${_formatCurrency(currentData['average'])}',
                            Icons.trending_up,
                            AppColors.success,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Earnings Chart
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
                              'Earnings Trend',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildEarningsChart(currentData['dailyEarnings']),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job Types Breakdown
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
                              'Earnings by Job Type',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...currentData['jobTypes'].entries.map((entry) {
                              final percentage =
                                  (entry.value / currentData['total'] * 100)
                                      .round();
                              return _buildJobTypeItem(
                                entry.key,
                                entry.value.toDouble(),
                                percentage,
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recent Transactions
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
                              'Recent Transactions',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTransactionItem(
                                'House Cleaning', 'Completed', 2500.0, 'Today'),
                            _buildTransactionItem('Deep Cleaning', 'Completed',
                                4000.0, 'Yesterday'),
                            _buildTransactionItem('Organizing', 'Completed',
                                1800.0, '2 days ago'),
                            _buildTransactionItem('Kitchen Cleaning', 'Pending',
                                1200.0, '3 days ago'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.home,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(List<int> data) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart,
                size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Chart data for yearly view\nwill be implemented here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final height = (value / maxValue) * 180;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.8),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJobTypeItem(String jobType, double amount, int percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jobType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${_formatCurrency(amount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.lightGreen.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      String title, String status, double amount, String date) {
    final isCompleted = status == 'Completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCompleted ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.schedule,
              color: isCompleted ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$status • $date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'LKR ${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCompleted ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
