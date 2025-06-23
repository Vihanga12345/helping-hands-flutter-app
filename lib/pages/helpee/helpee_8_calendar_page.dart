import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Event {
  final String title;
  final String status;
  final String helper;

  const Event({
    required this.title,
    required this.status,
    required this.helper,
  });

  @override
  String toString() => title;
}

class Helpee8CalendarPage extends StatefulWidget {
  const Helpee8CalendarPage({super.key});

  @override
  State<Helpee8CalendarPage> createState() => _Helpee8CalendarPageState();
}

class _Helpee8CalendarPageState extends State<Helpee8CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sample events data
  final Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();

    // Initialize sample events
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    _events[today] = [
      const Event(
          title: 'House Cleaning', status: 'CONFIRMED', helper: 'John Smith'),
      const Event(
          title: 'Gardening', status: 'PENDING', helper: 'Waiting for Helper'),
    ];

    _events[tomorrow] = [
      const Event(
          title: 'Cooking', status: 'CONFIRMED', helper: 'Maria Garcia'),
    ];
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Calendar',
            showMenuButton: true,
            showNotificationButton: true,
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Interactive Calendar Widget
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TableCalendar<Event>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        eventLoader: _getEventsForDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 3,
                          markerDecoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          formatButtonDecoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Selected Day's Schedule Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDay != null
                                ? "${_getEventsForDay(_selectedDay!).isNotEmpty ? 'Jobs for ' : 'No jobs for '}${_formatDate(_selectedDay!)}"
                                : "Today's Schedule",
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Show jobs for selected day
                          if (_selectedDay != null &&
                              _getEventsForDay(_selectedDay!).isNotEmpty)
                            ..._getEventsForDay(_selectedDay!)
                                .map((event) => _buildJobCardFromEvent(
                                      context: context,
                                      event: event,
                                    ))
                                .toList()
                          else if (_selectedDay != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No jobs scheduled for this day',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.calendar,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required BuildContext context,
    required String title,
    required String pay,
    required String date,
    required String time,
    required String location,
    required String status,
    required String helper,
    required String jobType,
  }) {
    Color statusColor = status == 'CONFIRMED'
        ? AppColors.success
        : status == 'PENDING'
            ? AppColors.warning
            : AppColors.textSecondary;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to appropriate job detail page based on job status
            if (status == 'PENDING') {
              context.push('/helpee/job-detail/pending');
            } else if (status == 'CONFIRMED' || status == 'ONGOING') {
              context.push('/helpee/job-detail/ongoing');
            } else if (status == 'COMPLETED') {
              context.push('/helpee/job-detail/completed');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pay rate (top right in green pill)
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pay,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Helper Profile Bar (Clickable)
                GestureDetector(
                  onTap: () {
                    if (helper != 'Waiting for Helper') {
                      context.push('/helpee/helper-profile');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: helper == 'Waiting for Helper'
                              ? AppColors.textSecondary
                              : AppColors.primaryGreen,
                          child: Text(
                            helper == 'Waiting for Helper' ? '?' : helper[0],
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            helper,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (helper != 'Waiting for Helper')
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons - Inside the tile (NO View Job Details button)
                if (jobType == 'confirmed') ...[
                  // Message and Track buttons for confirmed jobs
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Opening chat with helper...')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side:
                                const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Message',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.primaryGreen,
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
                              const SnackBar(
                                  content: Text('Tracking job progress...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Track Job',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Edit and Cancel buttons for pending jobs
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/helpee/job-edit');
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
                            'Edit',
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
                              const SnackBar(
                                  content: Text('Job request cancelled')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Cancel',
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
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildJobCardFromEvent({
    required BuildContext context,
    required Event event,
  }) {
    return _buildJobCard(
      context: context,
      title: event.title,
      pay: '1500/Hr',
      date: 'Dec 24, 2024',
      time: '10:00 AM',
      location: 'Colombo 03',
      status: event.status,
      helper: event.helper,
      jobType: event.status == 'CONFIRMED' ? 'confirmed' : 'pending',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
