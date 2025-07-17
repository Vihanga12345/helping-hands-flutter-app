import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'realtime_notification_service.dart';
import 'custom_auth_service.dart';

class GlobalJobNavigationService {
  static final GlobalJobNavigationService _instance =
      GlobalJobNavigationService._internal();
  factory GlobalJobNavigationService() => _instance;
  GlobalJobNavigationService._internal();

  final RealTimeNotificationService _realtimeService =
      RealTimeNotificationService();
  final CustomAuthService _authService = CustomAuthService();

  StreamSubscription? _jobUpdateSubscription;
  BuildContext? _appContext;
  bool _isInitialized = false;

  /// Initialize the global navigation service
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appContext = context;

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print(
            '❌ No current user found - cannot initialize global job navigation');
        return;
      }

      print(
          '🌐 Initializing Global Job Navigation Service for user: ${currentUser['user_id']}');

      // Subscribe to job updates from real-time service
      _jobUpdateSubscription =
          _realtimeService.jobUpdateStream.listen(_handleJobStatusChange);

      _isInitialized = true;
      print('✅ Global Job Navigation Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Global Job Navigation Service: $e');
    }
  }

  /// Handle job status changes and navigate users accordingly
  void _handleJobStatusChange(Map<String, dynamic> jobData) {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || _appContext == null) return;

      final jobId = jobData['id'];
      final status = jobData['status']?.toLowerCase() ?? '';
      final helpeeId = jobData['helpee_id'];
      final helperId = jobData['assigned_helper_id'];
      final currentUserId = currentUser['user_id'];
      final userType = currentUser['user_type'];

      // Check if current user is involved in this job
      final isUserInvolved =
          (helpeeId == currentUserId) || (helperId == currentUserId);

      if (!isUserInvolved) {
        print('🌐 Job update not relevant to current user: $jobId');
        return;
      }

      print(
          '🌐 Processing job status change for user: $currentUserId, job: $jobId, status: $status');

      // Determine target route based on job status and user type
      String? targetRoute = _determineTargetRoute(status, userType);

      if (targetRoute != null) {
        print('🌐 Navigating $userType to: $targetRoute');
        _navigateToRoute(targetRoute);
      }
    } catch (e) {
      print('❌ Error handling job status change: $e');
    }
  }

  /// Determine the target route based on job status and user type
  String? _determineTargetRoute(String status, String userType) {
    String baseRoute =
        userType == 'helper' ? '/helper/activity' : '/helpee/activity';

    switch (status) {
      case 'accepted':
      case 'started':
      case 'paused':
      case 'resumed':
      case 'ongoing':
        return '$baseRoute/ongoing';

      case 'completed':
        return '$baseRoute/completed';

      default:
        // For other statuses (pending, cancelled, etc.), don't navigate
        return null;
    }
  }

  /// Navigate to the specified route
  void _navigateToRoute(String route) {
    try {
      if (_appContext != null && _appContext!.mounted) {
        // Use go() instead of push() to replace current route and avoid stacking
        _appContext!.go(route);
        print('✅ Navigation completed to: $route');
      } else {
        print('⚠️ Cannot navigate: context not available');
      }
    } catch (e) {
      print('❌ Navigation error: $e');
    }
  }

  /// Update app context when needed
  void updateContext(BuildContext context) {
    _appContext = context;
  }

  /// Dispose of the service
  void dispose() {
    _jobUpdateSubscription?.cancel();
    _isInitialized = false;
    print('🌐 Global Job Navigation Service disposed');
  }
}
