import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'custom_auth_service.dart';

class HelperDataService {
  static final HelperDataService _instance = HelperDataService._internal();
  factory HelperDataService() => _instance;
  HelperDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get helper's selected job types
  Future<List<Map<String, dynamic>>> getHelperJobTypes(String helperId) async {
    try {
      print('🔍 Fetching job types for helper: $helperId');

      final response = await _supabase
          .from('helper_job_types')
          .select('''
            id,
            hourly_rate,
            experience_level,
            is_active,
            job_categories(
              id,
              name,
              icon_name,
              default_hourly_rate
            )
          ''')
          .eq('helper_id', helperId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      print('✅ Found ${response.length} job types for helper');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching helper job types: $e');
      return [];
    }
  }

  /// Get helper's uploaded documents
  Future<List<Map<String, dynamic>>> getHelperDocuments(String helperId) async {
    try {
      print('🔍 Fetching documents for helper: $helperId');

      final response = await _supabase
          .from('helper_documents')
          .select('''
            id,
            document_type,
            document_name,
            document_url,
            file_size_bytes,
            file_type,
            verification_status,
            created_at,
            job_categories(name)
          ''')
          .eq('helper_id', helperId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} documents for helper');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching helper documents: $e');
      return [];
    }
  }

  /// Save helper job types during registration
  Future<void> saveHelperJobTypes(
      String helperId, List<String> jobCategoryIds) async {
    try {
      print('💾 Saving job types for helper: $helperId');

      // First, deactivate all existing job types
      await _supabase
          .from('helper_job_types')
          .update({'is_active': false}).eq('helper_id', helperId);

      // Insert new job types
      for (String categoryId in jobCategoryIds) {
        await _supabase.from('helper_job_types').upsert({
          'helper_id': helperId,
          'job_category_id': categoryId,
          'is_active': true,
          'hourly_rate': 2000.00, // Default rate
          'experience_level': 'beginner',
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'helper_id,job_category_id');
      }

      print('✅ Helper job types saved successfully');
    } catch (e) {
      print('❌ Error saving helper job types: $e');
      throw Exception('Failed to save job types: $e');
    }
  }

  /// Upload and save helper document
  Future<String> uploadHelperDocument({
    required String helperId,
    required String documentType,
    required String fileName,
    required List<int> fileBytes,
    String? jobCategoryId,
  }) async {
    try {
      print('📤 Uploading document: $fileName for helper: $helperId');

      // Convert List<int> to Uint8List
      final Uint8List uint8FileBytes = Uint8List.fromList(fileBytes);

      // For now, we'll save the document metadata without actual file storage
      // In production, you would set up the storage bucket properly in Supabase dashboard

      // Generate a mock URL for now
      final String mockUrl =
          'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=${Uri.encodeComponent(fileName)}';

      // Save document metadata to database
      await _supabase.from('helper_documents').insert({
        'helper_id': helperId,
        'document_type': documentType,
        'document_name': fileName,
        'document_url': mockUrl,
        'file_size_bytes': fileBytes.length,
        'file_type': fileName.split('.').last,
        'job_category_id': jobCategoryId,
        'verification_status': 'pending',
        'is_active': true,
      });

      print('✅ Document metadata saved successfully (using mock URL for now)');
      return mockUrl;
    } catch (e) {
      print('❌ Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get helper's earnings data
  Future<Map<String, dynamic>> getHelperEarnings(String helperId) async {
    try {
      print('💰 Fetching earnings for helper: $helperId');

      final response = await _supabase
          .from('helper_earnings')
          .select('*')
          .eq('helper_id', helperId);

      double totalEarnings = 0;
      double totalHours = 0;
      double pendingEarnings = 0;

      for (var earning in response) {
        totalEarnings += (earning['net_earnings'] ?? 0).toDouble();
        totalHours += (earning['hours_worked'] ?? 0).toDouble();

        if (earning['payment_status'] == 'pending') {
          pendingEarnings += (earning['net_earnings'] ?? 0).toDouble();
        }
      }

      return {
        'total_earnings': totalEarnings,
        'total_hours': totalHours,
        'pending_earnings': pendingEarnings,
        'jobs_completed': response.length,
        'average_hourly_rate': totalHours > 0 ? totalEarnings / totalHours : 0,
      };
    } catch (e) {
      print('❌ Error fetching helper earnings: $e');
      return {
        'total_earnings': 0.0,
        'total_hours': 0.0,
        'pending_earnings': 0.0,
        'jobs_completed': 0,
        'average_hourly_rate': 0.0,
      };
    }
  }

  /// Update helper job types (for profile editing)
  Future<void> updateHelperJobTypes(
      String helperId, List<String> jobCategoryIds) async {
    try {
      await saveHelperJobTypes(helperId, jobCategoryIds);
    } catch (e) {
      throw Exception('Failed to update job types: $e');
    }
  }

  /// Get helpee profile data for helper to view
  Future<Map<String, dynamic>?> getHelpeeProfileForHelper(
      String helpeeId) async {
    try {
      print('🔍 Fetching helpee profile for helper view: $helpeeId');

      final response = await _supabase.from('users').select('''
            id, first_name, last_name, email, phone, profile_image_url,
            location_city, date_of_birth, gender, about_me, created_at
          ''').eq('id', helpeeId).eq('user_type', 'helpee').maybeSingle();

      if (response != null) {
        print('✅ Helpee profile data fetched successfully');
        return response;
      } else {
        print('❌ Helpee not found');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching helpee profile: $e');
      return null;
    }
  }

  /// Get helpee ratings and reviews from helpers
  Future<List<Map<String, dynamic>>> getHelpeeRatingsAndReviews(
      String helpeeId) async {
    try {
      print('🔍 Fetching helpee ratings and reviews: $helpeeId');

      final response = await _supabase
          .from('ratings_reviews')
          .select('''
            id, rating, review_text, created_at,
            reviewer:users!ratings_reviews_reviewer_id_fkey(first_name, last_name),
            jobs(title)
          ''')
          .eq('reviewee_id', helpeeId)
          .eq('review_type', 'helper_to_helpee')
          .not('review_text', 'is', null)
          .order('created_at', ascending: false)
          .limit(10);

      print('✅ Found ${response.length} reviews for helpee');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching helpee reviews: $e');
      return [];
    }
  }

  /// Get helpee job statistics
  Future<Map<String, dynamic>> getHelpeeJobStatistics(String helpeeId) async {
    try {
      print('🔍 Fetching helpee job statistics: $helpeeId');

      // Get job counts by status
      final jobs = await _supabase
          .from('jobs')
          .select('status, created_at')
          .eq('helpee_id', helpeeId);

      // Get ratings statistics
      final ratings = await _supabase
          .from('ratings_reviews')
          .select('rating')
          .eq('reviewee_id', helpeeId)
          .eq('review_type', 'helper_to_helpee')
          .not('rating', 'is', null);

      int totalJobs = jobs.length;
      int completedJobs =
          jobs.where((job) => job['status'] == 'completed').length;
      int pendingJobs = jobs.where((job) => job['status'] == 'pending').length;
      int ongoingJobs = jobs
          .where((job) =>
              ['accepted', 'started', 'ongoing'].contains(job['status']))
          .length;

      double averageRating = 0.0;
      int totalReviews = ratings.length;

      if (totalReviews > 0) {
        double ratingSum = ratings.fold(
            0.0, (sum, rating) => sum + (rating['rating'] ?? 0).toDouble());
        averageRating = ratingSum / totalReviews;
      }

      // Calculate response rate (simplified - jobs completed vs total)
      double responseRate =
          totalJobs > 0 ? (completedJobs / totalJobs) * 100 : 0.0;

      return {
        'total_jobs': totalJobs,
        'completed_jobs': completedJobs,
        'pending_jobs': pendingJobs,
        'ongoing_jobs': ongoingJobs,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'response_rate': responseRate,
        'member_since': _formatMemberSince(
            jobs.isNotEmpty ? jobs.first['created_at'] : null),
      };
    } catch (e) {
      print('❌ Error fetching helpee job statistics: $e');
      return {
        'total_jobs': 0,
        'completed_jobs': 0,
        'pending_jobs': 0,
        'ongoing_jobs': 0,
        'average_rating': 0.0,
        'total_reviews': 0,
        'response_rate': 0.0,
        'member_since': 'Recently joined',
      };
    }
  }

  /// Get helpee availability (upcoming scheduled jobs)
  Future<List<Map<String, dynamic>>> getHelpeeAvailability(
      String helpeeId) async {
    try {
      print('🔍 Fetching helpee availability: $helpeeId');

      final response = await _supabase
          .from('jobs')
          .select('''
            id, title, scheduled_date, scheduled_time, status,
            helper:users!assigned_helper_id(first_name, last_name)
          ''')
          .eq('helpee_id', helpeeId)
          .gte('scheduled_date', DateTime.now().toIso8601String().split('T')[0])
          .inFilter('status', ['pending', 'accepted', 'started'])
          .order('scheduled_date', ascending: true)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching helpee availability: $e');
      return [];
    }
  }

  /// Helper method to format member since date
  String _formatMemberSince(String? createdAt) {
    if (createdAt == null) return 'Recently joined';

    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 30) {
        return 'This month';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months == 1 ? '' : 's'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return 'Recently joined';
    }
  }

  /// Delete helper document
  Future<void> deleteHelperDocument(String documentId) async {
    try {
      print('🗑️ Deleting document: $documentId');

      await _supabase
          .from('helper_documents')
          .update({'is_active': false}).eq('id', documentId);

      print('✅ Document deleted successfully');
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get available job categories for selection
  Future<List<Map<String, dynamic>>> getAvailableJobCategories() async {
    try {
      final response = await _supabase
          .from('job_categories')
          .select('*')
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching job categories: $e');
      return [];
    }
  }

  /// Check if helper can take specific job type
  Future<bool> canHelperTakeJob(String helperId, String jobCategoryId) async {
    try {
      final response = await _supabase
          .from('helper_job_types')
          .select('id')
          .eq('helper_id', helperId)
          .eq('job_category_id', jobCategoryId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking helper job capability: $e');
      return false;
    }
  }

  /// Get helper's profile with additional data
  Future<Map<String, dynamic>?> getHelperCompleteProfile(
      String helperId) async {
    try {
      // Get basic profile
      final userProfile =
          await _supabase.from('users').select('*').eq('id', helperId).single();

      // Get job types
      final jobTypes = await getHelperJobTypes(helperId);

      // Get documents
      final documents = await getHelperDocuments(helperId);

      // Get earnings
      final earnings = await getHelperEarnings(helperId);

      // Get ratings and reviews
      final ratingsData = await getHelperRatingsAndReviews(helperId);

      return {
        ...userProfile,
        'job_types': jobTypes,
        'documents': documents,
        'earnings': earnings,
        'ratings': ratingsData,
      };
    } catch (e) {
      print('❌ Error fetching complete helper profile: $e');
      return null;
    }
  }

  /// Get helper's ratings and reviews
  Future<Map<String, dynamic>> getHelperRatingsAndReviews(
      String helperId) async {
    try {
      print('⭐ Fetching ratings and reviews for helper: $helperId');

      final response = await _supabase
          .from('ratings_reviews')
          .select('''
            id,
            rating,
            review_text,
            created_at,
            reviewer:users!ratings_reviews_reviewer_id_fkey(first_name, last_name, profile_image_url)
          ''')
          .eq('reviewee_id', helperId)
          .eq('review_type', 'helpee_to_helper')
          .order('created_at', ascending: false);

      // Rename fields for consistency
      final formattedReviews = response
          .map((r) => {
                'id': r['id'],
                'rating': r['rating'],
                'review': r['review_text'],
                'created_at': r['created_at'],
                'reviewer': r['reviewer'],
              })
          .toList();

      double totalRating = 0;
      int totalReviews = formattedReviews.length;

      if (totalReviews > 0) {
        for (var review in formattedReviews) {
          totalRating += (review['rating'] ?? 0).toDouble();
        }
      }

      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

      return {
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'reviews': formattedReviews,
      };
    } catch (e) {
      print('❌ Error fetching helper ratings: $e');
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
        'reviews': [],
      };
    }
  }

  /// Get helper's job statistics
  Future<Map<String, dynamic>> getHelperJobStatistics(String helperId) async {
    try {
      print('📊 Fetching job statistics for helper: $helperId');

      final completedJobs = await _supabase
          .from('jobs')
          .select('id, created_at, scheduled_date, hourly_rate')
          .eq('assigned_helper_id', helperId)
          .eq('status', 'completed');

      final totalJobs = completedJobs.length;
      double totalEarnings = 0;
      int totalHours = 0;

      // Calculate experience (years since first job)
      DateTime? firstJobDate;
      for (var job in completedJobs) {
        totalEarnings += (job['hourly_rate'] ?? 0).toDouble();
        totalHours +=
            3; // Average 3 hours per job (this should be calculated from actual time)

        DateTime jobDate = DateTime.parse(job['created_at']);
        if (firstJobDate == null || jobDate.isBefore(firstJobDate)) {
          firstJobDate = jobDate;
        }
      }

      double experienceYears = 0;
      if (firstJobDate != null) {
        experienceYears =
            DateTime.now().difference(firstJobDate).inDays / 365.25;
      }

      return {
        'total_jobs': totalJobs,
        'total_earnings': totalEarnings,
        'total_hours': totalHours,
        'experience_years': experienceYears.ceil(),
        'first_job_date': firstJobDate,
      };
    } catch (e) {
      print('❌ Error fetching helper job statistics: $e');
      return {
        'total_jobs': 0,
        'total_earnings': 0.0,
        'total_hours': 0,
        'experience_years': 0,
        'first_job_date': null,
      };
    }
  }

  /// Get helper's availability status
  Future<Map<String, dynamic>> getHelperAvailability(String helperId) async {
    try {
      print('🕒 Fetching availability for helper: $helperId');

      // Check if helper has any ongoing jobs
      final ongoingJobs = await _supabase
          .from('jobs')
          .select('id')
          .eq('assigned_helper_id', helperId)
          .inFilter('status', ['accepted', 'in_progress']);

      bool isAvailable = ongoingJobs.isEmpty;
      String availabilityStatus = isAvailable ? 'Available Now' : 'Busy';

      // Get helper's working hours/preferences (if table exists)
      // For now, default to basic availability

      return {
        'is_available': isAvailable,
        'status': availabilityStatus,
        'response_time': '< 1hr', // Default response time
      };
    } catch (e) {
      print('❌ Error fetching helper availability: $e');
      return {
        'is_available': true,
        'status': 'Available Now',
        'response_time': '< 1hr',
      };
    }
  }

  /// Get helper profile for helpee view (comprehensive data)
  Future<Map<String, dynamic>?> getHelperProfileForHelpee(
      String helperId) async {
    try {
      print('👤 Fetching helper profile for helpee view: $helperId');

      // Get basic profile
      final userProfile =
          await _supabase.from('users').select('*').eq('id', helperId).single();

      // Get job types with category names
      final jobTypes = await getHelperJobTypes(helperId);
      List<String> jobTypeNames =
          jobTypes.map((jt) => jt['job_categories']['name'] as String).toList();

      // Get ratings and reviews
      final ratingsData = await getHelperRatingsAndReviews(helperId);

      // Get job statistics
      final jobStats = await getHelperJobStatistics(helperId);

      // Get availability
      final availability = await getHelperAvailability(helperId);

      // Get documents for resume tab
      final documents = await getHelperDocuments(helperId);

      // Get comprehensive statistics
      final comprehensiveStats =
          await getHelperComprehensiveStatistics(helperId);

      return {
        // Basic profile info
        'id': userProfile['id'],
        'full_name':
            '${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}'
                .trim(),
        'email': userProfile['email'],
        'phone_number': userProfile['phone'],
        'profile_image_url': userProfile['profile_image_url'],
        'about_me': userProfile['about_me'] ??
            'Professional helper ready to assist you.',
        'location': userProfile['location_address'] ?? 'Location not specified',

        // Job related info
        'job_types': jobTypes,
        'job_type_names': jobTypeNames,

        // Ratings and reviews
        'average_rating': ratingsData['average_rating'],
        'total_reviews': ratingsData['total_reviews'],
        'reviews': ratingsData['reviews'],

        // Basic statistics
        'total_jobs': jobStats['total_jobs'],
        'experience_years': jobStats['experience_years'],
        'total_hours': jobStats['total_hours'],

        // Comprehensive statistics for Statistics tab
        'completed_jobs': comprehensiveStats['completed_jobs'],
        'ongoing_jobs': comprehensiveStats['ongoing_jobs'],
        'pending_jobs': comprehensiveStats['pending_jobs'],
        'total_earnings': comprehensiveStats['total_earnings'],
        'avg_earning_per_job': comprehensiveStats['avg_earning_per_job'],
        'this_month_earnings': comprehensiveStats['this_month_earnings'],
        'last_month_earnings': comprehensiveStats['last_month_earnings'],
        'total_hours_worked': comprehensiveStats['total_hours_worked'],
        'avg_hours_per_job': comprehensiveStats['avg_hours_per_job'],
        'this_month_hours': comprehensiveStats['this_month_hours'],
        'avg_response_time': comprehensiveStats['avg_response_time'],
        'category_stats': comprehensiveStats['category_stats'],

        // Availability
        'is_available': availability['is_available'],
        'availability_status': availability['status'],
        'response_time': availability['response_time'],

        // Documents for resume
        'documents': documents,
      };
    } catch (e) {
      print('❌ Error fetching helper profile for helpee: $e');
      return null;
    }
  }

  /// Get comprehensive statistics for helper (used in Statistics tab)
  Future<Map<String, dynamic>> getHelperComprehensiveStatistics(
      String helperId) async {
    try {
      print('📊 Fetching comprehensive statistics for helper: $helperId');

      // Get job counts by status
      final allJobs = await _supabase
          .from('jobs')
          .select('id, status, pay, category_id, created_at, time_taken_hours')
          .eq('assigned_helper_id', helperId);

      int completedJobs = 0;
      int ongoingJobs = 0;
      int pendingJobs = 0;
      double totalEarnings = 0;
      int totalHours = 0;

      // Current month calculations
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      double thisMonthEarnings = 0;
      double lastMonthEarnings = 0;
      int thisMonthHours = 0;

      // Category performance tracking
      Map<String, Map<String, dynamic>> categoryPerformance = {};

      for (var job in allJobs) {
        final jobDate = DateTime.parse(job['created_at']);
        final pay = (job['pay'] ?? 0).toDouble();
        final hours = ((job['time_taken_hours'] ?? 3) as num)
            .toInt(); // Default 3 hours if not specified

        switch (job['status']?.toLowerCase()) {
          case 'completed':
            completedJobs++;
            totalEarnings += pay;
            totalHours += hours;

            // Monthly earnings
            if (jobDate.isAfter(currentMonth)) {
              thisMonthEarnings += pay;
              thisMonthHours += hours;
            } else if (jobDate.isAfter(lastMonth) &&
                jobDate.isBefore(currentMonth)) {
              lastMonthEarnings += pay;
            }

            // Category performance
            final categoryId = job['category_id']?.toString();
            if (categoryId != null) {
              if (!categoryPerformance.containsKey(categoryId)) {
                categoryPerformance[categoryId] = {
                  'completed_jobs': 0,
                  'total_earnings': 0.0,
                  'total_ratings': 0.0,
                  'rating_count': 0,
                };
              }
              categoryPerformance[categoryId]!['completed_jobs'] += 1;
              categoryPerformance[categoryId]!['total_earnings'] += pay;
            }
            break;
          case 'ongoing':
          case 'in_progress':
          case 'started':
            ongoingJobs++;
            break;
          case 'pending':
          case 'accepted':
            pendingJobs++;
            break;
        }
      }

      // Calculate averages
      final avgEarningPerJob =
          completedJobs > 0 ? totalEarnings / completedJobs : 0.0;
      final avgHoursPerJob =
          completedJobs > 0 ? totalHours / completedJobs : 0.0;

      // Get category names and ratings
      List<Map<String, dynamic>> categoryStats = [];
      for (var entry in categoryPerformance.entries) {
        try {
          final categoryData = await _supabase
              .from('job_categories')
              .select('name')
              .eq('id', entry.key)
              .single();

          // Get ratings for this category
          final ratingsResponse = await _supabase
              .from('ratings_reviews')
              .select('rating')
              .eq('reviewee_id', helperId)
              .eq('job_category_id', entry.key);

          double avgRating = 0.0;
          if (ratingsResponse.isNotEmpty) {
            final ratings = ratingsResponse
                .map((r) => (r['rating'] ?? 0).toDouble())
                .toList();
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }

          categoryStats.add({
            'name': categoryData['name'],
            'completed_jobs': entry.value['completed_jobs'],
            'total_earnings': entry.value['total_earnings'],
            'avg_rating': avgRating,
          });
        } catch (e) {
          print('❌ Error fetching category data for ${entry.key}: $e');
        }
      }

      return {
        'completed_jobs': completedJobs,
        'ongoing_jobs': ongoingJobs,
        'pending_jobs': pendingJobs,
        'total_earnings': totalEarnings,
        'avg_earning_per_job': avgEarningPerJob,
        'this_month_earnings': thisMonthEarnings,
        'last_month_earnings': lastMonthEarnings,
        'total_hours_worked': totalHours,
        'avg_hours_per_job': avgHoursPerJob,
        'this_month_hours': thisMonthHours,
        'avg_response_time':
            30, // Default 30 minutes - should be calculated from actual data
        'category_stats': categoryStats,
      };
    } catch (e) {
      print('❌ Error fetching comprehensive statistics: $e');
      return {
        'completed_jobs': 0,
        'ongoing_jobs': 0,
        'pending_jobs': 0,
        'total_earnings': 0.0,
        'avg_earning_per_job': 0.0,
        'this_month_earnings': 0.0,
        'last_month_earnings': 0.0,
        'total_hours_worked': 0,
        'avg_hours_per_job': 0.0,
        'this_month_hours': 0,
        'avg_response_time': 30,
        'category_stats': [],
      };
    }
  }
}
