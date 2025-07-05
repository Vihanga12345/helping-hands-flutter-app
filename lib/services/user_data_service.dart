import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';

class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get current user's complete profile data
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      // Get current user from auth service
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return null;
      }

      // Get additional profile data from users table
      final userProfile = await _supabase
          .from('users')
          .select('*')
          .eq('id', currentUser['user_id'])
          .single();

      // Merge auth data with profile data
      return {
        ...currentUser,
        ...userProfile,
      };
    } catch (e) {
      print('❌ Error getting current user profile: $e');
      // Return auth service data as fallback
      return _authService.currentUser;
    }
  }

  /// Get user statistics (job counts, ratings, reviews) for helpees
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final stats = await _supabase
          .from('helpee_statistics')
          .select('*')
          .eq('helpee_id', userId)
          .maybeSingle();

      if (stats != null) {
        return {
          'total_jobs': stats['total_jobs'] ?? 0,
          'pending_jobs': stats['pending_jobs'] ?? 0,
          'ongoing_jobs': stats['ongoing_jobs'] ?? 0,
          'completed_jobs': stats['completed_jobs'] ?? 0,
          'rating': (stats['average_rating_given'] ?? 0.0).toDouble(),
          'total_reviews': stats['completed_jobs'] ?? 0,
          'member_since': _formatMemberSince(stats['member_since']),
        };
      }

      // Fallback to manual calculation if view doesn't exist
      return await _calculateUserStatisticsManually(userId, 'helpee');
    } catch (e) {
      print('❌ Error getting user statistics: $e');
      return await _calculateUserStatisticsManually(userId, 'helpee');
    }
  }

  /// Get helper statistics
  Future<Map<String, dynamic>> getHelperStatistics(String helperId) async {
    try {
      final stats = await _supabase
          .from('helper_statistics')
          .select('*')
          .eq('helper_id', helperId)
          .maybeSingle();

      if (stats != null) {
        return {
          'total_jobs': stats['total_jobs'] ?? 0,
          'pending_jobs': stats['pending_jobs'] ?? 0,
          'ongoing_jobs': stats['ongoing_jobs'] ?? 0,
          'completed_jobs': stats['completed_jobs'] ?? 0,
          'rating': (stats['average_rating_received'] ?? 0.0).toDouble(),
          'total_reviews': stats['completed_jobs'] ?? 0,
          'member_since': _formatMemberSince(stats['member_since']),
        };
      }

      // Fallback to manual calculation
      return await _calculateUserStatisticsManually(helperId, 'helper');
    } catch (e) {
      print('❌ Error getting helper statistics: $e');
      return await _calculateUserStatisticsManually(helperId, 'helper');
    }
  }

  /// Manual statistics calculation fallback
  Future<Map<String, dynamic>> _calculateUserStatisticsManually(
      String userId, String userType) async {
    try {
      if (userType == 'helper') {
        // For helpers, we need to count:
        // 1. Jobs assigned to them (jobs they've accepted/started/completed)
        // 2. Available job requests (pending jobs they can accept)

        // Get jobs assigned to helper
        final assignedJobs = await _supabase
            .from('jobs')
            .select('status')
            .eq('assigned_helper_id', userId);

        // Get helper's job type preferences
        final helperJobTypesResponse = await _supabase
            .from('helper_job_types')
            .select('job_category_id')
            .eq('helper_id', userId)
            .eq('is_active', true);

        final helperJobCategoryIds = helperJobTypesResponse
            .map((item) => item['job_category_id'])
            .toList();

        // Get available job requests (both public and private) filtered by job type
        final publicJobs = helperJobCategoryIds.isNotEmpty
            ? await _supabase
                .from('jobs')
                .select('status')
                .eq('status', 'pending')
                .eq('is_private', false)
                .filter('assigned_helper_id', 'is', 'null')
                .filter('job_category_id', 'in',
                    '(${helperJobCategoryIds.join(',')})')
            : <Map<String, dynamic>>[];

        final privateJobs = helperJobCategoryIds.isNotEmpty
            ? await _supabase
                .from('jobs')
                .select('status')
                .eq('status', 'pending')
                .eq('is_private', true)
                .eq('assigned_helper_id', userId)
                .filter('job_category_id', 'in',
                    '(${helperJobCategoryIds.join(',')})')
            : <Map<String, dynamic>>[];

        // For helper stats:
        // - pending_jobs = available job requests (public + private pending)
        // - ongoing_jobs = accepted and started jobs
        // - completed_jobs = completed jobs
        int pendingJobs = publicJobs.length + privateJobs.length;
        int ongoingJobs = assignedJobs
            .where((j) => ['accepted', 'started'].contains(j['status']))
            .length;
        int completedJobs =
            assignedJobs.where((j) => j['status'] == 'completed').length;
        int totalJobs = assignedJobs.length;

        return {
          'total_jobs': totalJobs,
          'pending_jobs': pendingJobs,
          'ongoing_jobs': ongoingJobs,
          'completed_jobs': completedJobs,
          'rating': 4.5, // Mock rating
          'total_reviews': totalJobs > 0 ? (totalJobs * 0.8).round() : 0,
          'member_since': 'Dec 2024',
        };
      } else {
        // For helpees, use the existing logic
        final jobs = await _supabase
            .from('jobs')
            .select('status')
            .eq('helpee_id', userId);

        int totalJobs = jobs.length;
        int pendingJobs = jobs.where((j) => j['status'] == 'pending').length;
        int ongoingJobs = jobs
            .where((j) => ['accepted', 'started'].contains(j['status']))
            .length;
        int completedJobs =
            jobs.where((j) => j['status'] == 'completed').length;

        return {
          'total_jobs': totalJobs,
          'pending_jobs': pendingJobs,
          'ongoing_jobs': ongoingJobs,
          'completed_jobs': completedJobs,
          'rating': 4.5, // Mock rating
          'total_reviews': totalJobs > 0 ? (totalJobs * 0.8).round() : 0,
          'member_since': 'Dec 2024',
        };
      }
    } catch (e) {
      print('❌ Error in manual statistics calculation: $e');
      return {
        'total_jobs': 0,
        'pending_jobs': 0,
        'ongoing_jobs': 0,
        'completed_jobs': 0,
        'rating': 0.0,
        'total_reviews': 0,
        'member_since': 'Dec 2024',
      };
    }
  }

  /// Get user's recent activity (last 5 jobs)
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    try {
      final recentJobs = await _supabase
          .from('jobs')
          .select('''
            id, title, status, created_at, scheduled_date,
            job_categories(name),
            users!assigned_helper_id(first_name, last_name)
          ''')
          .eq('helpee_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(recentJobs).map((job) {
        String statusText = _getActivityStatusText(job['status']);
        String timeText = _getActivityTimeText(job);

        return {
          'title': job['title'] ?? 'Unknown Job',
          'subtitle': statusText,
          'time_text': timeText,
          'status': job['status'],
          'icon': _getActivityIcon(job['status']),
          'color': _getActivityColor(job['status']),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting recent activity: $e');
      return [];
    }
  }

  /// Get helper's recent activity
  Future<List<Map<String, dynamic>>> getHelperRecentActivity(
      String helperId) async {
    try {
      final recentJobs = await _supabase
          .from('jobs')
          .select('''
            id, title, status, created_at, scheduled_date,
            job_categories(name),
            users!helpee_id(first_name, last_name)
          ''')
          .eq('assigned_helper_id', helperId)
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(recentJobs).map((job) {
        String statusText = _getActivityStatusText(job['status']);
        String timeText = _getActivityTimeText(job);

        return {
          'title': job['title'] ?? 'Unknown Job',
          'subtitle': statusText,
          'time_text': timeText,
          'status': job['status'],
          'icon': _getActivityIcon(job['status']),
          'color': _getActivityColor(job['status']),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting helper recent activity: $e');
      return [];
    }
  }

  /// Helper methods for formatting data
  String _formatMemberSince(dynamic memberSinceData) {
    try {
      DateTime memberDate;
      if (memberSinceData is String) {
        memberDate = DateTime.parse(memberSinceData);
      } else if (memberSinceData is DateTime) {
        memberDate = memberSinceData;
      } else {
        memberDate = DateTime.now();
      }

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
      return '${months[memberDate.month - 1]} ${memberDate.year}';
    } catch (e) {
      return 'Dec 2024';
    }
  }

  String _getActivityStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending approval';
      case 'accepted':
        return 'Accepted by helper';
      case 'started':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown status';
    }
  }

  String _getActivityTimeText(Map<String, dynamic> job) {
    try {
      if (job['status'] == 'completed') {
        return 'Completed recently';
      } else if (job['scheduled_date'] != null) {
        final scheduledDate = DateTime.parse(job['scheduled_date']);
        final now = DateTime.now();
        final difference = scheduledDate.difference(now).inDays;

        if (difference == 0) {
          return 'Today';
        } else if (difference == 1) {
          return 'Tomorrow';
        } else if (difference > 0) {
          return 'In $difference days';
        } else {
          return '${difference.abs()} days ago';
        }
      } else {
        return 'Date not set';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  String _getActivityIcon(String status) {
    switch (status) {
      case 'pending':
        return 'pending';
      case 'accepted':
      case 'started':
        return 'schedule';
      case 'completed':
        return 'check_circle';
      case 'cancelled':
        return 'cancel';
      default:
        return 'help';
    }
  }

  String _getActivityColor(String status) {
    switch (status) {
      case 'pending':
        return 'warning';
      case 'accepted':
      case 'started':
        return 'warning';
      case 'completed':
        return 'success';
      case 'cancelled':
        return 'error';
      default:
        return 'textSecondary';
    }
  }

  // Add this method to update user profile data
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('📝 Updating user profile for user ID: ${currentUser['user_id']}');

      // Update users table with new profile data
      await _supabase
          .from('users')
          .update(profileData)
          .eq('id', currentUser['user_id']);

      print('✅ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Add method to get registered helpers for search page
  Future<List<Map<String, dynamic>>> getRegisteredHelpers() async {
    try {
      print('🔍 Fetching registered helpers from database...');

      final response = await _supabase.from('users').select('''
            id,
            first_name,
            last_name,
            display_name,
            location_city,
            hourly_rate_default,
            availability_status,
            profile_image_url,
            created_at
          ''').eq('user_type', 'helper').eq('is_active', true);

      print('✅ Found ${response.length} registered helpers');

      // Transform data to include ratings and skills
      List<Map<String, dynamic>> helpers = [];

      for (var helper in response) {
        // Get helper statistics
        final stats = await getHelperStatistics(helper['id']);

        // Get helper skills (if helper_skills table exists)
        List<String> skills = [];
        try {
          final skillsResponse = await _supabase
              .from('helper_skills')
              .select('skill_name')
              .eq('helper_id', helper['id'])
              .eq('is_active', true);

          if (skillsResponse.isNotEmpty) {
            skills =
                skillsResponse.map((s) => s['skill_name'].toString()).toList();
          }
        } catch (e) {
          // Silently handle missing table or other errors
          print('⚠️ No skills found for helper ${helper['id']}: $e');
        }

        // Always provide at least one default skill
        if (skills.isEmpty) {
          skills = ['General Services'];
        }

        helpers.add({
          ...helper,
          'average_rating': stats['average_rating'] ?? 0.0,
          'total_reviews': stats['total_reviews'] ?? 0,
          'total_jobs': stats['total_jobs'] ?? 0,
          'skills': skills,
        });
      }

      return helpers;
    } catch (e) {
      print('❌ Error fetching registered helpers: $e');
      throw Exception('Failed to fetch helpers: $e');
    }
  }

  /// Get notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔔 Fetching notifications for user: ${currentUser['user_id']}');

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', currentUser['user_id'])
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} notifications');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }
}
