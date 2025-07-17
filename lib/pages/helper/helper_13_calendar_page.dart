import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/common/job_action_buttons.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../widgets/common/realtime_app_wrapper.dart';
import 'dart:async';

class Event {
  final String title;
  final String status;
  final String helpee;
  final String jobId;
  final String time;
  final String pay;
  final String location;

  const Event({
    required this.title,
    required this.status,
    required this.helpee,
    required this.jobId,
    required this.time,
    required this.pay,
    required this.location,
  });

  @override
  String toString() => title;
}

class Helper13CalendarPage extends StatefulWidget {
  const Helper13CalendarPage({super.key});

  @override
  State<Helper13CalendarPage> createState() => _Helper13CalendarPageState();
}

class _Helper13CalendarPageState extends State<Helper13CalendarPage>
    with RealTimePageMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();

  // Dynamic events data from database
  Map<DateTime, List<Event>> _events = {};
  bool _isLoading = true;
  String? _error;

  // Real-time subscription
  StreamSubscription? _calendarSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeRealTimeCalendar();
  }

  void _initializeRealTimeCalendar() {
    // Listen to real-time calendar data updates
    _calendarSubscription =
        liveDataService.calendarStream.listen((calendarJobs) {
      if (mounted) {
        _processCalendarData(calendarJobs);
      }
    });

    // Initial calendar data load
    _loadCalendarEvents();
  }

  void _processCalendarData(List<Map<String, dynamic>> calendarJobs) {
    try {
      // Convert jobs to Event objects grouped by date
      Map<DateTime, List<Event>> events = {};

      for (var job in calendarJobs) {
        final scheduledDate = job['scheduled_date'];
        if (scheduledDate != null) {
          final date = DateTime.parse(scheduledDate);
          final normalizedDate = DateTime(date.year, date.month, date.day);

          // Extract and format the required fields
          final timeStr = _extractTimeFromJob(job);
          final payStr = _extractPayFromJob(job);
          final locationStr = _extractLocationFromJob(job);
          final helpeeStr = _extractHelpeeFromJob(job);

          final event = Event(
            title: job['title'] ?? 'Unknown Job',
            status: job['status'] ?? 'PENDING',
            helpee: helpeeStr,
            jobId: job['id'] ?? '',
            time: timeStr,
            pay: payStr,
            location: locationStr,
          );

          if (events[normalizedDate] == null) {
            events[normalizedDate] = [];
          }
          events[normalizedDate]!.add(event);
        }
      }

      setState(() {
        _events = events;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to process calendar data: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to extract and format time from job data
  String _extractTimeFromJob(Map<String, dynamic> job) {
    // Try multiple possible field names for time
    String? timeValue =
        job['time'] ?? job['scheduled_start_time'] ?? job['scheduled_time'];

    print(
        '🕐 Extracting time from job ${job['id']}: time=${job['time']}, scheduled_start_time=${job['scheduled_start_time']}');

    if (timeValue != null && timeValue != 'Time TBD') {
      print('✅ Using existing time value: $timeValue');
      return timeValue;
    }

    // Try to format from raw time data
    try {
      if (job['scheduled_start_time'] != null) {
        final dateTime = DateTime.parse(job['scheduled_start_time']);
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final formattedTime = '$hour:$minute';
        print('✅ Formatted time from scheduled_start_time: $formattedTime');
        return formattedTime;
      }
    } catch (e) {
      print('❌ Error formatting time: $e');
    }

    print('⚠️ Using fallback time: Time not set');
    return 'Time not set';
  }

  // Helper method to extract and format pay from job data
  String _extractPayFromJob(Map<String, dynamic> job) {
    print(
        '💰 Extracting pay from job ${job['id']}: pay=${job['pay']}, hourly_rate=${job['hourly_rate']}');

    // Try multiple possible field names for pay
    if (job['pay'] != null && job['pay'] != 'Rate not set') {
      print('✅ Using existing pay value: ${job['pay']}');
      return job['pay'];
    }

    // Try to format from hourly_rate
    if (job['hourly_rate'] != null) {
      final formattedPay = 'LKR ${job['hourly_rate']}/Hr';
      print('✅ Formatted pay from hourly_rate: $formattedPay');
      return formattedPay;
    }

    print('⚠️ Using fallback pay: Rate not set');
    return 'Rate not set';
  }

  // Helper method to extract location from job data
  String _extractLocationFromJob(Map<String, dynamic> job) {
    final location =
        job['location'] ?? job['location_address'] ?? 'Location not set';

    print(
        '📍 Extracting location from job ${job['id']}: location=${job['location']}, location_address=${job['location_address']} -> $location');
    return location;
  }

  // Helper method to extract helpee name from job data
  String _extractHelpeeFromJob(Map<String, dynamic> job) {
    // Try multiple possible field names for helpee name
    String? helpeeName;

    // First try the users object
    if (job['users'] != null && job['users']['display_name'] != null) {
      helpeeName = job['users']['display_name'];
    }
    // Then try first and last name separately
    else if (job['helpee_first_name'] != null ||
        job['helpee_last_name'] != null) {
      final firstName = job['helpee_first_name'] ?? '';
      final lastName = job['helpee_last_name'] ?? '';
      helpeeName = '$firstName $lastName'.trim();
    }

    if (helpeeName == null || helpeeName.isEmpty) {
      helpeeName = 'Unknown Client';
    }

    return helpeeName;
  }

  Future<void> _loadCalendarEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      // Use real-time service to refresh calendar data
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await liveDataService.refreshCalendar(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load calendar events: $e';
      });
    }
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    super.dispose();
  }

  // Method to get complete job data for action buttons
  Future<Map<String, dynamic>?> _getCompleteJobData(String jobId) async {
    if (jobId.isEmpty) return null;

    try {
      final jobDetails =
          await _jobDataService.getJobDetailsWithQuestions(jobId);
      return jobDetails;
    } catch (e) {
      print('❌ Error getting complete job data: $e');
      return null;
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Debug logging to see what's happening with date matching
    final normalizedDay = DateTime(day.year, day.month, day.day);
    print('🔍 Looking for events on: $normalizedDay');
    print('📅 Available event dates: ${_events.keys.toList()}');

    final events = _events[normalizedDay] ?? [];
    print('✅ Found ${events.length} events for this date');

    return events;
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
            onMenuPressed: () {
              context.push('/helper/menu');
            },
            onNotificationPressed: () {
              context.push('/helper/notifications');
            },
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _buildCalendarContent(),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.calendar,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              'Unable to load calendar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCalendarEvents,
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

  Widget _buildCalendarContent() {
    return SingleChildScrollView(
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
              onDaySelected: (selectedDay, focusedDay) async {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  // Debug: Log the selected date
                  print('📅 Selected date: $selectedDay');
                  print(
                      '📅 Normalized date: ${DateTime(selectedDay.year, selectedDay.month, selectedDay.day)}');

                  // Optionally refresh calendar data for the specific date
                  await _loadCalendarEvents();
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
                      .map((event) => _buildJobCardFromEvent(event))
                      .toList()
                else if (_selectedDay != null)
                  _buildNoJobsCard(),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJobCardFromEvent(Event event) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getJobDetailsForEvent(event),
      builder: (context, snapshot) {
        // Use Event data directly for basic display, even while loading full job details
        final basicJobData = {
          'title': event.title,
          'pay': event.pay,
          'date': _formatDate(_selectedDay!),
          'time': event.time,
          'location': event.location,
          'status': event.status,
          'id': event.jobId,
        };

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show basic card with Event data while loading additional details
          return _buildJobCard(
            context: context,
            title: event.title,
            pay: event.pay,
            date: _formatDate(_selectedDay!),
            time: event.time,
            location: event.location,
            status: event.status,
            helpee: event.helpee,
            jobType: _getJobTypeFromStatus(event.status),
            jobId: event.jobId,
            jobData: basicJobData,
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          // Use Event data if detailed fetch fails
          return _buildJobCard(
            context: context,
            title: event.title,
            pay: event.pay,
            date: _formatDate(_selectedDay!),
            time: event.time,
            location: event.location,
            status: event.status,
            helpee: event.helpee,
            jobType: _getJobTypeFromStatus(event.status),
            jobId: event.jobId,
            jobData: basicJobData,
          );
        }

        // Use detailed job data if available, but fallback to Event data for missing fields
        final jobDetails = snapshot.data!.first;
        return _buildJobCard(
          context: context,
          title: jobDetails['title'] ?? event.title,
          pay: jobDetails['pay'] ?? event.pay,
          date: jobDetails['date'] ?? _formatDate(_selectedDay!),
          time: jobDetails['time'] ?? event.time,
          location: jobDetails['location'] ?? event.location,
          status: event.status,
          helpee: event.helpee,
          jobType: _getJobTypeFromStatus(event.status),
          jobId: event.jobId,
          jobData: jobDetails,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getJobDetailsForEvent(Event event) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || event.jobId.isEmpty) return [];

    try {
      // Get all pending jobs (including both private assigned and public available)
      final pendingJobs =
          await _jobDataService.getHelperPendingJobs(currentUser['user_id']);

      // Get assigned jobs in other statuses
      final ongoingJobs = await _jobDataService.getJobsByHelperAndStatus(
          currentUser['user_id'], 'ongoing');
      final completedJobs = await _jobDataService.getJobsByHelperAndStatus(
          currentUser['user_id'], 'completed');
      final acceptedJobs = await _jobDataService.getJobsByHelperAndStatus(
          currentUser['user_id'], 'accepted');
      final startedJobs = await _jobDataService.getJobsByHelperAndStatus(
          currentUser['user_id'], 'started');

      final allJobsList = [
        ...pendingJobs,
        ...ongoingJobs,
        ...completedJobs,
        ...acceptedJobs,
        ...startedJobs
      ];
      final matchingJobs =
          allJobsList.where((job) => job['id'] == event.jobId).toList();

      return matchingJobs;
    } catch (e) {
      print('❌ Error getting job details for event: $e');
      return [];
    }
  }

  Widget _buildBasicJobCard(Event event) {
    return _buildJobCard(
      context: context,
      title: event.title,
      pay: 'Rate not available',
      date: _formatDate(_selectedDay!),
      time: 'Time not available',
      location: 'Location not available',
      status: event.status,
      helpee: event.helpee,
      jobType: _getJobTypeFromStatus(event.status),
      jobId: event.jobId,
      jobData: null,
    );
  }

  Widget _buildLoadingJobCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildNoJobsCard() {
    return Container(
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
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/helper/view-requests/public'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text(
              'View Job Requests',
              style: TextStyle(color: AppColors.white),
            ),
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
    required String helpee,
    required String jobType,
    String? jobId,
    Map<String, dynamic>? jobData,
  }) {
    Color statusColor =
        status == 'CONFIRMED' || status == 'ACCEPTED' || status == 'STARTED'
            ? AppColors.success
            : status == 'PENDING'
                ? AppColors.warning
                : status == 'AVAILABLE'
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to comprehensive job detail page with job ID
            if (jobId != null && jobId!.isNotEmpty) {
              context.push('/helper/comprehensive-job-detail/$jobId');
            } else {
              // Show message if no job ID available
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Job details not available'),
                  backgroundColor: AppColors.warning,
                ),
              );
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
                _buildInfoPill(date),
                const SizedBox(height: 8),
                // Time Pill
                _buildInfoPill(time),
                const SizedBox(height: 8),
                // Location Pill
                _buildInfoPill(location),
                const SizedBox(height: 16),

                // Dynamic Action Buttons using JobActionButtons widget
                if (jobData != null) ...[
                  JobActionButtons(
                    job: jobData!,
                    userType: 'helper',
                    onJobUpdated: () {
                      _loadCalendarEvents(); // Reload calendar when job status changes
                    },
                    showTimer: ['started', 'paused']
                        .contains(jobData!['status']?.toLowerCase()),
                  ),
                ] else if (jobId != null && jobId!.isNotEmpty) ...[
                  // Load job data dynamically if not provided
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getCompleteJobData(jobId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        return JobActionButtons(
                          job: snapshot.data!,
                          userType: 'helper',
                          onJobUpdated: () {
                            _loadCalendarEvents(); // Reload calendar when job status changes
                          },
                          showTimer: [
                            'started',
                            'paused'
                          ].contains(snapshot.data!['status']?.toLowerCase()),
                        );
                      }

                      // Fallback for when no job data is available
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Job actions not available',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Fallback when no job ID is available
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Job details not available',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

  Widget _buildInfoPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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

  String _getJobTypeFromStatus(String status) {
    switch (status) {
      case 'PENDING':
        return 'pending';
      case 'CONFIRMED':
      case 'STARTED':
        return 'confirmed';
      case 'COMPLETED':
        return 'completed';
      default:
        return 'pending';
    }
  }
}
