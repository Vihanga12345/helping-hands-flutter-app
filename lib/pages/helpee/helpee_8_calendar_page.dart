import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';

class Event {
  final String title;
  final String status;
  final String helper;
  final String jobId;

  const Event({
    required this.title,
    required this.status,
    required this.helper,
    required this.jobId,
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
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();

  // Dynamic events data from database
  Map<DateTime, List<Event>> _events = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadCalendarEvents();
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

      final calendarData =
          await _jobDataService.getJobsForCalendar(currentUser['user_id']);

      // Convert to Event objects
      Map<DateTime, List<Event>> events = {};
      calendarData.forEach((date, jobList) {
        events[date] = jobList
            .map((job) => Event(
                  title: job['title'] ?? 'Unknown Job'.tr(),
                  status: job['status'] ?? 'PENDING',
                  helper: job['helper'] ?? 'Waiting for Helper'.tr(),
                  jobId: job['job_id'] ?? '',
                ))
            .toList();
      });

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load calendar events: $e'.tr();
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
        return _buildJobCard(
          context: context,
          title: jobDetails['title'] ?? event.title,
          pay: jobDetails['pay'] ?? 'Rate not set',
          date: jobDetails['date'] ?? _formatDate(_selectedDay!),
          time: jobDetails['time'] ?? 'Time not set',
          location: jobDetails['location'] ?? 'Location not set',
          status: event.status,
          helper: event.helper,
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
    return _buildJobCard(
      context: context,
      title: event.title,
      pay: 'Rate not available'.tr(),
      date: _formatDate(_selectedDay!),
      time: 'Time not available'.tr(),
      location: 'Location not available'.tr(),
      status: event.status,
      helper: event.helper,
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
    String? jobId,
    Map<String, dynamic>? jobData,
  }) {
    Color statusColor = status == 'CONFIRMED' || status == 'ACCEPTED'
        ? AppColors.success
        : status == 'PENDING'
            ? AppColors.warning
            : status == 'STARTED'
                ? AppColors.primaryGreen
                : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to appropriate job detail page based on job status - SAME AS FUNCTIONAL_JOB_CARD
          String route;
          switch (status.toLowerCase()) {
            case 'pending':
              route = '/helpee/job-detail/pending';
              break;
            case 'accepted':
            case 'started':
            case 'paused':
            case 'confirmed':
            case 'ongoing':
              route = '/helpee/job-detail/ongoing';
              break;
            case 'completed':
              route = '/helpee/job-detail/completed';
              break;
            default:
              route = '/helpee/job-detail/pending';
          }

          context.push(route, extra: {
            'jobId': jobId ?? '',
            'jobData': jobData ??
                {
                  'id': jobId ?? '',
                  'title': title,
                  'pay': pay,
                  'date': date,
                  'time': time,
                  'location': location,
                  'status': status,
                  'helper': helper,
                },
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Job details section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Helper info
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      helper,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pay rate - moved to bottom and made more prominent
            Row(
              children: [
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    pay,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
