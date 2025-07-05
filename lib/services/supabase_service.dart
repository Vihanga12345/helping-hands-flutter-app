import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';
import 'job_questions_service.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Service instances
  final CustomAuthService _authService = CustomAuthService();
  final JobQuestionsService _questionsService = JobQuestionsService();

  // Flag to determine if we're using mock data
  bool _useMockData = false;

  // Initialize Supabase
  static Future<void> initialize() async {
    // Production Supabase configuration with provided API keys
    const String supabaseUrl = 'https://awdhnscowyibbbvoysfa.supabase.co';
    const String supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3ZGhuc2Nvd3lpYmJidm95c2ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NjQ3ODUsImV4cCI6MjA2NjM0MDc4NX0.2gsbjyjj82Fb6bT89XpJdlxzRwHTfu0Lw_rXwpB565g';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // Initialize custom authentication
    await CustomAuthService().initialize();

    // Initialize job questions service
    await JobQuestionsService().initialize();

    // Always use real database - no mock data fallback
    SupabaseService()._useMockData = false;
    print('✅ SupabaseService connected to production database');
  }

  // =============================================================================
  // AUTHENTICATION METHODS (Delegated to CustomAuthService)
  // =============================================================================

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String userType,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    return await _authService.register(
      username: username,
      email: email,
      password: password,
      userType: userType,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  /// Login user
  Future<Map<String, dynamic>> loginUser({
    required String usernameOrEmail,
    required String password,
    required String userType,
  }) async {
    return await _authService.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
      userType: userType,
    );
  }

  /// Logout current user
  Future<void> logoutUser() async {
    await _authService.logout();
  }

  /// Get current user
  Map<String, dynamic>? get currentUser => _authService.currentUser;
  String? get currentUserType => _authService.currentUserType;
  String? get currentUserId => _authService.currentUserId;
  String? get currentUsername => _authService.currentUsername;
  bool get isLoggedIn => _authService.isLoggedIn;

  /// Check username availability
  Future<bool> isUsernameAvailable(String username) async {
    return await _authService.isUsernameAvailable(username);
  }

  /// Check email availability
  Future<bool> isEmailAvailable(String email) async {
    return await _authService.isEmailAvailable(email);
  }

  // =============================================================================
  // USER MANAGEMENT
  // =============================================================================

  // Create user profile (Updated to use custom auth)
  Future<Map<String, dynamic>?> createUserProfile({
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String userType,
    String? dateOfBirth,
    String? gender,
    String? aboutMe,
    String? locationAddress,
    String? locationCity,
    String? locationDistrict,
    double? locationLatitude,
    double? locationLongitude,
  }) async {
    try {
      final response = await _client
          .from('users')
          .insert({
            'email': email,
            'phone': phone,
            'first_name': firstName,
            'last_name': lastName,
            'user_type': userType,
            'date_of_birth': dateOfBirth,
            'gender': gender,
            'about_me': aboutMe,
            'location_address': locationAddress,
            'location_city': locationCity,
            'location_district': locationDistrict,
            'location_latitude': locationLatitude,
            'location_longitude': locationLongitude,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _client.from('users').update(updates).eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get user skills (for helpers)
  Future<List<Map<String, dynamic>>> getUserSkills(String userId) async {
    try {
      final response = await _client
          .from('user_skills')
          .select('*, job_categories(*)')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user skills: $e');
      return [];
    }
  }

  // Add/Update user skill
  Future<bool> upsertUserSkill({
    required String userId,
    required String categoryId,
    required int experienceYears,
    required String skillLevel,
    required double hourlyRate,
  }) async {
    try {
      await _client.from('user_skills').upsert({
        'user_id': userId,
        'category_id': categoryId,
        'experience_years': experienceYears,
        'skill_level': skillLevel,
        'hourly_rate': hourlyRate,
      });

      return true;
    } catch (e) {
      print('Error upserting user skill: $e');
      return false;
    }
  }

  // =============================================================================
  // JOB MANAGEMENT (Enhanced with Questions)
  // =============================================================================

  // Get job categories
  Future<List<Map<String, dynamic>>> getJobCategories() async {
    try {
      // Delegate to JobQuestionsService which handles mock data
      return await _questionsService.getJobCategories();
    } catch (e) {
      print('Error getting job categories: $e');
      return [];
    }
  }

  // Get questions for job category
  Future<List<Map<String, dynamic>>> getJobCategoryQuestions(
      String categoryId) async {
    return await _questionsService.getQuestionsForCategory(categoryId);
  }

  // Get questions by category name
  Future<List<Map<String, dynamic>>> getQuestionsByCategoryName(
      String categoryName) async {
    return await _questionsService.getQuestionsByCategoryName(categoryName);
  }

  // Create job with questions (Enhanced)
  Future<Map<String, dynamic>?> createJobWithQuestions({
    required String helpeeId,
    required String categoryId,
    required String jobCategoryName,
    required String title,
    required String description,
    required String jobType,
    required double hourlyRate,
    required String scheduledDate,
    required String scheduledStartTime,
    required double locationLatitude,
    required double locationLongitude,
    required String locationAddress,
    required List<Map<String, dynamic>> questionAnswers,
    String? assignedHelperId,
    String? invitedHelperEmail,
    String? specialInstructions,
    double? estimatedHours,
    String? scheduledEndTime,
    String? locationType,
    String? paymentMethod,
    bool? requiresOwnSupplies,
    bool? petFriendlyRequired,
  }) async {
    try {
      if (_useMockData) {
        // Create job in mock data
        final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
        final job = {
          'id': jobId,
          'helpee_id': helpeeId,
          'category_id': categoryId,
          'title': title,
          'description': description,
          'job_type': jobType,
          'hourly_rate': hourlyRate,
          'scheduled_date': scheduledDate,
          'scheduled_start_time': scheduledStartTime,
          'location_latitude': locationLatitude,
          'location_longitude': locationLongitude,
          'location_address': locationAddress,
          'assigned_helper_id': assignedHelperId,
          'invited_helper_email': invitedHelperEmail,
          'special_instructions': specialInstructions,
          'estimated_hours': estimatedHours,
          'scheduled_end_time': scheduledEndTime,
          'location_type': locationType,
          'payment_method': paymentMethod ?? 'cash',
          'requires_own_supplies': requiresOwnSupplies ?? false,
          'pet_friendly_required': petFriendlyRequired ?? false,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Save question answers
        if (questionAnswers.isNotEmpty) {
          await _questionsService.saveJobAnswers(
            jobId: jobId,
            answers: questionAnswers,
          );
        }

        print('✅ Job created successfully in mock data: $title');
        return job;
      }

      // Create job using stored function with helpee details
      print('🔧 Creating job with category ID: $categoryId');
      print('🔧 Job category name: $jobCategoryName');
      print('🔧 Job type: $jobType');

      final jobId =
          await _client.rpc('create_job_with_helpee_details', params: {
        'p_helpee_id': helpeeId,
        'p_category_id': categoryId,
        'p_job_category_name': jobCategoryName,
        'p_title': title,
        'p_description': description,
        'p_job_type': jobType,
        'p_hourly_rate': hourlyRate,
        'p_scheduled_date': scheduledDate,
        'p_scheduled_start_time': scheduledStartTime,
        'p_location_latitude': locationLatitude,
        'p_location_longitude': locationLongitude,
        'p_location_address': locationAddress,
      });

      print('🔧 Created job with ID: $jobId');

      if (jobId != null) {
        // Update job with additional details
        await _client.from('jobs').update({
          'assigned_helper_id': assignedHelperId,
          'invited_helper_email': invitedHelperEmail,
          'special_instructions': specialInstructions,
          'estimated_hours': estimatedHours,
          'scheduled_end_time': scheduledEndTime,
          'location_type': locationType,
          'payment_method': paymentMethod ?? 'cash',
          'requires_own_supplies': requiresOwnSupplies ?? false,
          'pet_friendly_required': petFriendlyRequired ?? false,
        }).eq('id', jobId);

        // Save question answers
        if (questionAnswers.isNotEmpty) {
          await _questionsService.saveJobAnswers(
            jobId: jobId,
            answers: questionAnswers,
          );
        }

        // Get the created job with all details
        final jobDetails = await _client
            .from('jobs')
            .select('*, job_categories(*)')
            .eq('id', jobId)
            .single();

        return jobDetails;
      }

      return null;
    } catch (e) {
      print('Error creating job with questions: $e');
      return null;
    }
  }

  // Create job (Original method - maintained for compatibility)
  Future<Map<String, dynamic>?> createJob({
    required String helpeeId,
    required String categoryId,
    required String title,
    required String description,
    required String jobType,
    required double hourlyRate,
    required String scheduledDate,
    required String scheduledStartTime,
    required double locationLatitude,
    required double locationLongitude,
    required String locationAddress,
    String? assignedHelperId,
    String? invitedHelperEmail, // For private job targeting
    String? specialInstructions,
    double? estimatedHours,
    String? scheduledEndTime,
    String? locationType,
    String? paymentMethod,
    bool? requiresOwnSupplies,
    bool? petFriendlyRequired,
  }) async {
    try {
      // Look up the category name from the categoryId
      final categoryResponse = await _client
          .from('job_categories')
          .select('name')
          .eq('id', categoryId)
          .single();

      final jobCategoryName = categoryResponse['name'] ?? 'Unknown';

      return await createJobWithQuestions(
        helpeeId: helpeeId,
        categoryId: categoryId,
        jobCategoryName: jobCategoryName,
        title: title,
        description: description,
        jobType: jobType,
        hourlyRate: hourlyRate,
        scheduledDate: scheduledDate,
        scheduledStartTime: scheduledStartTime,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        locationAddress: locationAddress,
        questionAnswers: [], // Empty answers for compatibility
        assignedHelperId: assignedHelperId,
        invitedHelperEmail: invitedHelperEmail,
        specialInstructions: specialInstructions,
        estimatedHours: estimatedHours,
        scheduledEndTime: scheduledEndTime,
        locationType: locationType,
        paymentMethod: paymentMethod,
        requiresOwnSupplies: requiresOwnSupplies,
        petFriendlyRequired: petFriendlyRequired,
      );
    } catch (e) {
      print('Error in createJob compatibility method: $e');
      return null;
    }
  }

  // Get job answers for helpers to view
  Future<List<Map<String, dynamic>>> getJobAnswers(String jobId) async {
    return await _questionsService.getFormattedJobAnswers(jobId);
  }

  // Get jobs by helpee (Enhanced with helpee details)
  Future<List<Map<String, dynamic>>> getJobsByHelpee(String helpeeId) async {
    try {
      final response = await _client
          .from('jobs')
          .select('*, job_categories(*), users!assigned_helper_id(*)')
          .eq('helpee_id', helpeeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting jobs by helpee: $e');
      return [];
    }
  }

  // Get jobs by helper (Enhanced with helper details)
  Future<List<Map<String, dynamic>>> getJobsByHelper(String helperId) async {
    try {
      final response = await _client
          .from('jobs')
          .select('*, job_categories(*), users!helpee_id(*)')
          .eq('assigned_helper_id', helperId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting jobs by helper: $e');
      return [];
    }
  }

  // Get public jobs (Enhanced with user details)
  Future<List<Map<String, dynamic>>> getPublicJobs(
      {String? categoryId, String? status}) async {
    try {
      var query = _client
          .from('jobs')
          .select('*, job_categories(*), users!helpee_id(*)')
          .eq('job_type', 'public');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.eq('status', 'pending'); // Default to pending jobs
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting public jobs: $e');
      return [];
    }
  }

  // Update job status
  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      await _client.from('jobs').update({'status': status}).eq('id', jobId);

      return true;
    } catch (e) {
      print('Error updating job status: $e');
      return false;
    }
  }

  // Accept job (Enhanced with helper assignment function)
  Future<bool> acceptJob(String jobId, String helperId) async {
    try {
      final result = await _client.rpc('assign_helper_to_job', params: {
        'p_job_id': jobId,
        'p_helper_id': helperId,
      });

      return result == true;
    } catch (e) {
      print('Error accepting job: $e');
      return false;
    }
  }

  // Reject job (for helpers)
  Future<bool> rejectJob(String jobId, String helperId) async {
    try {
      await _client
          .from('jobs')
          .update({'status': 'cancelled'}).eq('id', jobId);

      return true;
    } catch (e) {
      print('Error rejecting job: $e');
      return false;
    }
  }

  // Get private jobs for specific helper (Enhanced)
  Future<List<Map<String, dynamic>>> getPrivateJobsForHelper(
      String helperEmail) async {
    try {
      final response = await _client
          .from('jobs')
          .select('*, job_categories(*), users!helpee_id(*)')
          .eq('job_type', 'private')
          .eq('invited_helper_email', helperEmail)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting private jobs for helper: $e');
      return [];
    }
  }

  // Get jobs with enhanced details (helpee and helper names)
  Future<List<Map<String, dynamic>>> getJobsWithDetails({
    String? helpeeId,
    String? helperId,
    String? status,
    String? jobType,
  }) async {
    try {
      var query = _client.from('jobs').select('''
            *, 
            job_categories(*),
            users!helpee_id(id, first_name, last_name, username, display_name, profile_image_url),
            assigned_helper:users!assigned_helper_id(id, first_name, last_name, username, display_name, profile_image_url)
          ''');

      if (helpeeId != null) {
        query = query.eq('helpee_id', helpeeId);
      }
      if (helperId != null) {
        query = query.eq('assigned_helper_id', helperId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (jobType != null) {
        query = query.eq('job_type', jobType);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting jobs with details: $e');
      return [];
    }
  }

  // =============================================================================
  // JOB TIMER FUNCTIONALITY
  // =============================================================================

  // Start job timer
  Future<bool> startJobTimer(String jobId, String helperId) async {
    try {
      // Update job status and timer state
      await _client.from('jobs').update({
        'status': 'started',
        'is_timer_running': true,
        'timer_start_time': DateTime.now().toIso8601String(),
        'actual_start_time': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Create new timer session
      await _client.from('job_timer_sessions').insert({
        'job_id': jobId,
        'helper_id': helperId,
        'session_start_time': DateTime.now().toIso8601String(),
        'session_type': 'work',
      });

      return true;
    } catch (e) {
      print('Error starting job timer: $e');
      return false;
    }
  }

  // Pause job timer
  Future<bool> pauseJobTimer(String jobId) async {
    try {
      // Get current timer session
      final currentSession = await _client
          .from('job_timer_sessions')
          .select()
          .eq('job_id', jobId)
          .isFilter('session_end_time', null)
          .single();

      if (currentSession != null) {
        final startTime = DateTime.parse(currentSession['session_start_time']);
        final endTime = DateTime.now();
        final durationMinutes = endTime.difference(startTime).inMinutes;

        // End current session
        await _client.from('job_timer_sessions').update({
          'session_end_time': endTime.toIso8601String(),
          'duration_minutes': durationMinutes,
        }).eq('id', currentSession['id']);

        // Update job timer state
        await _client.from('jobs').update({
          'status': 'paused',
          'is_timer_running': false,
          'timer_paused_time': endTime.toIso8601String(),
        }).eq('id', jobId);
      }

      return true;
    } catch (e) {
      print('Error pausing job timer: $e');
      return false;
    }
  }

  // Resume job timer
  Future<bool> resumeJobTimer(String jobId, String helperId) async {
    try {
      // Update job timer state
      await _client.from('jobs').update({
        'status': 'started',
        'is_timer_running': true,
        'timer_start_time': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Create new timer session
      await _client.from('job_timer_sessions').insert({
        'job_id': jobId,
        'helper_id': helperId,
        'session_start_time': DateTime.now().toIso8601String(),
        'session_type': 'work',
      });

      return true;
    } catch (e) {
      print('Error resuming job timer: $e');
      return false;
    }
  }

  // Complete job
  Future<bool> completeJob(String jobId) async {
    try {
      // End current timer session if running
      final currentSession = await _client
          .from('job_timer_sessions')
          .select()
          .eq('job_id', jobId)
          .isFilter('session_end_time', null)
          .maybeSingle();

      if (currentSession != null) {
        final startTime = DateTime.parse(currentSession['session_start_time']);
        final endTime = DateTime.now();
        final durationMinutes = endTime.difference(startTime).inMinutes;

        await _client.from('job_timer_sessions').update({
          'session_end_time': endTime.toIso8601String(),
          'duration_minutes': durationMinutes,
        }).eq('id', currentSession['id']);
      }

      // Calculate total work time
      final sessions = await _client
          .from('job_timer_sessions')
          .select('duration_minutes')
          .eq('job_id', jobId)
          .eq('session_type', 'work')
          .not('duration_minutes', 'is', null);

      int totalMinutes = 0;
      for (var session in sessions) {
        totalMinutes += (session['duration_minutes'] ?? 0) as int;
      }

      // Get job details for price calculation
      final jobDetails = await _client
          .from('jobs')
          .select('hourly_rate')
          .eq('id', jobId)
          .single();

      double hourlyRate = (jobDetails['hourly_rate'] ?? 0.0).toDouble();
      double totalHours = totalMinutes / 60.0;
      double calculatedPrice = hourlyRate * totalHours;

      // Update job as completed with calculated price
      await _client.from('jobs').update({
        'status': 'completed',
        'is_timer_running': false,
        'actual_end_time': DateTime.now().toIso8601String(),
        'total_work_time_minutes': totalMinutes,
        'price_calculated': calculatedPrice,
        'payment_requested_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      return true;
    } catch (e) {
      print('Error completing job: $e');
      return false;
    }
  }

  // Get job timer sessions
  Future<List<Map<String, dynamic>>> getJobTimerSessions(String jobId) async {
    try {
      final response = await _client
          .from('job_timer_sessions')
          .select()
          .eq('job_id', jobId)
          .order('session_start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting timer sessions: $e');
      return [];
    }
  }

  // =============================================================================
  // RATING AND REVIEW SYSTEM
  // =============================================================================

  // Create rating and review with job rating status update
  Future<bool> createRating({
    required String jobId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String reviewType,
    String? reviewText,
  }) async {
    try {
      // Insert rating
      await _client.from('ratings_reviews').insert({
        'job_id': jobId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'review_text': reviewText,
        'review_type': reviewType,
      });

      // Update job rating status
      Map<String, dynamic> updates = {};
      if (reviewType == 'helpee_to_helper') {
        updates['is_rated_by_helpee'] = true;
      } else if (reviewType == 'helper_to_helpee') {
        updates['is_rated_by_helper'] = true;
      }

      if (updates.isNotEmpty) {
        await _client.from('jobs').update(updates).eq('id', jobId);
      }

      return true;
    } catch (e) {
      print('Error creating rating: $e');
      return false;
    }
  }

  // Check if job needs rating from user
  Future<bool> doesJobNeedRating(
      String jobId, String userId, String userType) async {
    try {
      final job = await _client
          .from('jobs')
          .select(
              'is_rated_by_helpee, is_rated_by_helper, helpee_id, assigned_helper_id')
          .eq('id', jobId)
          .single();

      if (userType == 'helpee' && job['helpee_id'] == userId) {
        return !(job['is_rated_by_helpee'] ?? false);
      } else if (userType == 'helper' && job['assigned_helper_id'] == userId) {
        return !(job['is_rated_by_helper'] ?? false);
      }

      return false;
    } catch (e) {
      print('Error checking rating status: $e');
      return false;
    }
  }

  // Get ratings for user
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final response = await _client
          .from('ratings_reviews')
          .select('*, jobs(*), users!reviewer_id(*)')
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user ratings: $e');
      return [];
    }
  }

  // Get average rating for user
  Future<double> getUserAverageRating(String userId) async {
    try {
      final response = await _client
          .from('ratings_reviews')
          .select('rating')
          .eq('reviewee_id', userId);

      if (response.isEmpty) return 0.0;

      double sum = 0;
      for (var rating in response) {
        sum += (rating['rating'] as int).toDouble();
      }

      return sum / response.length;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  // =============================================================================
  // NOTIFICATIONS
  // =============================================================================

  // Create notification
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String notificationType,
    String? relatedJobId,
    String? relatedUserId,
    String? actionUrl,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'notification_type': notificationType,
        'related_job_id': relatedJobId,
        'related_user_id': relatedUserId,
        'action_url': actionUrl,
      });

      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String()
      }).eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // =============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // =============================================================================

  // Subscribe to job status changes
  RealtimeChannel subscribeToJobUpdates(
      String jobId, Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('job_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: jobId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Subscribe to user notifications
  RealtimeChannel subscribeToNotifications(
      String userId, Function(Map<String, dynamic>) onNotification) {
    return _client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }
}
