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

  // Check if username is available for specific user type
  Future<bool> isUsernameAvailable(String username, {String? userType}) async {
    try {
      if (userType != null) {
        // Use the new function for user type specific checking
        final result =
            await _client.rpc('check_username_availability', params: {
          'p_username': username,
          'p_user_type': userType,
        });
        return result == true;
      } else {
        // Fallback to old behavior if userType not provided
        final response = await _client
            .from('users')
            .select('id')
            .eq('username', username)
            .maybeSingle();
        return response == null;
      }
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Check if email is available (should be unique across all user types)
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response == null;
    } catch (e) {
      print('Error checking email availability: $e');
      return false;
    }
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

      throw Exception('Failed to create job - no data returned');
    } catch (e) {
      print('Error creating job with questions: $e');
      // Check if it's a notification trigger error
      if (e.toString().contains('notifications')) {
        // If it's a notification error, try to get the job that was created
        try {
          final jobs = await _client
              .from('jobs')
              .select('*, job_categories(*)')
              .eq('helpee_id', helpeeId)
              .eq('title', title)
              .order('created_at', ascending: false)
              .limit(1);

          if (jobs.isNotEmpty) {
            print('✅ Found created job despite notification error');
            return jobs[0];
          }
        } catch (innerError) {
          print('Error retrieving created job: $innerError');
        }
      }
      throw Exception('Failed to create job - $e');
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

  // Enhanced private job creation with helper assignment
  Future<Map<String, dynamic>?> createPrivateJobWithHelperAssignment({
    required String helpeeId,
    required String categoryId,
    required String jobCategoryName,
    required String title,
    required String description,
    required double hourlyRate,
    required String scheduledDate,
    required String scheduledStartTime,
    required double locationLatitude,
    required double locationLongitude,
    required String locationAddress,
    required List<Map<String, dynamic>> questionAnswers,
    required Map<String, dynamic> selectedHelper,
    String? specialInstructions,
  }) async {
    try {
      // Create job with helper assignment
      final jobData = {
        'helpee_id': helpeeId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'job_type': 'private',
        'status': 'pending',
        'hourly_rate': hourlyRate,
        'scheduled_date': scheduledDate,
        'scheduled_start_time': scheduledStartTime,
        'location_latitude': locationLatitude,
        'location_longitude': locationLongitude,
        'location_address': locationAddress,
        'special_instructions': specialInstructions,
        // Helper assignment
        'assigned_helper_id': selectedHelper['id'],
        'invited_helper_email': selectedHelper['email'],
        'assigned_helper_email': selectedHelper['email'],
        'helper_selection_method': 'search',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _client.from('jobs').insert(jobData).select().single();

      if (response != null) {
        final jobId = response['id'];

        // Insert question answers
        if (questionAnswers.isNotEmpty) {
          await _questionsService.saveJobAnswers(
            jobId: jobId,
            answers: questionAnswers,
          );
        }

        // Create notification for assigned helper
        await _createPrivateJobNotification(
          helperId: selectedHelper['id'],
          jobId: jobId,
          jobTitle: title,
          helpeeId: helpeeId,
        );

        return response;
      }
      return null;
    } catch (e) {
      print('❌ Error creating private job with helper assignment: $e');
      return null;
    }
  }

  Future<void> _createPrivateJobNotification({
    required String helperId,
    required String jobId,
    required String jobTitle,
    required String helpeeId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': helperId,
        'title': 'New Private Job Request',
        'message': 'You have been invited to a private job: $jobTitle',
        'notification_type': 'private_job_request',
        'related_job_id': jobId,
        'related_user_id': helpeeId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error creating private job notification: $e');
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

  // =============================================
  // FIREBASE NOTIFICATION METHODS
  // =============================================

  /// Update user's FCM token
  Future<void> updateUserFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _client.from('users').update({
        'fcm_token': fcmToken,
        'last_fcm_update': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ FCM token updated for user: $userId');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      throw Exception('Failed to update FCM token');
    }
  }

  /// Get user's FCM token
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('fcm_token')
          .eq('id', userId)
          .single();

      return response['fcm_token'] as String?;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get user notification preferences
  Future<Map<String, dynamic>?> getUserNotificationPreferences(
      String userId) async {
    try {
      final response = await _client
          .from('user_notification_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error getting notification preferences: $e');
      return null;
    }
  }

  /// Update user notification preferences
  Future<void> updateUserNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final data = {
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
        ...preferences,
      };

      await _client.from('user_notification_preferences').upsert(data);

      print('✅ Notification preferences updated for user: $userId');
    } catch (e) {
      print('❌ Error updating notification preferences: $e');
      throw Exception('Failed to update notification preferences');
    }
  }

  /// Get notification template by key and language
  Future<Map<String, dynamic>?> getNotificationTemplate({
    required String templateKey,
    required String languageCode,
  }) async {
    try {
      final response = await _client
          .from('notification_templates')
          .select('*')
          .eq('template_key', templateKey)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        // Return localized title and body based on language
        final title = response['title_$languageCode'] ?? response['title_en'];
        final body = response['body_$languageCode'] ?? response['body_en'];

        return {
          'title': title,
          'body': body,
          'notification_type': response['notification_type'],
        };
      }

      return null;
    } catch (e) {
      print('❌ Error getting notification template: $e');
      return null;
    }
  }

  /// Log notification to history
  Future<String?> logNotificationHistory({
    required String userId,
    String? notificationId,
    required String title,
    required String body,
    required String notificationType,
    String? firebaseMessageId,
    String deviceType = 'unknown',
    String appVersion = '1.0.0',
  }) async {
    try {
      final response = await _client
          .from('notification_history')
          .insert({
            'user_id': userId,
            'notification_id': notificationId,
            'title': title,
            'body': body,
            'notification_type': notificationType,
            'firebase_message_id': firebaseMessageId,
            'device_type': deviceType,
            'app_version': appVersion,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('❌ Error logging notification history: $e');
      return null;
    }
  }
}
