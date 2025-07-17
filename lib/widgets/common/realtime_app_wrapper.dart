import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/realtime_notification_service.dart'
    as MainNotificationService;
// import '../../services/real_time_notification_service.dart'
//     as LegacyNotificationService;
import '../../services/live_data_refresh_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/global_job_navigation_service.dart';
import '../../services/payment_flow_service.dart';
import '../../services/popup_manager_service.dart';
import '../../services/webrtc_service.dart';

class RealTimeAppWrapper extends StatefulWidget {
  final Widget child;

  const RealTimeAppWrapper({
    super.key,
    required this.child,
  });

  @override
  State<RealTimeAppWrapper> createState() => _RealTimeAppWrapperState();
}

class _RealTimeAppWrapperState extends State<RealTimeAppWrapper> {
  final MainNotificationService.RealTimeNotificationService
      _notificationService =
      MainNotificationService.RealTimeNotificationService();
  // final LegacyNotificationService.RealTimeNotificationService
  //     _legacyNotificationService =
  //     LegacyNotificationService.RealTimeNotificationService();
  final LiveDataRefreshService _liveDataService = LiveDataRefreshService();
  final GlobalJobNavigationService _globalNavService =
      GlobalJobNavigationService();
  final PaymentFlowService _paymentFlowService = PaymentFlowService();
  final CustomAuthService _authService = CustomAuthService();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame to be rendered before initializing services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRealTimeServices();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services when dependencies change (like when user logs in)
    if (!_isInitialized) {
      _initializeRealTimeServices();
    }
  }

  Future<void> _initializeRealTimeServices() async {
    try {
      // Check if user is logged in
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('🔔 Real-time services not initialized - no user logged in');
        return;
      }

      if (_isInitialized) return;

      final userId = currentUser['user_id'];
      final userType = currentUser['user_type'];

      print(
          '🔔 Initializing global real-time services for user: $userId ($userType)');

      // Set up navigator keys for all services that need them
      if (mounted) {
        final navigatorKey = _getNavigatorKey();
        if (navigatorKey != null) {
          MainNotificationService.RealTimeNotificationService.setNavigatorKey(
              navigatorKey);
          // LegacyNotificationService.RealTimeNotificationService.setNavigatorKey(
          //     navigatorKey);
          PopupManagerService.setNavigatorKey(navigatorKey);
          WebRTCService.setNavigatorKey(navigatorKey);
          print('✅ Navigator keys set for all services');
        }
      }

      // Initialize main notification service with app context (includes message notifications)
      await _notificationService.initialize(context);

      // Initialize legacy notification service for message handling (DISABLED)
      // await _legacyNotificationService.initialize(userId, userType);

      // Initialize live data refresh service with global scope
      await _liveDataService.initialize();

      // Initialize global job navigation service
      await _globalNavService.initialize(context);

      // Start global auto-refresh for all pages
      _startGlobalAutoRefresh();

      _isInitialized = true;
      print('✅ Global real-time services initialized successfully');
    } catch (e) {
      print('❌ Error initializing real-time services: $e');
    }
  }

  /// Get the navigator key from the current context
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    try {
      // Try to find the navigator key from the current context
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        // Access the navigator state's widget key if available
        final state = navigator as NavigatorState;
        return state.widget.key as GlobalKey<NavigatorState>?;
      }
      return null;
    } catch (e) {
      print('⚠️ Could not get navigator key: $e');
      return null;
    }
  }

  /// Start global auto-refresh that works on all pages
  void _startGlobalAutoRefresh() {
    try {
      // Enable auto-refresh globally
      _liveDataService.setAutoRefresh(true);

      print('✅ Global auto-refresh enabled - works on all pages');
    } catch (e) {
      print('❌ Error starting global auto-refresh: $e');
    }
  }

  @override
  void dispose() {
    // Clean up services when app is disposed
    _notificationService.dispose();
    // _legacyNotificationService.dispose();
    _liveDataService.dispose();
    _globalNavService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to provide easy access to real-time services from anywhere in the app
extension RealTimeContext on BuildContext {
  MainNotificationService.RealTimeNotificationService get notificationService =>
      MainNotificationService.RealTimeNotificationService();
  LiveDataRefreshService get liveDataService => LiveDataRefreshService();
}

/// Mixin for pages that need real-time updates
mixin RealTimePageMixin<T extends StatefulWidget> on State<T> {
  // Use singleton instances instead of creating new ones
  late final MainNotificationService.RealTimeNotificationService
      _notificationService;
  late final LiveDataRefreshService _liveDataService;

  @override
  void initState() {
    super.initState();
    // Get singleton instances
    _notificationService =
        MainNotificationService.RealTimeNotificationService();
    _liveDataService = LiveDataRefreshService();
    _ensureRealTimeServicesInitialized();
  }

  void _ensureRealTimeServicesInitialized() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_notificationService.isInitialized) {
        _notificationService.initialize(context);
      }
      if (!_liveDataService.isInitialized) {
        _liveDataService.initialize();
      }
    });
  }

  MainNotificationService.RealTimeNotificationService get notificationService =>
      _notificationService;
  LiveDataRefreshService get liveDataService => _liveDataService;
}
