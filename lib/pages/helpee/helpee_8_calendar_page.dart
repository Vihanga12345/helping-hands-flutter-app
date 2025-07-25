import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/common/realtime_app_wrapper.dart';
import 'dart:async';
import '../../widgets/ui_elements/functional_job_card.dart';

class Event {
  final String title;
  final String status;
  final String helper;
  final String jobId;
  final Map<String, dynamic>? jobData; // Add original job data

  const Event({
    required this.title,
    required this.status,
    required this.helper,
    required this.jobId,
    this.jobData, // Make it optional for backward compatibility
  });

  @override
  String toString() => title;
}

class Helpee8CalendarPage extends StatefulWidget {
  const Helpee8CalendarPage({super.key});

  @override
  State<Helpee8CalendarPage> createState() => _Helpee8CalendarPageState();
}

class _Helpee8CalendarPageState extends State<Helpee8CalendarPage>
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
      print(
          '🔄 Helpee Calendar: Received ${calendarJobs.length} jobs from stream');

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

          final event = Event(
            title: job['title'] ?? 'Unknown Job'.tr(),
            status: job['status'] ?? 'PENDING',
            helper: job['users']?['display_name'] ?? 'Waiting for Helper'.tr(),
            jobId: job['id'] ?? '',
            jobData: job, // Store the original job data
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
        _error = 'Failed to process calendar data: $e'.tr();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    super.dispose();
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
          _error = 'User not logged in'.tr();
        });
        return;
      }

      print('🔄 Helpee Calendar: Loading events...');

      // Ensure the live data service is initialized
      if (!liveDataService.isInitialized) {
        print('⚠️ LiveDataService not initialized, initializing now...');
        await liveDataService.initialize();
      }

      // Use real-time service to refresh calendar data
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await liveDataService.refreshCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      print('✅ Helpee Calendar: Events loaded successfully');
    } catch (e) {
      print('❌ Error loading helpee calendar events: $e');

      // Fallback: Load calendar data directly
      print('🔄 Fallback: Loading helpee calendar data directly...');
      await _loadCalendarDataDirectly();
    }
  }

  // Fallback method to load calendar data directly if live service fails
  Future<void> _loadCalendarDataDirectly() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in'.tr();
        });
        return;
      }

      final helpeeId = currentUser['user_id'];
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      print('🔄 Loading helpee calendar data directly for: $helpeeId');

      // Load all job statuses for the current month
      final allJobs = <Map<String, dynamic>>[];

      // Get jobs with different statuses
      final pendingJobs =
          await _jobDataService.getJobsByUserAndStatus(helpeeId, 'pending');
      final ongoingJobs =
          await _jobDataService.getJobsByUserAndStatus(helpeeId, 'ongoing');
      final completedJobs =
          await _jobDataService.getJobsByUserAndStatus(helpeeId, 'completed');

      allJobs.addAll(pendingJobs);
      allJobs.addAll(ongoingJobs);
      allJobs.addAll(completedJobs);

      // Filter jobs by date range and convert to Events
      final filteredEvents = <DateTime, List<Event>>{};

      for (var job in allJobs) {
        final scheduledDate = job['scheduled_date'];
        if (scheduledDate != null) {
          final date = DateTime.parse(scheduledDate);
          final normalizedDate = DateTime(date.year, date.month, date.day);

          // Check if date is within our range
          if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)))) {
            // Create Event object from job data
            final event = Event(
              title: job['title'] ?? 'Unknown Job'.tr(),
              status: job['status'] ?? 'PENDING',
              helper: job['helper_name'] ?? 'Waiting for Helper'.tr(),
              jobId: job['id'] ?? '',
              jobData: job, // Store the original job data
            );

            if (filteredEvents[normalizedDate] == null) {
              filteredEvents[normalizedDate] = [];
            }
            filteredEvents[normalizedDate]!.add(event);
          }
        }
      }

      print(
          '✅ Direct helpee calendar data load completed: ${filteredEvents.length} days with events');

      setState(() {
        _events = filteredEvents;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('❌ Error in direct helpee calendar data loading: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load calendar data: $e'.tr();
      });
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Calendar'.tr(),
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
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _buildCalendarContent(),
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
            Text(
              'Unable to load calendar'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error'.tr(),
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
              child: Text(
                'Retry'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    return SafeArea(
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
                onDaySelected: _onDaySelected,
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
                        ? "${_getEventsForDay(_selectedDay!).isNotEmpty ? '${'Jobs for'.tr()} ' : '${'No jobs for'.tr()} '}${_formatDate(_selectedDay!)}"
                        : "Today's Schedule".tr(),
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

            const SizedBox(height: 100), // Add bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardFromEvent(Event event) {
    // Use the stored job data directly if available
    if (event.jobData != null) {
      print('🔍 Calendar: Using stored job data for ${event.title}');
      final formattedJobData = _formatJobDataForCard(event.jobData!, event);

      return FunctionalJobCard(
        jobData: formattedJobData,
        userType: 'helpee',
        onStatusChanged: () {
          // Refresh calendar when job status changes
          _loadCalendarEvents();
        },
      );
    }

    // Fallback to fetching job details (for backward compatibility)
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getJobDetailsForEvent(event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingJobCard();
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildBasicJobCard(event);
        }

        final jobDetails = snapshot.data!.first;

        // Format the job data to match FunctionalJobCard expectations
        final formattedJobData = _formatJobDataForCard(jobDetails, event);

        return FunctionalJobCard(
          jobData: formattedJobData,
          userType: 'helpee',
          onStatusChanged: () {
            // Refresh calendar when job status changes
            _loadCalendarEvents();
          },
        );
      },
    );
  }

  Map<String, dynamic> _formatJobDataForCard(
      Map<String, dynamic> jobDetails, Event event) {
    // Debug: Print ALL available fields to see what data we have
    print('🔍 Calendar: Raw job details for ${event.title}:');
    print('   ALL FIELDS: ${jobDetails.keys.toList()}');
    jobDetails.forEach((key, value) {
      print('   $key: $value');
    });

    // Extract time - prioritize pre-formatted field from live data service
    String formattedTime = 'Time TBD';

    // First check for pre-formatted time field (from live data service _transformJobData)
    if (jobDetails['time'] != null && jobDetails['time'] != 'Time TBD') {
      formattedTime = jobDetails['time'];
      print('🔍 Calendar: Using pre-formatted time field: $formattedTime');
    }
    // Then try scheduled_start_time (raw field)
    else if (jobDetails['scheduled_start_time'] != null) {
      formattedTime = _formatTime(jobDetails['scheduled_start_time']);
      print('🔍 Calendar: Using scheduled_start_time: $formattedTime');
    }
    // Fallback to scheduled_time field
    else if (jobDetails['scheduled_time'] != null) {
      formattedTime = jobDetails['scheduled_time'];
      print('🔍 Calendar: Using scheduled_time: $formattedTime');
    }
    // Last resort: try to extract from scheduled_date
    else if (jobDetails['scheduled_date'] != null) {
      try {
        final scheduledDateTime = DateTime.parse(jobDetails['scheduled_date']);
        final hour = scheduledDateTime.hour;
        final minute = scheduledDateTime.minute;

        print(
            '🔍 Calendar: Parsed from scheduled_date - hour: $hour, minute: $minute');

        // Only format if there's actual time data (not just 00:00)
        if (hour != 0 || minute != 0) {
          // Format as 12-hour time
          String period = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          String formattedMinute = minute.toString().padLeft(2, '0');

          formattedTime = '$displayHour:$formattedMinute $period';
          print(
              '🔍 Calendar: Formatted time from scheduled_date: $formattedTime');
        } else {
          print('🔍 Calendar: Time is 00:00 in scheduled_date, keeping as TBD');
        }
      } catch (e) {
        print('❌ Calendar: Error formatting time from scheduled_date: $e');
      }
    }

    // Debug pay formatting
    print('🔍 Calendar: Pay fields available:');
    print('   pay: ${jobDetails['pay']}');
    print('   hourly_rate: ${jobDetails['hourly_rate']}');
    print('   rate: ${jobDetails['rate']}');

    // Format the date
    String formattedDate = _formatDate(_selectedDay!);
    if (jobDetails['scheduled_date'] != null) {
      try {
        final scheduledDateTime = DateTime.parse(jobDetails['scheduled_date']);
        formattedDate = _formatDate(scheduledDateTime);
      } catch (e) {
        formattedDate = _formatDate(_selectedDay!);
      }
    }

    final result = {
      'id': event.jobId,
      'title': jobDetails['title'] ?? event.title,
      'pay': _formatPay(jobDetails),
      'date': formattedDate,
      'time': formattedTime,
      'location': jobDetails['location_address'] ??
          jobDetails['location'] ??
          'Location TBD',
      'status': event.status.toLowerCase(),
      'helper': event.helper,
      'is_private': jobDetails['is_private'] ?? false,
      'job_category_id': jobDetails['job_category_id'],
      'hourly_rate': jobDetails['hourly_rate'],
      'scheduled_date': jobDetails['scheduled_date'],
      'scheduled_start_time': jobDetails['scheduled_start_time'],
      'created_at': jobDetails['created_at'],
      'helpee_id': jobDetails['helpee_id'],
      'assigned_helper_id': jobDetails['assigned_helper_id'],
    };

    print('🔍 Calendar: Final formatted data:');
    print('   title: ${result['title']}');
    print('   pay: ${result['pay']}');
    print('   time: ${result['time']}');
    print('   date: ${result['date']}');

    return result;
  }

  // Add the same time formatting method used by job data service
  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Time TBD';
    try {
      final time = DateTime.parse(timeStr);
      final hour = time.hour;
      final minute = time.minute;

      // Format as 12-hour time with AM/PM
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String formattedMinute = minute.toString().padLeft(2, '0');

      return '$displayHour:$formattedMinute $period';
    } catch (e) {
      print('❌ Calendar: Error in _formatTime: $e');
      return 'Time TBD';
    }
  }

  String _formatPay(Map<String, dynamic> jobDetails) {
    // First check for pre-formatted pay field (from live data service _transformJobData)
    if (jobDetails['pay'] != null && jobDetails['pay'] != 'Rate not set') {
      print('🔍 Calendar: Using pre-formatted pay field: ${jobDetails['pay']}');
      return jobDetails['pay'];
    }

    // Then try different field names for pay/rate information
    if (jobDetails['hourly_rate'] != null) {
      final formattedPay = 'LKR ${jobDetails['hourly_rate']}/hr';
      print('🔍 Calendar: Formatted from hourly_rate: $formattedPay');
      return formattedPay;
    }
    if (jobDetails['rate'] != null) {
      print('🔍 Calendar: Using rate field: ${jobDetails['rate']}');
      return 'LKR ${jobDetails['rate']}/hr';
    }

    print('❌ Calendar: No pay data found in available fields');
    return 'Rate not set';
  }

  Future<List<Map<String, dynamic>>> _getJobDetailsForEvent(Event event) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || event.jobId.isEmpty) return [];

    try {
      // This is a simplified approach - in a real app, you'd have a specific method
      // to get job details by ID. For now, we'll get all jobs and filter.
      final allJobs = await _jobDataService.getJobsByUserAndStatus(
          currentUser['user_id'], 'pending');
      final acceptedJobs = await _jobDataService.getJobsByUserAndStatus(
          currentUser['user_id'], 'accepted');
      final startedJobs = await _jobDataService.getJobsByUserAndStatus(
          currentUser['user_id'], 'started');
      final completedJobs = await _jobDataService.getJobsByUserAndStatus(
          currentUser['user_id'], 'completed');

      final allJobsList = [
        ...allJobs,
        ...acceptedJobs,
        ...startedJobs,
        ...completedJobs
      ];
      return allJobsList.where((job) => job['id'] == event.jobId).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildBasicJobCard(Event event) {
    // Use FunctionalJobCard for basic events too
    final basicJobData = {
      'id': event.jobId,
      'title': event.title,
      'pay': 'Rate not available',
      'date': _formatDate(_selectedDay!),
      'time': 'Time TBD',
      'location': 'Location TBD',
      'status': event.status.toLowerCase(),
      'helper': event.helper,
      'is_private': false,
    };

    return FunctionalJobCard(
      jobData: basicJobData,
      userType: 'helpee',
      onStatusChanged: () {
        _loadCalendarEvents();
      },
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
            'No jobs scheduled for this day'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/helpee/job-request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: Text(
              'Create Job Request'.tr(),
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January'.tr(),
      'February'.tr(),
      'March'.tr(),
      'April'.tr(),
      'May'.tr(),
      'June'.tr(),
      'July'.tr(),
      'August'.tr(),
      'September'.tr(),
      'October'.tr(),
      'November'.tr(),
      'December'.tr()
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
      case 'ACCEPTED':
      case 'STARTED':
        return 'confirmed';
      case 'COMPLETED':
        return 'completed';
      default:
        return 'pending';
    }
  }
}
