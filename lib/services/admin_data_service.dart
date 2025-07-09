import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_auth_service.dart';

class AdminDataService {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  final _supabase = Supabase.instance.client;
  final _adminAuth = AdminAuthService();

  // ============================================================================
  // JOB MANAGEMENT OPERATIONS
  // ============================================================================

  /// Get all jobs with helper and helpee information
  Future<List<Map<String, dynamic>>> getAllJobs() async {
    await _logAdminAction('view', 'job', actionDetails: {
      'query_type': 'all_jobs',
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      final response = await Supabase.instance.client.from('jobs').select('''
            *,
            helpee:helpee_id(id, first_name, last_name, email, phone),
            helper:assigned_helper_id(id, first_name, last_name, email, phone)
          ''').order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting all jobs: $e');
      return [];
    }
  }

  /// Get jobs filtered by status
  Future<List<Map<String, dynamic>>> getJobsByStatus(String status) async {
    await _logAdminAction('view', 'job', actionDetails: {
      'query_type': 'jobs_by_status',
      'filter_status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      // Handle special cases for status filtering
      String queryStatus = status;
      if (status == 'all') {
        final response = await getAllJobs();
        return response;
      }

      final response = await Supabase.instance.client.from('jobs').select('''
            *,
            helpee:helpee_id(id, first_name, last_name, email, phone),
            helper:assigned_helper_id(id, first_name, last_name, email, phone)
          ''').eq('status', queryStatus).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting jobs by status: $e');
      return [];
    }
  }

  /// Update job status (admin override)
  Future<void> updateJobStatus(String jobId, String newStatus) async {
    try {
      // Get current job data for audit log
      final currentJob = await _supabase
          .from('jobs')
          .select('status, title')
          .eq('id', jobId)
          .single();

      // Update job status
      await _supabase.from('jobs').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Log admin action
      await _logAdminAction(
        'update',
        'job',
        entityId: jobId,
        entityName: currentJob['title'],
        oldValues: {'status': currentJob['status']},
        newValues: {'status': newStatus},
      );

      print('✅ Job status updated successfully: $jobId -> $newStatus');
    } catch (e) {
      print('❌ Error updating job status: $e');
      rethrow;
    }
  }

  /// Delete job (admin only)
  Future<void> deleteJob(String jobId) async {
    try {
      // Get job data for audit log
      final job = await _supabase
          .from('jobs')
          .select('title, status, helpee_id, assigned_helper_id')
          .eq('id', jobId)
          .single();

      // Delete the job
      await _supabase.from('jobs').delete().eq('id', jobId);

      // Log admin action
      await _logAdminAction(
        'delete',
        'job',
        entityId: jobId,
        entityName: job['title'],
        actionDetails: {
          'deleted_job': job,
          'reason': 'admin_deletion',
        },
      );

      print('✅ Job deleted successfully: $jobId');
    } catch (e) {
      print('❌ Error deleting job: $e');
      rethrow;
    }
  }

  /// Get job statistics
  Future<Map<String, dynamic>> getJobStatistics() async {
    try {
      await _logAdminAction('view', 'system', actionDetails: {
        'operation': 'get_job_statistics',
      });

      final response = await _supabase.rpc('get_admin_dashboard_stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting job statistics: $e');
      rethrow;
    }
  }

  // ============================================================================
  // USER MANAGEMENT OPERATIONS
  // ============================================================================

  /// Get all users with filters
  Future<List<Map<String, dynamic>>> getAllUsers({
    String? userType,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      await _logAdminAction('view', 'user', actionDetails: {
        'operation': 'get_all_users',
        'filters': {
          'user_type': userType,
          'is_active': isActive,
          'limit': limit,
        },
      });

      var queryBuilder = _supabase.from('users').select('*');

      if (userType != null) {
        queryBuilder = queryBuilder.eq('user_type', userType);
      }

      if (isActive != null) {
        queryBuilder = queryBuilder.eq('is_active', isActive);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting all users: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      await _logAdminAction('view', 'user', entityId: userId);

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      rethrow;
    }
  }

  /// Update user status (activate/deactivate)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      // Get current user data
      final currentUser = await _supabase
          .from('users')
          .select('is_active, full_name, email')
          .eq('id', userId)
          .single();

      // Update user status
      await _supabase.from('users').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Log admin action
      await _logAdminAction(
        'update',
        'user',
        entityId: userId,
        entityName: currentUser['full_name'],
        oldValues: {'is_active': currentUser['is_active']},
        newValues: {'is_active': isActive},
      );

      print('✅ User status updated: $userId -> active: $isActive');
    } catch (e) {
      print('❌ Error updating user status: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      await _logAdminAction('view', 'system', actionDetails: {
        'operation': 'get_user_statistics',
      });

      final response =
          await _supabase.from('system_overview_stats').select('*').single();

      return response;
    } catch (e) {
      print('❌ Error getting user statistics: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CATEGORY MANAGEMENT OPERATIONS
  // ============================================================================

  /// Get all job categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      await _logAdminAction('view', 'category', actionDetails: {
        'operation': 'get_all_categories',
      });

      final response = await _supabase
          .from('job_categories')
          .select('*')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting categories: $e');
      rethrow;
    }
  }

  /// Create new job category
  Future<Map<String, dynamic>> createCategory(
    String name,
    String description,
  ) async {
    try {
      final response = await _supabase
          .from('job_categories')
          .insert({
            'name': name,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Log admin action
      await _logAdminAction(
        'create',
        'category',
        entityId: response['id'],
        entityName: name,
        newValues: {'name': name, 'description': description},
      );

      print('✅ Category created: $name');
      return response;
    } catch (e) {
      print('❌ Error creating category: $e');
      rethrow;
    }
  }

  /// Update job category
  Future<void> updateCategory(
    String categoryId,
    String name,
    String description,
  ) async {
    try {
      // Get current category data
      final currentCategory = await _supabase
          .from('job_categories')
          .select('name, description')
          .eq('id', categoryId)
          .single();

      // Update category
      await _supabase.from('job_categories').update({
        'name': name,
        'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', categoryId);

      // Log admin action
      await _logAdminAction(
        'update',
        'category',
        entityId: categoryId,
        entityName: name,
        oldValues: currentCategory,
        newValues: {'name': name, 'description': description},
      );

      print('✅ Category updated: $categoryId');
    } catch (e) {
      print('❌ Error updating category: $e');
      rethrow;
    }
  }

  /// Delete job category
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Get category data for audit log
      final category = await _supabase
          .from('job_categories')
          .select('name, description')
          .eq('id', categoryId)
          .single();

      // Check if category is being used by any jobs
      final jobsUsingCategory = await _supabase
          .from('jobs')
          .select('id')
          .eq('category_id', categoryId)
          .limit(1);

      if (jobsUsingCategory.isNotEmpty) {
        throw Exception(
            'Cannot delete category: it is being used by existing jobs');
      }

      // Delete category
      await _supabase.from('job_categories').delete().eq('id', categoryId);

      // Log admin action
      await _logAdminAction(
        'delete',
        'category',
        entityId: categoryId,
        entityName: category['name'],
        actionDetails: {'deleted_category': category},
      );

      print('✅ Category deleted: $categoryId');
    } catch (e) {
      print('❌ Error deleting category: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ANALYTICS OPERATIONS
  // ============================================================================

  /// Get daily job statistics
  Future<List<Map<String, dynamic>>> getDailyJobStats({
    int days = 30,
  }) async {
    try {
      await _logAdminAction('view', 'analytics', actionDetails: {
        'operation': 'get_daily_job_stats',
        'days': days,
      });

      final response = await _supabase
          .from('daily_job_stats')
          .select('*')
          .order('job_date', ascending: false)
          .limit(days);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting daily job stats: $e');
      rethrow;
    }
  }

  /// Get category performance statistics
  Future<List<Map<String, dynamic>>> getCategoryPerformanceStats() async {
    try {
      await _logAdminAction('view', 'analytics', actionDetails: {
        'operation': 'get_category_performance_stats',
      });

      final response = await _supabase
          .from('category_performance_stats')
          .select('*')
          .order('total_jobs', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting category performance stats: $e');
      rethrow;
    }
  }

  /// Get user registration statistics
  Future<List<Map<String, dynamic>>> getUserRegistrationStats({
    int days = 30,
  }) async {
    try {
      await _logAdminAction('view', 'analytics', actionDetails: {
        'operation': 'get_user_registration_stats',
        'days': days,
      });

      final response = await _supabase
          .from('user_registration_stats')
          .select('*')
          .order('registration_date', ascending: false)
          .limit(days);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting user registration stats: $e');
      rethrow;
    }
  }

  /// Get recent admin activity
  Future<List<Map<String, dynamic>>> getRecentAdminActivity({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('recent_admin_activity')
          .select('*')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting recent admin activity: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SYSTEM MANAGEMENT OPERATIONS
  // ============================================================================

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      await _logAdminAction('view', 'system', actionDetails: {
        'operation': 'get_system_health',
      });

      // Get basic system metrics
      final stats = await _supabase.rpc('get_admin_dashboard_stats');

      // Add additional health metrics
      final health = {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': stats,
        'database_status': 'connected',
        'api_status': 'operational',
      };

      return health;
    } catch (e) {
      print('❌ Error getting system health: $e');
      return {
        'status': 'error',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Export data for reporting
  Future<Map<String, dynamic>> exportSystemData({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? dataTypes,
  }) async {
    try {
      await _logAdminAction('export', 'system', actionDetails: {
        'operation': 'export_system_data',
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'data_types': dataTypes,
      });

      final exportData = <String, dynamic>{};

      // Export jobs data
      if (dataTypes == null || dataTypes.contains('jobs')) {
        exportData['jobs'] = await getAllJobs();
      }

      // Export users data
      if (dataTypes == null || dataTypes.contains('users')) {
        exportData['users'] = await getAllUsers(limit: 1000);
      }

      // Export analytics data
      if (dataTypes == null || dataTypes.contains('analytics')) {
        exportData['daily_stats'] = await getDailyJobStats(days: 90);
        exportData['category_stats'] = await getCategoryPerformanceStats();
      }

      exportData['export_metadata'] = {
        'generated_at': DateTime.now().toIso8601String(),
        'generated_by': _adminAuth.currentAdminUsername,
        'total_records': exportData.values
            .where((data) => data is List)
            .fold<int>(0, (sum, list) => sum + (list as List).length),
      };

      return exportData;
    } catch (e) {
      print('❌ Error exporting system data: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Format jobs response with proper field mapping
  List<Map<String, dynamic>> _formatJobsResponse(List<dynamic> response) {
    return response.map((job) {
      final jobMap = Map<String, dynamic>.from(job);

      // Add formatted helpee/helper names
      if (jobMap['helpee'] != null) {
        jobMap['helpee_name'] = jobMap['helpee']['full_name'];
        jobMap['helpee_email'] = jobMap['helpee']['email'];
      }

      if (jobMap['helper'] != null) {
        jobMap['helper_name'] = jobMap['helper']['full_name'];
        jobMap['helper_email'] = jobMap['helper']['email'];
      }

      if (jobMap['category'] != null) {
        jobMap['category_name'] = jobMap['category']['name'];
      }

      return jobMap;
    }).toList();
  }

  /// Log admin action for audit trail
  Future<void> _logAdminAction(
    String actionType,
    String entityType, {
    String? entityId,
    String? entityName,
    Map<String, dynamic>? actionDetails,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      if (_adminAuth.isLoggedIn) {
        await _adminAuth.logAction(
          actionType,
          entityType,
          entityId: entityId,
          entityName: entityName,
          actionDetails: actionDetails,
          oldValues: oldValues,
          newValues: newValues,
        );
      }
    } catch (e) {
      print('⚠️ Warning: Failed to log admin action: $e');
      // Don't throw here to avoid breaking the main operation
    }
  }
}
