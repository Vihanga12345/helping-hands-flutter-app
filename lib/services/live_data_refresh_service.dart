import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';
import 'realtime_notification_service.dart';

class LiveDataRefreshService {
  static final LiveDataRefreshService _instance =
      LiveDataRefreshService._internal();
  factory LiveDataRefreshService() => _instance;
  LiveDataRefreshService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();
  final RealTimeNotificationService _notificationService =
      RealTimeNotificationService();

  // Stream controllers for different data types
  final StreamController<List<Map<String, dynamic>>> _jobsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _activityController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _calendarController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _profileController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _statsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Cached data to minimize database calls
  Map<String, List<Map<String, dynamic>>> _cachedJobs = {};
  Map<String, List<Map<String, dynamic>>> _cachedActivity = {};
  Map<String, List<Map<String, dynamic>>> _cachedCalendar = {};
  Map<String, dynamic>? _cachedProfile;
  Map<String, dynamic>? _cachedStats;

  // Data change tracking to prevent unnecessary refreshes
  Map<String, String> _lastDataHashes = {};

  // Subscriptions to real-time updates
  StreamSubscription? _jobUpdateSubscription;
  StreamSubscription? _notificationSubscription;
  Timer?
      _autoRefreshTimer; // REDUCED to 10-second auto-refresh timer for fallback only

  bool _isInitialized = false;
  bool _autoRefreshEnabled = true; // Enable auto-refresh by default
  String? _currentUserId;
  bool _hasRecentChanges = false; // Track if there were recent changes

  // Streams for UI to listen to
  Stream<List<Map<String, dynamic>>> get jobsStream => _jobsController.stream;
  Stream<List<Map<String, dynamic>>> get activityStream =>
      _activityController.stream;
  Stream<List<Map<String, dynamic>>> get calendarStream =>
      _calendarController.stream;
  Stream<Map<String, dynamic>> get profileStream => _profileController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  /// Enable or disable auto-refresh (useful for performance optimization)
  void setAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    if (enabled) {
      _startAutoRefreshTimer();
    } else {
      _stopAutoRefreshTimer();
    }
    print('🔄 Auto-refresh ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Start the optimized auto-refresh timer (5 seconds, works globally)
  void _startAutoRefreshTimer() {
    _stopAutoRefreshTimer(); // Stop any existing timer

    if (!_autoRefreshEnabled) return;

    // Use 12-second interval with smart refresh logic
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 12), (timer) async {
      if (_currentUserId == null || !_isInitialized) return;

      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        final shouldRefresh = _hasRecentChanges || (now % 60000 < 15000);

        if (!shouldRefresh) {
          // Skip if no recent changes and not fallback window
          return;
        }

        print('🔄 Smart auto-refresh triggered (recent: $_hasRecentChanges)');

        try {
          await Future.wait([
            refreshJobs(),
            refreshActivity(),
            refreshCalendar(),
            refreshProfile(),
            refreshStats(),
          ]);

          _hasRecentChanges = false;
          print('✅ Smart auto-refresh completed');
        } catch (refreshError) {
          print('❌ Smart auto-refresh failed: $refreshError');
        }
      } catch (e) {
        print('❌ Global auto-refresh error: $e');
        // Keep the timer running for next attempt
      }
    });

    print('✅ Smart auto-refresh timer started (12-second interval)');
  }

  /// Stop the auto-refresh timer
  void _stopAutoRefreshTimer() {
    if (_autoRefreshTimer != null) {
      _autoRefreshTimer!.cancel();
      _autoRefreshTimer = null;
      print('🔄 Auto-refresh timer stopped');
    }
  }

  /// Initialize the live data refresh service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found - cannot initialize live data refresh');
        return;
      }

      _currentUserId = currentUser['user_id'];
      print(
          '🔄 Initializing Live Data Refresh Service for user: $_currentUserId');

      // Subscribe to real-time job updates
      _jobUpdateSubscription =
          _notificationService.jobUpdateStream.listen(_handleJobUpdate);

      // Subscribe to notifications for data refresh triggers
      _notificationSubscription = _notificationService.notificationStream
          .listen(_handleNotificationUpdate);

      // Load initial data
      await _loadInitialData();

      // Start auto-refresh timer
      _startAutoRefreshTimer();

      _isInitialized = true;
      print('✅ Live Data Refresh Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Live Data Refresh Service: $e');
    }
  }

  /// Load initial data from database
  Future<void> _loadInitialData() async {
    try {
      // Load all data types in parallel
      await Future.wait([
        refreshJobs(),
        refreshActivity(),
        refreshCalendar(),
        refreshProfile(),
        refreshStats(),
      ]);
    } catch (e) {
      print('❌ Error loading initial data: $e');
    }
  }

  /// Handle job updates from real-time service
  void _handleJobUpdate(Map<String, dynamic> jobData) {
    print('🔄 Handling job update for live refresh: ${jobData['id']}');

    // Mark that we have recent changes
    _hasRecentChanges = true;

    // Refresh relevant data streams immediately
    refreshJobs();
    refreshActivity();
    refreshCalendar();
    refreshStats();
  }

  /// Handle notification updates that might require data refresh
  void _handleNotificationUpdate(Map<String, dynamic> notification) {
    final notificationType = notification['notification_type'];

    // Mark that we have recent changes for any relevant notification
    _hasRecentChanges = true;

    switch (notificationType) {
      case 'job_accepted':
      case 'job_rejected':
      case 'job_started':
      case 'job_completed':
        refreshJobs();
        refreshActivity();
        refreshCalendar();
        break;
      case 'payment_received':
        refreshStats();
        break;
      case 'rating_received':
        refreshProfile();
        refreshStats();
        break;
    }
  }

  /// Transform job data from database format to UI format
  Map<String, dynamic> _transformJobData(Map<String, dynamic> job) {
    final transformed = Map<String, dynamic>.from(job);

    // Add UI-expected fields from database fields
    transformed['date'] = _formatDate(job['scheduled_date']);
    transformed['time'] =
        _formatTime(job['scheduled_start_time'] ?? job['scheduled_time']) ??
            'Time TBD';
    transformed['location'] = job['location_address'] ?? 'Location not set';

    // Rate formatting
    final rateText = job['total_amount']?.toString() ??
        job['hourly_rate']?.toString() ??
        'Rate not set';
    transformed['rate'] = rateText;
    transformed['pay'] =
        'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr'; // UI expects 'pay' field with formatting

    // Helper name extraction from joined user data
    String helperName = 'Waiting for Helper';
    if (job['users'] != null && job['users'] is Map) {
      final userData = job['users'] as Map<String, dynamic>;
      helperName = userData['display_name'] ?? 'Helper';
    } else if (job['assigned_helper_id'] != null) {
      helperName = 'Helper';
    }
    transformed['helper'] = helperName;

    // Ensure all expected fields exist with defaults
    transformed['title'] = job['title'] ?? 'Untitled Job';
    transformed['description'] = job['description'] ?? 'No description';
    transformed['status'] = job['status'] ?? 'pending';

    return transformed;
  }

  /// Format date for display
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Date not set';

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Date not set';
    }
  }

  /// Format time for display
  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      // Try parsing as full datetime first
      DateTime dateTime;
      if (timeString.contains('T')) {
        dateTime = DateTime.parse(timeString);
      } else if (timeString.contains(':')) {
        // Parse time only (HH:MM format)
        final parts = timeString.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        dateTime = DateTime(2024, 1, 1, hour, minute);
      } else {
        return null;
      }

      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return null;
    }
  }

  /// Refresh jobs data for current user with retry logic
  Future<void> refreshJobs({String? status, String? userType}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        if (_currentUserId == null) return;

        final currentUser = _authService.currentUser;
        if (currentUser == null) return;

        final userRole = currentUser['user_type'];
        String cacheKey = '${userRole}_${status ?? 'all'}';

        List<Map<String, dynamic>> jobs = [];

        if (userRole == 'helpee') {
          var query = _supabase.from('jobs').select('''
                id, title, description, status, job_type, location_address, 
                scheduled_date, scheduled_start_time, total_amount, hourly_rate, created_at, assigned_helper_id,
                users!jobs_assigned_helper_id_fkey(display_name, profile_picture_url, user_type)
              ''').eq('helpee_id', _currentUserId!);

          if (status != null) {
            query = query.eq('status', status);
          }

          // Add timeout to prevent hanging requests
          final response = await query
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10));
          jobs = List<Map<String, dynamic>>.from(response);
        } else if (userRole == 'helper') {
          // For helpers jobs: get assigned jobs AND public pending jobs
          List<Map<String, dynamic>> assignedJobs = [];
          List<Map<String, dynamic>> publicPendingJobs = [];

          // Get jobs assigned to this helper
          var assignedQuery = _supabase
              .from('jobs')
              .select('''
                id, title, description, status, job_type, location_address, 
                scheduled_date, scheduled_start_time, total_amount, hourly_rate, created_at, helpee_id,
                users!jobs_helpee_id_fkey(display_name, profile_picture_url, user_type)
              ''')
              .eq('assigned_helper_id', _currentUserId!)
              .inFilter('status', [
                'pending',
                'accepted',
                'ongoing',
                'started',
                'completed',
                'cancelled'
              ]);

          if (status != null && status != 'pending') {
            assignedQuery = assignedQuery.eq('status', status);
          }

          assignedJobs = List<Map<String, dynamic>>.from(await assignedQuery
              .order('created_at', ascending: false)
              .timeout(Duration(seconds: 10)));

          // Get public pending jobs (only if we're not filtering by a specific non-pending status)
          if (status == null || status == 'pending') {
            try {
              // CRITICAL FIX: Use the filtered database function
              final filteredJobs =
                  await _supabase.rpc('get_public_jobs_for_helper', params: {
                'p_helper_id': _currentUserId,
              }).timeout(Duration(seconds: 10));

              // Transform to match expected format
              publicPendingJobs =
                  List<Map<String, dynamic>>.from(filteredJobs).map((job) {
                return {
                  'id': job['id'],
                  'title': job['title'],
                  'description': job['description'],
                  'status': job['status'],
                  'job_type': job['is_private'] ? 'private' : 'public',
                  'location_address': job['location_address'],
                  'scheduled_date': job['scheduled_date'],
                  'scheduled_start_time': job['scheduled_start_time'],
                  'total_amount': null,
                  'hourly_rate': job['hourly_rate'],
                  'created_at': job['created_at'],
                  'helpee_id': job['helpee_id'],
                  'users': {
                    'display_name':
                        '${job['helpee_first_name']} ${job['helpee_last_name']}',
                    'profile_picture_url': null,
                    'user_type': 'helpee',
                  }
                };
              }).toList();
            } catch (e) {
              print('⚠️ Failed to get filtered jobs, using empty list: $e');
              publicPendingJobs = [];
            }
          }

          // Combine and deduplicate
          final jobIds = <String>{};
          jobs = [];

          for (final job in [...assignedJobs, ...publicPendingJobs]) {
            final jobId = job['id'].toString();
            if (!jobIds.contains(jobId)) {
              jobIds.add(jobId);
              jobs.add(job);
            }
          }

          // Sort by created_at
          jobs.sort((a, b) => DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));
        }

        // Transform job data to match UI expectations
        final transformedJobs =
            jobs.map(_transformJobData).cast<Map<String, dynamic>>().toList();

        // Update cache and broadcast
        _cachedJobs[cacheKey] = transformedJobs;
        _jobsController.add(transformedJobs);

        print('✅ Jobs refreshed: ${transformedJobs.length} jobs for $cacheKey');
        return; // Success, exit retry loop
      } catch (e) {
        print('❌ Error refreshing jobs (attempt ${attempt + 1}): $e');
        if (attempt == 2) {
          print('❌ Failed to refresh jobs after 3 attempts');
          return;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
  }

  /// Refresh activity data
  Future<void> refreshActivity({String? status}) async {
    try {
      if (_currentUserId == null) return;

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userRole = currentUser['user_type'];
      String cacheKey = '${userRole}_activity_${status ?? 'all'}';

      List<Map<String, dynamic>> activities = [];

      if (userRole == 'helpee') {
        var query = _supabase.from('jobs').select('''
              id, title, description, status, job_type, location_address, 
              scheduled_date, scheduled_start_time, total_amount, hourly_rate, created_at, updated_at, assigned_helper_id,
              users!jobs_assigned_helper_id_fkey(display_name, profile_picture_url)
            ''').eq('helpee_id', _currentUserId!);

        if (status != null) {
          query = query.eq('status', status);
        }

        activities = List<Map<String, dynamic>>.from(
            await query.order('updated_at', ascending: false));
      } else if (userRole == 'helper') {
        // For helpers, we need to get:
        // 1. Jobs assigned to them (all statuses)
        // 2. Public pending jobs (assigned_helper_id is NULL and status is 'pending')

        List<Map<String, dynamic>> assignedJobs = [];
        List<Map<String, dynamic>> publicPendingJobs = [];

        // Get jobs assigned to this helper
        var assignedQuery = _supabase.from('jobs').select('''
              id, title, description, status, job_type, location_address, 
              scheduled_date, scheduled_start_time, total_amount, hourly_rate, created_at, updated_at, helpee_id,
              users!jobs_helpee_id_fkey(display_name, profile_picture_url)
            ''').eq('assigned_helper_id', _currentUserId!).inFilter('status', [
              'pending',
              'accepted',
              'ongoing',
              'started',
              'completed',
              'cancelled'
            ]);

        if (status != null && status != 'pending') {
          assignedQuery = assignedQuery.eq('status', status);
        }

        assignedJobs = List<Map<String, dynamic>>.from(
            await assignedQuery.order('updated_at', ascending: false));

        // Get public pending jobs (only if we're not filtering by a specific non-pending status)
        if (status == null || status == 'pending') {
          // CRITICAL FIX: Use the filtered database function instead of direct query
          final filteredJobs =
              await _supabase.rpc('get_public_jobs_for_helper', params: {
            'p_helper_id': _currentUserId,
          });

          // Transform to match expected format
          publicPendingJobs =
              List<Map<String, dynamic>>.from(filteredJobs).map((job) {
            return {
              'id': job['id'],
              'title': job['title'],
              'description': job['description'],
              'status': job['status'],
              'job_type': job['is_private'] ? 'private' : 'public',
              'location_address': job['location_address'],
              'scheduled_date': job['scheduled_date'],
              'scheduled_start_time': job['scheduled_start_time'],
              'total_amount': null, // Not in function return
              'hourly_rate': job['hourly_rate'],
              'created_at': job['created_at'],
              'updated_at': job['created_at'], // Use created_at as fallback
              'helpee_id': job['helpee_id'],
              'users': {
                'display_name':
                    '${job['helpee_first_name']} ${job['helpee_last_name']}',
                'profile_picture_url': null, // Not in function return
              }
            };
          }).toList();
        }

        // Combine and deduplicate
        final jobIds = <String>{};
        activities = [];

        for (final job in [...assignedJobs, ...publicPendingJobs]) {
          final jobId = job['id'].toString();
          if (!jobIds.contains(jobId)) {
            jobIds.add(jobId);
            activities.add(job);
          }
        }

        // Sort by updated_at
        activities.sort((a, b) => DateTime.parse(b['updated_at'])
            .compareTo(DateTime.parse(a['updated_at'])));
      }

      // Transform activity data to match UI expectations
      final transformedActivities = activities
          .map(_transformJobData)
          .cast<Map<String, dynamic>>()
          .toList();

      // Update cache and broadcast
      _cachedActivity[cacheKey] = transformedActivities;
      _activityController.add(transformedActivities);

      print(
          '✅ Activity refreshed: ${transformedActivities.length} activities for $cacheKey');
    } catch (e) {
      print('❌ Error refreshing activity: $e');
    }
  }

  /// Refresh calendar data
  Future<void> refreshCalendar({DateTime? startDate, DateTime? endDate}) async {
    try {
      if (_currentUserId == null) return;

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userRole = currentUser['user_type'];
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      String cacheKey =
          '${userRole}_calendar_${start.toIso8601String().split('T')[0]}_${end.toIso8601String().split('T')[0]}';

      List<Map<String, dynamic>> calendarJobs = [];

      if (userRole == 'helpee') {
        calendarJobs = List<Map<String, dynamic>>.from(await _supabase
            .from('jobs')
            .select('''
                id, title, status, job_type, scheduled_date, scheduled_start_time,
                total_amount, hourly_rate, location_address, assigned_helper_id,
                users!jobs_assigned_helper_id_fkey(display_name, profile_picture_url)
              ''')
            .eq('helpee_id', _currentUserId!)
            .gte('scheduled_date', start.toIso8601String())
            .lte('scheduled_date', end.toIso8601String())
            .order('scheduled_date', ascending: true));
      } else if (userRole == 'helper') {
        // For helpers calendar: get assigned jobs AND public pending jobs
        List<Map<String, dynamic>> assignedJobs = [];
        List<Map<String, dynamic>> publicPendingJobs = [];

        // Get jobs assigned to this helper
        assignedJobs = List<Map<String, dynamic>>.from(await _supabase
            .from('jobs')
            .select('''
                id, title, status, job_type, scheduled_date, scheduled_start_time,
                total_amount, hourly_rate, location_address, helpee_id,
                users!jobs_helpee_id_fkey(display_name, profile_picture_url)
              ''')
            .eq('assigned_helper_id', _currentUserId!)
            .inFilter('status',
                ['pending', 'accepted', 'ongoing', 'started', 'completed'])
            .gte('scheduled_date', start.toIso8601String())
            .lte('scheduled_date', end.toIso8601String())
            .order('scheduled_date', ascending: true));

        // CRITICAL FIX: Use filtered database function for public jobs
        final allFilteredJobs =
            await _supabase.rpc('get_public_jobs_for_helper', params: {
          'p_helper_id': _currentUserId,
        });

        // Filter by date range
        publicPendingJobs =
            List<Map<String, dynamic>>.from(allFilteredJobs).where((job) {
          final jobDate = DateTime.parse(job['scheduled_date']);
          return jobDate.isAfter(start.subtract(const Duration(days: 1))) &&
              jobDate.isBefore(end.add(const Duration(days: 1)));
        }).map((job) {
          return {
            'id': job['id'],
            'title': job['title'],
            'status': job['status'],
            'job_type': job['is_private'] ? 'private' : 'public',
            'scheduled_date': job['scheduled_date'],
            'scheduled_start_time': job['scheduled_start_time'],
            'total_amount': null,
            'hourly_rate': job['hourly_rate'],
            'location_address': job['location_address'],
            'helpee_id': job['helpee_id'],
            'users': {
              'display_name':
                  '${job['helpee_first_name']} ${job['helpee_last_name']}',
              'profile_picture_url': null,
            }
          };
        }).toList();

        // Combine and deduplicate
        final jobIds = <String>{};
        calendarJobs = [];

        for (final job in [...assignedJobs, ...publicPendingJobs]) {
          final jobId = job['id'].toString();
          if (!jobIds.contains(jobId)) {
            jobIds.add(jobId);
            calendarJobs.add(job);
          }
        }

        // Sort by scheduled_date
        calendarJobs.sort((a, b) => DateTime.parse(a['scheduled_date'])
            .compareTo(DateTime.parse(b['scheduled_date'])));
      }

      // Transform calendar data to match UI expectations
      final transformedCalendarJobs = calendarJobs
          .map(_transformJobData)
          .cast<Map<String, dynamic>>()
          .toList();

      // Update cache and broadcast
      _cachedCalendar[cacheKey] = transformedCalendarJobs;
      _calendarController.add(transformedCalendarJobs);

      print(
          '✅ Calendar refreshed: ${transformedCalendarJobs.length} jobs for $cacheKey');
    } catch (e) {
      print('❌ Error refreshing calendar: $e');
    }
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    try {
      if (_currentUserId == null) return;

      final profileData = await _supabase.from('users').select('''
            id, email, display_name, user_type, phone, date_of_birth, location_address,
            profile_picture_url, fcm_token, notification_enabled, bio, emergency_contact_name,
            emergency_contact_phone, is_verified, created_at
          ''').eq('id', _currentUserId!).single();

      // Get additional stats if helper
      if (profileData['user_type'] == 'helper') {
        final stats = await _supabase.rpc('get_helper_statistics',
            params: {'p_helper_id': _currentUserId});

        profileData['stats'] = stats;
      }

      _cachedProfile = profileData;
      _profileController.add(profileData);

      print('✅ Profile refreshed for user: $_currentUserId');
    } catch (e) {
      print('❌ Error refreshing profile: $e');
    }
  }

  /// Refresh statistics data
  Future<void> refreshStats() async {
    try {
      if (_currentUserId == null) return;

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userRole = currentUser['user_type'];
      Map<String, dynamic> stats = {};

      if (userRole == 'helpee') {
        // Get helpee statistics
        final jobStats = await _supabase.rpc('get_helpee_statistics',
            params: {'p_helpee_id': _currentUserId});
        if (jobStats is List && jobStats.isNotEmpty) {
          stats = Map<String, dynamic>.from(jobStats.first);
        } else {
          stats = {};
        }
      } else if (userRole == 'helper') {
        // Get helper statistics
        final helperStats = await _supabase.rpc('get_helper_statistics',
            params: {'p_helper_id': _currentUserId});
        if (helperStats is List && helperStats.isNotEmpty) {
          stats = Map<String, dynamic>.from(helperStats.first);
        } else {
          stats = {};
        }
      }

      _cachedStats = stats;
      _statsController.add(stats);

      print('✅ Stats refreshed for $userRole: $_currentUserId');
    } catch (e) {
      print('❌ Error refreshing stats: $e');
    }
  }

  /// Get cached jobs data
  List<Map<String, dynamic>>? getCachedJobs(
      {String? status, String? userType}) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final userRole = userType ?? currentUser['user_type'];
    String cacheKey = '${userRole}_${status ?? 'all'}';
    return _cachedJobs[cacheKey];
  }

  /// Get cached activity data
  List<Map<String, dynamic>>? getCachedActivity({String? status}) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final userRole = currentUser['user_type'];
    String cacheKey = '${userRole}_activity_${status ?? 'all'}';
    return _cachedActivity[cacheKey];
  }

  /// Get cached calendar data
  List<Map<String, dynamic>>? getCachedCalendar(
      {DateTime? startDate, DateTime? endDate}) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final userRole = currentUser['user_type'];
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0);

    String cacheKey =
        '${userRole}_calendar_${start.toIso8601String().split('T')[0]}_${end.toIso8601String().split('T')[0]}';
    return _cachedCalendar[cacheKey];
  }

  /// Get cached profile data
  Map<String, dynamic>? getCachedProfile() => _cachedProfile;

  /// Get cached stats data
  Map<String, dynamic>? getCachedStats() => _cachedStats;

  /// Force refresh all data
  Future<void> refreshAllData() async {
    print('🔄 Force refreshing all data...');
    await Future.wait([
      refreshJobs(),
      refreshActivity(),
      refreshCalendar(),
      refreshProfile(),
      refreshStats(),
    ]);
    print('✅ All data refreshed');
  }

  /// Clear all cached data
  void clearCache() {
    _cachedJobs.clear();
    _cachedActivity.clear();
    _cachedCalendar.clear();
    _cachedProfile = null;
    _cachedStats = null;
    print('🗑️ Cache cleared');
  }

  /// Dispose and cleanup
  void dispose() {
    _jobUpdateSubscription?.cancel();
    _notificationSubscription?.cancel();
    _autoRefreshTimer?.cancel(); // Cancel the auto-refresh timer

    _jobsController.close();
    _activityController.close();
    _calendarController.close();
    _profileController.close();
    _statsController.close();

    clearCache();

    _isInitialized = false;
    print('🔄 Live Data Refresh Service disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
