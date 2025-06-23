import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper13CalendarPage extends StatefulWidget {
  const Helper13CalendarPage({super.key});

  @override
  State<Helper13CalendarPage> createState() => _Helper13CalendarPageState();
}

class _Helper13CalendarPageState extends State<Helper13CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'My Calendar',
            showMenuButton: true,
            showNotificationButton: true,
            rightWidget: IconButton(
              icon: const Icon(Icons.today, color: AppColors.white),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
              },
            ),
            onMenuPressed: () {
              context.push('/helper/menu');
            },
            onNotificationPressed: () {
              context.push('/helper/notification');
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
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Calendar Header
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(
                                          _selectedDate.year,
                                          _selectedDate.month - 1);
                                    });
                                  },
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text(
                                  '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(
                                          _selectedDate.year,
                                          _selectedDate.month + 1);
                                    });
                                  },
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Week days
                            Row(
                              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                  .map((day) => Expanded(
                                        child: Center(
                                          child: Text(
                                            day,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),

                            const SizedBox(height: 8),

                            // Calendar grid (simplified)
                            Container(
                              height: 200,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                ),
                                itemCount: 35,
                                itemBuilder: (context, index) {
                                  final day = index - 6;
                                  final isCurrentMonth = day > 0 && day <= 31;
                                  final isToday = isCurrentMonth &&
                                      day == DateTime.now().day;

                                  return Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? AppColors.primaryGreen
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isCurrentMonth
                                        ? Center(
                                            child: Text(
                                              day.toString(),
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: isToday
                                                    ? AppColors.white
                                                    : AppColors.textPrimary,
                                                fontWeight: isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Today's Schedule
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
                              'Today\'s Schedule',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Job Cards
                            _buildJobTile(
                              title: 'House Deep Cleaning',
                              hourlyRate: '2,500 / Hr',
                              date: 'Today',
                              time: '9:00 AM - 12:00 PM',
                              location: 'Colombo 07',
                              status: 'ONGOING',
                              statusColor: AppColors.success,
                              onTap: () {
                                context.push('/helper/job-ongoing');
                              },
                            ),

                            _buildJobTile(
                              title: 'Office Maintenance',
                              hourlyRate: '4,000 / Hr',
                              date: 'Today',
                              time: '2:00 PM - 5:00 PM',
                              location: 'Bambalapitiya',
                              status: 'PENDING',
                              statusColor: AppColors.warning,
                              onTap: () {
                                context.push('/helper/job-pending-request');
                              },
                            ),

                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Available slot - can accept new jobs')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.lightGrey,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Available',
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '6:00 PM - 8:00 PM',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Open slot',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
          AppNavigationBar(
            currentTab: NavigationTab.calendar,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }

  Widget _buildJobTile({
    required String title,
    required String hourlyRate,
    required String date,
    required String time,
    required String location,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Header with Job Type and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Hourly Rate Pill (top right)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hourlyRate,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date Pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                date,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                time,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                location,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons - Inside the tile based on job status
            if (status == 'ONGOING') ...[
              // Action buttons for ongoing jobs
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job Paused')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Pause',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job Completed')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Complete',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'PENDING') ...[
              // Accept/Reject buttons for pending jobs
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rejected $title')),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accepted $title')),
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
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
