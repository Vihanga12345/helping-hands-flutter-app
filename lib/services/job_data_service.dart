import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';

class JobDataService {
  static final JobDataService _instance = JobDataService._internal();
  factory JobDataService() => _instance;
  JobDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get jobs by user and status for helpee
  Future<List<Map<String, dynamic>>> getJobsByUserAndStatus(
      String userId, String status) async {
    try {
      print('🔍 Getting jobs for helpee user: $userId, status: $status');

      // For ongoing status, include both 'ongoing', 'accepted', and 'started' jobs
      final statusesToQuery = status.toLowerCase() == 'ongoing'
          ? ['ongoing', 'accepted', 'started']
          : [status.toLowerCase()];

      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, created_at, description,
            job_categories(id, name),
            helper:users!assigned_helper_id(id, first_name, last_name)
          ''')
          .eq('helpee_id', userId)
          .inFilter('status', statusesToQuery)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((job) {
        final helper = job['helper'];
        final category = job['job_categories'];

        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helper_name': helper != null
              ? '${helper['first_name'] ?? ''} ${helper['last_name'] ?? ''}'
                  .trim()
              : 'Pending Assignment',
          'description': job['description'] ?? 'No description provided.',
          'category': category?['name'] ?? 'General',
          'status': job['status'] ?? 'pending',
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting jobs by user and status: $e');
      return [];
    }
  }

  /// Get jobs by helper and status - NOW WITH JOB CATEGORY FILTERING AND FALLBACK
  Future<List<Map<String, dynamic>>> getJobsByHelperAndStatus(
      String helperId, String status) async {
    try {
      print('🔍 Getting jobs for helper: $helperId, status: $status');

      // For ongoing status, include both 'ongoing', 'accepted', and 'started' jobs
      final statusesToQuery = status.toLowerCase() == 'ongoing'
          ? ['ongoing', 'accepted', 'started']
          : [status.toLowerCase()];

      try {
        // Try to use the new database function that filters by job categories
        final response =
            await _supabase.rpc('get_helper_assigned_jobs_by_status', params: {
          'p_helper_id': helperId,
          'p_statuses': statusesToQuery,
        });

        print(
            '✅ Found ${response.length} $status jobs matching helper preferences');

        // Transform the database response to match the expected UI format
        return List<Map<String, dynamic>>.from(response).map((job) {
          return {
            'id': job['id']?.toString() ?? '',
            'title': job['title'] ?? 'Unknown Job',
            'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
            'date': _formatDate(job['scheduled_date']),
            'time': job['scheduled_start_time'] ?? 'Time TBD',
            'location': job['location_address'] ?? 'Location TBD',
            'helpee_name':
                '${job['helpee_first_name'] ?? ''} ${job['helpee_last_name'] ?? ''}'
                    .trim(),
            'description': job['description'] ?? 'No description provided.',
            'category': job['job_category_name'] ?? 'General',
            'status': job['status'] ?? 'pending',
            'timer_status': job['timer_status'] ?? 'not_started',
            'created_at': job['created_at'],
            'hourly_rate': job['hourly_rate'],
            'scheduled_date': job['scheduled_date'],
            'scheduled_start_time': job['scheduled_start_time'],
            'location_address': job['location_address'],
            'job_category_name': job['job_category_name'],
          };
        }).toList();
      } catch (funcError) {
        print('⚠️ Database function failed, using fallback: $funcError');

        // FALLBACK: Use direct query with manual filtering
        return await _getJobsByHelperAndStatusFallback(
            helperId, statusesToQuery);
      }
    } catch (e) {
      print('❌ Error getting jobs by helper and status: $e');
      return [];
    }
  }

  /// Fallback method for getting jobs when database functions fail
  Future<List<Map<String, dynamic>>> _getJobsByHelperAndStatusFallback(
      String helperId, List<String> statusesToQuery) async {
    try {
      print('🔄 Using fallback method for helper jobs');

      // Get all assigned jobs without filtering
      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, timer_status, created_at, description,
            job_category_name,
            job_categories(id, name),
            helpee:users!helpee_id(id, first_name, last_name, location_city)
          ''')
          .eq('assigned_helper_id', helperId)
          .inFilter('status', statusesToQuery)
          .order('created_at', ascending: false);

      // Get helper's active job categories
      final helperCategoriesResponse = await _supabase
          .from('helper_job_types')
          .select('job_categories(name)')
          .eq('helper_id', helperId)
          .eq('is_active', true);

      final activeCategories = helperCategoriesResponse
          .map((item) => item['job_categories']['name'] as String)
          .toSet();

      print('🔍 Helper active categories (fallback): $activeCategories');

      // Filter jobs by active categories
      final filteredJobs = response.where((job) {
        final jobCategory = job['job_category_name'] as String?;
        return jobCategory != null && activeCategories.contains(jobCategory);
      }).toList();

      print('✅ Filtered to ${filteredJobs.length} jobs in active categories');

      return filteredJobs.map((job) {
        final helpee = job['helpee'];
        final category = job['job_categories'];

        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helpee_name': helpee != null
              ? '${helpee['first_name'] ?? ''} ${helpee['last_name'] ?? ''}'
                  .trim()
              : 'Unknown Client',
          'description': job['description'] ?? 'No description provided.',
          'category':
              job['job_category_name'] ?? category?['name'] ?? 'General',
          'status': job['status'] ?? 'pending',
          'timer_status': job['timer_status'] ?? 'not_started',
          'created_at': job['created_at'],
          'hourly_rate': job['hourly_rate'],
          'scheduled_date': job['scheduled_date'],
          'scheduled_start_time': job['scheduled_time'],
          'location_address': job['location_address'],
          'job_category_name': job['job_category_name'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error in fallback method: $e');
      return [];
    }
  }

  /// Get jobs for calendar view (helpee)
  Future<Map<DateTime, List<Map<String, dynamic>>>> getJobsForCalendar(
      String userId) async {
    try {
      print('🗓️ Getting calendar jobs for helpee: $userId');

      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, scheduled_date, scheduled_time, status,
            users!assigned_helper_id(first_name, last_name)
          ''')
          .eq('helpee_id', userId)
          .not('scheduled_date', 'is', null)
          .order('scheduled_date', ascending: true);

      Map<DateTime, List<Map<String, dynamic>>> calendarEvents = {};

      for (var job in response) {
        final dateStr = job['scheduled_date'];
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);

          final helper = job['users'];
          final event = {
            'title': job['title'] ?? 'Unknown Job',
            'status': job['status']?.toUpperCase() ?? 'PENDING',
            'helper': helper != null
                ? '${helper['first_name'] ?? ''} ${helper['last_name'] ?? ''}'
                    .trim()
                : 'Waiting for Helper',
            'time': job['scheduled_time'] ?? 'Time TBD',
            'job_id': job['id']?.toString() ?? '',
          };

          if (calendarEvents[dateKey] == null) {
            calendarEvents[dateKey] = [];
          }
          calendarEvents[dateKey]!.add(event);
        }
      }

      return calendarEvents;
    } catch (e) {
      print('❌ Error getting jobs for calendar: $e');
      return {};
    }
  }

  /// Get jobs for helper calendar view - includes both assigned jobs and available jobs - NOW WITH JOB CATEGORY FILTERING
  Future<Map<DateTime, List<Map<String, dynamic>>>> getHelperJobsForCalendar(
      String helperId) async {
    try {
      print('🗓️ Getting calendar jobs for helper: $helperId');

      // 1. Get assigned jobs filtered by helper's job preferences
      final assignedJobsResponse =
          await _supabase.rpc('get_helper_assigned_jobs_for_calendar', params: {
        'p_helper_id': helperId,
      });

      // Transform assigned jobs response
      final assignedJobs = List<Map<String, dynamic>>.from(assignedJobsResponse)
          .map((job) => {
                'id': job['id'],
                'title': job['title'],
                'scheduled_date': job['scheduled_date'],
                'scheduled_time': job['scheduled_start_time'],
                'status': job['status'],
                'is_private': job['is_private'],
                'users': {
                  'first_name': job['helpee_first_name'],
                  'last_name': job['helpee_last_name'],
                }
              })
          .toList();

      // 2. Get available public jobs filtered by helper's job preferences
      final availablePublicJobs = await getPublicJobRequests(helperId);

      // 3. Filter available public jobs to only include those with scheduled dates
      final availableJobs = availablePublicJobs
          .where((job) => job['scheduled_date'] != null)
          .map((job) => {
                'id': job['id'],
                'title': job['title'],
                'scheduled_date': job['scheduled_date'],
                'scheduled_time': job['scheduled_start_time'],
                'status': job['status'],
                'is_private': job['is_private'],
                'users': {
                  'first_name': job['helpee_first_name'],
                  'last_name': job['helpee_last_name'],
                }
              })
          .toList();

      final allJobs = [...assignedJobs, ...availableJobs];

      Map<DateTime, List<Map<String, dynamic>>> calendarEvents = {};

      for (var job in allJobs) {
        final dateStr = job['scheduled_date'];
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);

          final helpee = job['users'];
          final isAssigned =
              assignedJobs.any((assigned) => assigned['id'] == job['id']);

          final event = {
            'title': job['title'] ?? 'Unknown Job',
            'status': isAssigned
                ? (job['status']?.toUpperCase() ?? 'PENDING')
                : 'AVAILABLE',
            'helpee': helpee != null
                ? '${helpee['first_name'] ?? ''} ${helpee['last_name'] ?? ''}'
                    .trim()
                : 'Unknown Client',
            'time': job['scheduled_time'] ?? 'Time TBD',
            'job_id': job['id']?.toString() ?? '',
            'is_assigned': isAssigned,
            'is_private': job['is_private'] ?? false,
          };

          if (calendarEvents[dateKey] == null) {
            calendarEvents[dateKey] = [];
          }
          calendarEvents[dateKey]!.add(event);
        }
      }

      print(
          '✅ Found ${calendarEvents.length} dates with jobs (${assignedJobs.length} assigned + ${availableJobs.length} available)');
      return calendarEvents;
    } catch (e) {
      print('❌ Error getting helper jobs for calendar: $e');
      return {};
    }
  }

  /// Get public job requests filtered by helper's job type preferences
  Future<List<Map<String, dynamic>>> getPublicJobRequests(
      String helperId) async {
    try {
      print('🔍 Getting public job requests for helper: $helperId');

      // Use the new simplified database function
      final response =
          await _supabase.rpc('get_public_jobs_for_helper', params: {
        'p_helper_id': helperId,
      });

      print(
          '✅ Found ${response.length} public jobs matching helper preferences');

      // Transform the database response to match the expected UI format
      return List<Map<String, dynamic>>.from(response).map((job) {
        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_start_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helpee_name':
              '${job['helpee_first_name'] ?? ''} ${job['helpee_last_name'] ?? ''}'
                  .trim(),
          'helpee_location': job['helpee_location_city'] ?? 'Unknown',
          'description': job['description'] ?? 'No description provided.',
          'category': job['job_category_name'] ?? 'General',
          'is_private': false, // Public jobs
          'status': job['status'] ?? 'pending',
          'created_at': job['created_at'],
          'hourly_rate': job['hourly_rate'],
          'scheduled_date': job['scheduled_date'],
          'scheduled_start_time': job['scheduled_start_time'],
          'location_address': job['location_address'],
          'job_category_name': job['job_category_name'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting public job requests: $e');
      return [];
    }
  }

  /// Get private job requests for a specific helper filtered by job type preferences
  Future<List<Map<String, dynamic>>> getPrivateJobRequestsForHelper(
      String helperId) async {
    try {
      print('🔍 Getting private job requests for helper: $helperId');

      // Use the new simplified database function
      final response =
          await _supabase.rpc('get_private_jobs_for_helper', params: {
        'p_helper_id': helperId,
      });

      print('✅ Found ${response.length} private jobs for helper');

      // Transform the database response to match the expected UI format
      return List<Map<String, dynamic>>.from(response).map((job) {
        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_start_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helpee_name':
              '${job['helpee_first_name'] ?? ''} ${job['helpee_last_name'] ?? ''}'
                  .trim(),
          'helpee_location': job['helpee_location_city'] ?? 'Unknown',
          'description': job['description'] ?? 'No description provided.',
          'category': job['job_category_name'] ?? 'General',
          'is_private': true, // Private jobs
          'status': job['status'] ?? 'pending',
          'created_at': job['created_at'],
          'hourly_rate': job['hourly_rate'],
          'scheduled_date': job['scheduled_date'],
          'scheduled_start_time': job['scheduled_start_time'],
          'location_address': job['location_address'],
          'job_category_name': job['job_category_name'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting private job requests for helper: $e');
      return [];
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(String jobId, String newStatus) async {
    try {
      print('🔄 Updating job $jobId status to: $newStatus');

      await _supabase
          .from('jobs')
          .update({'status': newStatus.toLowerCase()}).eq('id', jobId);

      print('✅ Job status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating job status: $e');
      return false;
    }
  }

  /// Accept job request (assign helper to job)
  Future<bool> acceptJobRequest(String jobId, String helperId) async {
    try {
      print('🤝 Helper $helperId accepting job $jobId');

      await _supabase
          .from('jobs')
          .update({'assigned_helper_id': helperId, 'status': 'accepted'}).eq(
              'id', jobId);

      print('✅ Job accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting job: $e');
      return false;
    }
  }

  /// Reject job request
  Future<bool> rejectJobRequest(String jobId, String helperId) async {
    try {
      print('❌ Helper $helperId rejecting job $jobId');

      await _supabase
          .from('jobs')
          .update({'status': 'rejected'}).eq('id', jobId);

      print('✅ Job rejected successfully');
      return true;
    } catch (e) {
      print('❌ Error rejecting job: $e');
      return false;
    }
  }

  /// Start job (change status from accepted to started)
  Future<bool> startJob(String jobId) async {
    try {
      print('▶️ Starting job $jobId');

      // Use the new timer functionality
      return await startJobTimer(jobId);
    } catch (e) {
      print('❌ Error starting job: $e');
      return false;
    }
  }

  /// Pause job
  Future<bool> pauseJob(String jobId) async {
    try {
      print('⏸️ Pausing job $jobId');

      // Use the new timer functionality
      return await pauseJobTimer(jobId);
    } catch (e) {
      print('❌ Error pausing job: $e');
      return false;
    }
  }

  /// Resume job (change status from paused to started)
  Future<bool> resumeJob(String jobId) async {
    try {
      print('▶️ Resuming job $jobId');

      // Use the new timer functionality
      return await resumeJobTimer(jobId);
    } catch (e) {
      print('❌ Error resuming job: $e');
      return false;
    }
  }

  /// Complete job
  Future<bool> completeJob(String jobId) async {
    try {
      print('✅ Completing job $jobId');

      // Get current elapsed time before completing
      final currentElapsed = await getJobElapsedTime(jobId);

      await _supabase.from('jobs').update({
        'status': 'completed',
        'timer_status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'total_elapsed_seconds': currentElapsed,
      }).eq('id', jobId);

      print('✅ Job completed successfully');
      return true;
    } catch (e) {
      print('❌ Error completing job: $e');
      return false;
    }
  }

  /// Start job timer
  Future<bool> startJobTimer(String jobId) async {
    try {
      print('⏰ Starting job timer: $jobId');

      await _supabase.from('jobs').update({
        'status': 'started',
        'timer_status': 'running',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job timer started successfully');
      return true;
    } catch (e) {
      print('❌ Error starting job timer: $e');
      return false;
    }
  }

  /// Pause job timer
  Future<bool> pauseJobTimer(String jobId) async {
    try {
      print('⏸️ Pausing job timer: $jobId');

      // Get current elapsed time
      final currentElapsed = await getJobElapsedTime(jobId);

      await _supabase.from('jobs').update({
        'timer_status': 'paused',
        'paused_at': DateTime.now().toIso8601String(),
        'total_elapsed_seconds': currentElapsed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job timer paused successfully');
      return true;
    } catch (e) {
      print('❌ Error pausing job timer: $e');
      return false;
    }
  }

  /// Resume job timer
  Future<bool> resumeJobTimer(String jobId) async {
    try {
      print('▶️ Resuming job timer: $jobId');

      await _supabase.from('jobs').update({
        'timer_status': 'running',
        'resumed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job timer resumed successfully');
      return true;
    } catch (e) {
      print('❌ Error resuming job timer: $e');
      return false;
    }
  }

  /// Get job timer information
  Future<Map<String, dynamic>> getJobTimerInfo(String jobId) async {
    try {
      print('🔍 Getting job timer info: $jobId');

      final response = await _supabase
          .from('job_timer_info')
          .select('*')
          .eq('id', jobId)
          .single();

      print('✅ Job timer info retrieved successfully');
      return response;
    } catch (e) {
      print('❌ Error getting job timer info: $e');
      // Return default timer info if view doesn't exist yet
      final basicJob = await _supabase
          .from('jobs')
          .select(
              'id, timer_status, started_at, paused_at, total_elapsed_seconds')
          .eq('id', jobId)
          .maybeSingle();

      if (basicJob != null) {
        final elapsedSeconds = await getJobElapsedTime(jobId);
        return {
          'id': jobId,
          'timer_status': basicJob['timer_status'] ?? 'not_started',
          'current_elapsed_seconds': elapsedSeconds,
          'formatted_elapsed_time': formatElapsedTime(elapsedSeconds),
          'is_timer_running': basicJob['timer_status'] == 'running',
          'started_at': basicJob['started_at'],
          'paused_at': basicJob['paused_at'],
          'total_elapsed_seconds': basicJob['total_elapsed_seconds'] ?? 0,
        };
      }

      return {
        'id': jobId,
        'timer_status': 'not_started',
        'current_elapsed_seconds': 0,
        'formatted_elapsed_time': '00:00:00',
        'is_timer_running': false,
      };
    }
  }

  /// Get current elapsed time for a job in seconds
  Future<int> getJobElapsedTime(String jobId) async {
    try {
      print('⏱️ Getting job elapsed time: $jobId');

      // Try to use the database function if available
      try {
        final response = await _supabase
            .rpc('calculate_job_elapsed_time', params: {'job_id': jobId});
        return (response ?? 0) as int;
      } catch (e) {
        print('⚠️ Database function not available, calculating manually: $e');

        // Fallback: Calculate manually
        final job = await _supabase
            .from('jobs')
            .select(
                'started_at, paused_at, resumed_at, timer_status, total_elapsed_seconds')
            .eq('id', jobId)
            .maybeSingle();

        if (job == null || job['started_at'] == null) {
          return 0;
        }

        final startedAt = DateTime.parse(job['started_at']);
        final timerStatus = job['timer_status'] ?? 'not_started';
        final totalElapsed = job['total_elapsed_seconds'] ?? 0;

        if (timerStatus == 'running') {
          if (job['resumed_at'] != null) {
            final resumedAt = DateTime.parse(job['resumed_at']);
            return totalElapsed +
                DateTime.now().difference(resumedAt).inSeconds;
          } else {
            return DateTime.now().difference(startedAt).inSeconds;
          }
        } else {
          return totalElapsed;
        }
      }
    } catch (e) {
      print('❌ Error getting job elapsed time: $e');
      return 0;
    }
  }

  /// Format elapsed time in seconds to HH:MM:SS
  String formatElapsedTime(int seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get real-time timer updates (for live timer display)
  Stream<Map<String, dynamic>> getJobTimerStream(String jobId) async* {
    // Initial timer info
    yield await getJobTimerInfo(jobId);

    // Listen for database changes
    final stream =
        _supabase.from('jobs').stream(primaryKey: ['id']).eq('id', jobId);

    await for (final data in stream) {
      if (data.isNotEmpty) {
        yield await getJobTimerInfo(jobId);
      }
    }
  }

  /// Report job (for completed jobs)
  Future<bool> reportJob(
      String jobId, String reason, String description) async {
    try {
      print('📝 Reporting job $jobId');

      await _supabase.from('job_reports').insert({
        'job_id': jobId,
        'reported_by': _authService.currentUser?['user_id'],
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Job reported successfully');
      return true;
    } catch (e) {
      print('❌ Error reporting job: $e');
      return false;
    }
  }

  /// Delete job permanently (for pending jobs)
  Future<bool> deleteJob(String jobId) async {
    try {
      print('🗑️ Permanently deleting job: $jobId');

      // First delete any job question answers
      await _supabase.from('job_question_answers').delete().eq('job_id', jobId);

      // Then delete the job itself
      await _supabase.from('jobs').delete().eq('id', jobId);

      print('✅ Job deleted permanently from database');
      return true;
    } catch (e) {
      print('❌ Error deleting job: $e');
      return false;
    }
  }

  /// Cancel job (for pending jobs)
  Future<bool> cancelJob(String jobId, String reason) async {
    try {
      print('❌ Cancelling job $jobId');

      // For simplicity, try to delete the job directly first (for pending jobs)
      // If it fails, then update status to cancelled (for non-pending jobs)
      try {
        // First try to delete (this will work for pending jobs)
        await _supabase
            .from('job_question_answers')
            .delete()
            .eq('job_id', jobId);

        await _supabase.from('jobs').delete().eq('id', jobId);

        print('✅ Job deleted successfully');
        return true;
      } catch (deleteError) {
        print('⚠️ Could not delete job, updating status instead: $deleteError');

        // If delete fails, update status to cancelled
        await _supabase.from('jobs').update({
          'status': 'cancelled',
          'cancellation_reason': reason,
        }).eq('id', jobId);

        print('✅ Job status updated to cancelled');
        return true;
      }
    } catch (e) {
      print('❌ Error cancelling job: $e');
      return false;
    }
  }

  /// Get job by ID with full details
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      print('🔍 Getting job details for: $jobId');

      final response = await _supabase.from('jobs').select('''
            id, title, description, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, created_at,
            job_categories(id, name),
            helpee:users!helpee_id(id, first_name, last_name, phone, email),
            helper:users!assigned_helper_id(id, first_name, last_name, phone, email)
          ''').eq('id', jobId).single();

      return response;
    } catch (e) {
      print('❌ Error getting job details: $e');
      return null;
    }
  }

  /// Update job with helper assignment
  Future<bool> assignHelperToJob(String jobId, String helperId) async {
    try {
      print('👤 Assigning helper $helperId to job $jobId');

      await _supabase.from('jobs').update({
        'assigned_helper_id': helperId,
        'status': 'accepted',
        'assigned_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Helper assigned successfully');
      return true;
    } catch (e) {
      print('❌ Error assigning helper: $e');
      return false;
    }
  }

  /// Get job action buttons based on status and user type - UPDATED TO USER SPECIFICATIONS
  List<Map<String, dynamic>> getJobActionButtons(
      Map<String, dynamic> job, String userType,
      {String? context}) {
    final status = job['status']?.toLowerCase() ?? 'unknown';
    final timerStatus = job['timer_status']?.toLowerCase() ?? 'not_started';
    final isPublic = job['is_public'] == true || job['is_private'] == false;
    final List<Map<String, dynamic>> buttons = [];

    print(
        '🔧 Getting action buttons for: userType=$userType, status=$status, timerStatus=$timerStatus, isPublic=$isPublic');

    if (userType == 'helper') {
      switch (status) {
        // HELPER - PENDING TAB: Accept + Reject/Ignore
        case 'pending':
          buttons.add({
            'text': 'Accept',
            'action': 'accept',
            'color': 'success',
            'icon': 'check',
          });

          // Different button text for public vs private jobs
          if (isPublic) {
            buttons.add({
              'text': 'Ignore',
              'action': 'ignore',
              'color': 'secondary',
              'icon': 'visibility_off',
            });
          } else {
            buttons.add({
              'text': 'Reject',
              'action': 'reject',
              'color': 'error',
              'icon': 'close',
            });
          }
          break;

        // HELPER - ONGOING TAB: Start Job initially, then Pause/Resume + Complete
        case 'accepted':
        case 'ongoing':
          // Job accepted but not started yet
          if (timerStatus == 'not_started' || timerStatus == 'stopped') {
            buttons.add({
              'text': 'Start Job',
              'action': 'start',
              'color': 'primary',
              'icon': 'play_arrow',
            });
          }
          // Job is paused - show Resume + Complete
          else if (timerStatus == 'paused') {
            buttons.addAll([
              {
                'text': 'Resume',
                'action': 'resume',
                'color': 'primary',
                'icon': 'play_arrow',
              },
              {
                'text': 'Complete Job',
                'action': 'complete',
                'color': 'success',
                'icon': 'check_circle',
              },
            ]);
          }
          // Job is running - show Pause + Complete
          else if (timerStatus == 'running') {
            buttons.addAll([
              {
                'text': 'Pause',
                'action': 'pause',
                'color': 'warning',
                'icon': 'pause',
              },
              {
                'text': 'Complete Job',
                'action': 'complete',
                'color': 'success',
                'icon': 'check_circle',
              },
            ]);
          }
          break;

        case 'started':
          // Job has been started with timer
          if (timerStatus == 'paused') {
            buttons.addAll([
              {
                'text': 'Resume',
                'action': 'resume',
                'color': 'primary',
                'icon': 'play_arrow',
              },
              {
                'text': 'Complete Job',
                'action': 'complete',
                'color': 'success',
                'icon': 'check_circle',
              },
            ]);
          } else {
            buttons.addAll([
              {
                'text': 'Pause',
                'action': 'pause',
                'color': 'warning',
                'icon': 'pause',
              },
              {
                'text': 'Complete Job',
                'action': 'complete',
                'color': 'success',
                'icon': 'check_circle',
              },
            ]);
          }
          break;

        // HELPER - COMPLETED TAB: Report
        case 'completed':
          buttons.add({
            'text': 'Report',
            'action': 'report',
            'color': 'error',
            'icon': 'report',
          });
          break;
      }
    } else if (userType == 'helpee') {
      switch (status) {
        // HELPEE - PENDING TAB: Edit Job + Cancel Job
        case 'pending':
          buttons.addAll([
            {
              'text': 'Edit Job',
              'action': 'edit',
              'color': 'primary',
              'icon': 'edit',
            },
            {
              'text': 'Cancel Job',
              'action': 'cancel',
              'color': 'error',
              'icon': 'cancel',
            },
          ]);
          break;

        // HELPEE - ONGOING TAB: Report only
        case 'accepted':
        case 'ongoing':
        case 'started':
          buttons.add({
            'text': 'Report',
            'action': 'report',
            'color': 'error',
            'icon': 'report',
          });
          break;

        // HELPEE - COMPLETED TAB: Report only
        case 'completed':
          buttons.add({
            'text': 'Report',
            'action': 'report',
            'color': 'error',
            'icon': 'report',
          });
          break;
      }
    }

    print(
        '✅ Generated ${buttons.length} action buttons: ${buttons.map((b) => b['text']).join(', ')}');
    return buttons;
  }

  /// Execute job action
  Future<bool> executeJobAction(
      String action, String jobId, Map<String, dynamic>? params) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    switch (action) {
      case 'accept':
        return await acceptJobRequest(jobId, currentUser['user_id']);
      case 'reject':
        return await rejectJobRequest(jobId, currentUser['user_id']);
      case 'ignore':
        // For public jobs, helper can ignore (same as reject but different UX)
        return await rejectJobRequest(jobId, currentUser['user_id']);
      case 'start':
        return await startJob(jobId);
      case 'pause':
        return await pauseJob(jobId);
      case 'resume':
        return await resumeJob(jobId);
      case 'complete':
        return await completeJob(jobId);
      case 'cancel':
        return await cancelJob(jobId, params?['reason'] ?? 'Cancelled by user');
      case 'edit':
        // For helpee edit action - this should trigger navigation to edit page
        // Return true to indicate action was handled successfully
        return true;
      case 'report':
        return await reportJob(
            jobId, params?['reason'] ?? 'Other', params?['description'] ?? '');
      default:
        print('❌ Unknown action: $action');
        return false;
    }
  }

  /// Helper method to format date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Date TBD';
    try {
      final date = DateTime.parse(dateStr);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Date TBD';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }

  // Get job details with questions and answers
  Future<Map<String, dynamic>?> getJobDetailsWithQuestions(String jobId) async {
    try {
      print('🔍 Fetching job details for job ID: $jobId');

      // Fetch main job details with relations including helper data
      final jobResponse = await _supabase.from('jobs').select('''
            id, title, description, hourly_rate, scheduled_date, scheduled_start_time,
            location_address, status, timer_status, created_at, is_private,
            estimated_hours, special_instructions, helpee_id, assigned_helper_id,
            job_categories(id, name),
            helpee:users!jobs_helpee_id_fkey(id, first_name, last_name, phone, email, location_city, profile_image_url),
            helper:users!assigned_helper_id(id, first_name, last_name, phone, email, profile_image_url)
          ''').eq('id', jobId).maybeSingle();

      if (jobResponse == null) {
        print('❌ Job not found with ID: $jobId');
        return null;
      }

      // If there's an assigned helper, fetch their statistics
      Map<String, dynamic> helperStats = {};
      if (jobResponse['assigned_helper_id'] != null) {
        final helperId = jobResponse['assigned_helper_id'];

        try {
          // Fetch ratings list and calculate average in Dart
          final ratingsResp = await _supabase
              .from('ratings_reviews')
              .select('rating')
              .eq('reviewee_id', helperId)
              .eq('review_type', 'helpee_to_helper');

          final completedJobsResp = await _supabase
              .from('jobs')
              .select('id')
              .eq('assigned_helper_id', helperId)
              .eq('status', 'completed');

          // Calculate average rating
          double avgRating = 0.0;
          if (ratingsResp.isNotEmpty) {
            final ratings = ratingsResp
                .map((r) => (r['rating'] as num).toDouble())
                .toList();
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }

          // Get helper's job types from helper_skills table
          final helperJobTypesResp = await _supabase
              .from('helper_skills')
              .select('skill_category')
              .eq('helper_id', helperId)
              .eq('is_active', true);

          final jobTypeNames = helperJobTypesResp
              .map((hs) => hs['skill_category'] as String?)
              .where((name) => name != null)
              .cast<String>()
              .toSet() // Remove duplicates
              .toList();

          helperStats = {
            'avg_rating': avgRating,
            'completed_jobs': completedJobsResp.length,
            'job_types': jobTypeNames.isNotEmpty
                ? jobTypeNames.join(' • ')
                : 'General Services',
          };
        } catch (e) {
          print('⚠️ Error fetching helper stats: $e');
          helperStats = {
            'avg_rating': 0.0,
            'completed_jobs': 0,
            'job_types': 'General Services',
          };
        }
      }

      // Fetch job question answers
      final questionsResponse =
          await _supabase.from('job_question_answers').select('''
            answer_text, answer_number, answer_date, answer_time, answer_boolean, selected_options,
            job_category_questions(id, question, question_type, is_required)
          ''').eq('job_id', jobId);

      // Format the response
      final jobDetails = {
        ...jobResponse,
        // Format fields for UI display
        'category_name':
            jobResponse['job_categories']?['name'] ?? 'General Services',
        'date': jobResponse['scheduled_date'],
        'time': jobResponse['scheduled_start_time'],
        'location': jobResponse['location_address'] ?? 'Not specified',
        'hourly_rate': jobResponse['hourly_rate']?.toString() ?? '0',
        // Format helpee information
        'helpee_name': jobResponse['helpee'] != null
            ? '${jobResponse['helpee']['first_name'] ?? ''} ${jobResponse['helpee']['last_name'] ?? ''}'
                .trim()
            : 'Unknown Client',
        // Format helper information if available
        if (jobResponse['helper'] != null) ...{
          'helper_first_name': jobResponse['helper']['first_name'],
          'helper_last_name': jobResponse['helper']['last_name'],
          'helper_profile_pic': jobResponse['helper']['profile_image_url'],
          'helper_avg_rating': helperStats['avg_rating'],
          'helper_completed_jobs': helperStats['completed_jobs'],
          'helper_job_types': helperStats['job_types'],
        },
        // Parse questions and answers
        'parsed_questions': questionsResponse.map((qa) {
          final question = qa['job_category_questions'];

          // Determine answer based on question type
          String answer = 'No answer provided';
          if (qa['answer_text'] != null &&
              qa['answer_text'].toString().isNotEmpty) {
            answer = qa['answer_text'].toString();
          } else if (qa['answer_number'] != null) {
            answer = qa['answer_number'].toString();
          } else if (qa['answer_date'] != null) {
            answer = qa['answer_date'].toString();
          } else if (qa['answer_time'] != null) {
            answer = qa['answer_time'].toString();
          } else if (qa['answer_boolean'] != null) {
            answer = qa['answer_boolean'] == true ? 'Yes' : 'No';
          } else if (qa['selected_options'] != null) {
            answer = qa['selected_options'].toString();
          }

          return {
            'question_id': question?['id'],
            'question': question?['question'] ?? 'Question not available',
            'question_type': question?['question_type'] ?? 'text',
            'is_required': question?['is_required'] ?? false,
            'answer': answer,
          };
        }).toList(),
      };

      print('✅ Job details fetched successfully with helper data');
      return jobDetails;
    } catch (e) {
      print('❌ Error fetching job details with questions: $e');
      return null;
    }
  }

  // Update job with questions and answers
  Future<bool> updateJobWithQuestions({
    required String jobId,
    required String title,
    required String description,
    required String categoryId,
    required String jobCategoryName,
    required double hourlyRate,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String locationAddress,
    required bool isPrivate,
    String? notes,
    List<Map<String, dynamic>>? questionAnswers,
  }) async {
    try {
      // Update the job record with category name
      await _supabase.from('jobs').update({
        'title': title,
        'description': description,
        'category_id': categoryId,
        'job_category_name': jobCategoryName,
        'hourly_rate': hourlyRate,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'scheduled_start_time': scheduledTime,
        'location_address': locationAddress,
        'is_private': isPrivate,
        'special_instructions': notes ?? description,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Update question answers if provided
      if (questionAnswers != null && questionAnswers.isNotEmpty) {
        // Delete existing answers
        await _supabase
            .from('job_question_answers')
            .delete()
            .eq('job_id', jobId);

        // Insert new answers
        final answersToInsert = questionAnswers.map((answer) {
          return {
            'job_id': jobId,
            'question_id': answer['question_id'],
            'answer': answer['answer_text'] ??
                answer['answer_number']?.toString() ??
                answer['answer_boolean']?.toString() ??
                (answer['selected_options'] as List?)?.join(', ') ??
                '',
            'created_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase.from('job_question_answers').insert(answersToInsert);
      }

      return true;
    } catch (e) {
      print('Error updating job with questions: $e');
      return false;
    }
  }

  /// Get all public job requests for helpers to view
  Future<List<Map<String, dynamic>>> getPublicJobs() async {
    try {
      print('🔍 Fetching public jobs...');

      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, description, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, created_at, is_private,
            job_categories(id, name),
            helpee:users!jobs_helpee_id_fkey(id, first_name, last_name, location_city)
          ''')
          .eq('is_private', false)
          .eq('status', 'pending')
          .filter('assigned_helper_id', 'is', 'null')
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} public jobs');

      // Format the job data
      final formattedJobs = response.map((job) {
        final helpee = job['helpee'];
        final category = job['job_categories'];

        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'description': job['description'] ?? 'No description provided.',
          'hourly_rate': job['hourly_rate'] ?? 0,
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helpee_name': helpee != null
              ? '${helpee['first_name'] ?? ''} ${helpee['last_name'] ?? ''}'
                  .trim()
              : 'Unknown Client',
          'helpee_location': helpee?['location_city'] ?? 'Unknown',
          'category': category?['name'] ?? 'General',
          'distance': '1.5 km away', // Placeholder
        };
      }).toList();

      return formattedJobs;
    } catch (e) {
      print('❌ Error fetching public jobs: $e');
      return [];
    }
  }

  /// Get private job requests assigned to a specific helper
  Future<List<Map<String, dynamic>>> getPrivateJobRequests(
      String helperId) async {
    try {
      print('🔍 Fetching private job requests for helper: $helperId');

      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, description, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, created_at, is_private,
            job_categories(id, name),
            helpee:users!jobs_helpee_id_fkey(id, first_name, last_name, location_city)
          ''')
          .eq('is_private', true)
          .eq('assigned_helper_id', helperId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} private job requests');

      // Format the job data
      final formattedJobs = response.map((job) {
        final helpee = job['helpee'];
        final category = job['job_categories'];

        return {
          'id': job['id']?.toString() ?? '',
          'title': job['title'] ?? 'Unknown Job',
          'description': job['description'] ?? 'No description provided.',
          'hourly_rate': job['hourly_rate'] ?? 0,
          'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
          'date': _formatDate(job['scheduled_date']),
          'time': job['scheduled_time'] ?? 'Time TBD',
          'location': job['location_address'] ?? 'Location TBD',
          'helpee_name': helpee != null
              ? '${helpee['first_name'] ?? ''} ${helpee['last_name'] ?? ''}'
                  .trim()
              : 'Unknown Client',
          'helpee_location': helpee?['location_city'] ?? 'Unknown',
          'category': category?['name'] ?? 'General',
        };
      }).toList();

      return formattedJobs;
    } catch (e) {
      print('❌ Error fetching private job requests: $e');
      return [];
    }
  }

  /// Accept a job - assign helper and change status to accepted
  Future<bool> acceptJob(String jobId, String helperId) async {
    try {
      print('🤝 Accepting job $jobId for helper $helperId');

      final response = await _supabase.from('jobs').update({
        'assigned_helper_id': helperId,
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting job: $e');
      return false;
    }
  }

  /// Reject a private job - change status to rejected
  Future<bool> rejectJob(String jobId, String helperId) async {
    try {
      print('❌ Rejecting job $jobId by helper $helperId');

      // For private jobs, we can change status to rejected
      final response = await _supabase
          .from('jobs')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
            'special_instructions': 'Rejected by assigned helper',
          })
          .eq('id', jobId)
          .eq('assigned_helper_id', helperId);

      print('✅ Job rejected successfully');
      return true;
    } catch (e) {
      print('❌ Error rejecting job: $e');
      return false;
    }
  }

  /// Ignore a public job - add to ignored jobs table to hide from this helper
  Future<bool> ignoreJob(String jobId, String helperId) async {
    try {
      print('🙈 Ignoring job $jobId by helper $helperId');

      // Insert into job_ignores table to track that this helper has ignored this job
      final response = await _supabase.from('job_ignores').insert({
        'job_id': jobId,
        'helper_id': helperId,
        'ignored_at': DateTime.now().toIso8601String(),
      });

      print('✅ Job ignored successfully');
      return true;
    } catch (e) {
      print('❌ Error ignoring job: $e');
      return false;
    }
  }

  /// Get all pending jobs for a specific helper, including private requests assigned to them AND public jobs available for pickup
  Future<List<Map<String, dynamic>>> getHelperPendingJobs(
      String helperId) async {
    try {
      print('🔍 Fetching all pending jobs for helper: $helperId');

      // 1. Use the new database function to get filtered public jobs
      final publicJobs = await getPublicJobRequests(helperId);

      // 2. Use the new database function to get filtered private jobs
      final privateJobs = await getPrivateJobRequestsForHelper(helperId);

      // 3. Combine both lists
      final allPendingJobs = [...publicJobs, ...privateJobs];

      // Remove duplicates based on job ID
      final uniqueJobs = <String, Map<String, dynamic>>{};
      for (final job in allPendingJobs) {
        final jobId = job['id'].toString();
        uniqueJobs[jobId] = job;
      }

      // Sort by creation date
      final sortedJobs = uniqueJobs.values.toList();
      sortedJobs.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      print(
          '✅ Found ${sortedJobs.length} total pending jobs (${privateJobs.length} private + ${publicJobs.length} public)');
      return sortedJobs;
    } catch (e) {
      print('❌ Error fetching helper pending jobs: $e');
      // Fallback: return empty list instead of throwing exception
      print('🔄 Using fallback: returning empty list');
      return [];
    }
  }

  /// Get a single job's details by ID
  Future<Map<String, dynamic>?> getJobDetailsById(String jobId) async {
    try {
      final response = await _supabase.from('jobs').select('''
            id, title, description, hourly_rate, scheduled_date, scheduled_time, 
            location_address, status, created_at,
            job_categories(id, name),
            helpee:users!helpee_id(id, first_name, last_name, phone, email),
            helper:users!assigned_helper_id(id, first_name, last_name, phone, email)
          ''').eq('id', jobId).single();

      return response;
    } catch (e) {
      print('❌ Error getting job details: $e');
      return null;
    }
  }
}
