import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_auth_service.dart';
import 'admin_auth_service.dart';

/// AuthGuardService - Handles user type-based route protection and session validation
class AuthGuardService {
  static final AuthGuardService _instance = AuthGuardService._internal();
  factory AuthGuardService() => _instance;
  AuthGuardService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Lazy initialization to avoid circular dependency
  CustomAuthService? _authServiceInstance;
  CustomAuthService get _authService {
    _authServiceInstance ??= CustomAuthService();
    return _authServiceInstance!;
  }

  // Admin auth service for admin-specific authentication
  AdminAuthService? _adminAuthInstance;
  AdminAuthService get _adminAuth {
    _adminAuthInstance ??= AdminAuthService();
    return _adminAuthInstance!;
  }

  // Route patterns that require specific user types
  static const Map<String, List<String>> _routePermissions = {
    '/helpee': ['helpee'],
    '/helper': ['helper'],
    '/admin': ['admin'],
  };

  // Public routes that don't require authentication
  static const List<String> _publicRoutes = [
    '/',
    '/intro1',
    '/intro2',
    '/intro3',
    '/user-selection',
    '/helpee-auth',
    '/helpee-login',
    '/helpee-register',
    '/helper-auth',
    '/helper-login',
    '/helper-register',
    '/helper-register-2',
    '/helper-register-3',
    '/helper-register-4',
    '/admin', // Admin start page (splash screen)
    '/admin/login', // Admin login page
  ];

  /// Check if a route requires authentication
  bool requiresAuth(String route) {
    return !_publicRoutes.any((publicRoute) =>
        route == publicRoute || route.startsWith('$publicRoute/'));
  }

  /// Check if user has permission to access a specific route
  Future<RouteAccessResult> checkRouteAccess(String route) async {
    try {
      // Check if route requires authentication
      if (!requiresAuth(route)) {
        return RouteAccessResult.allowed();
      }

      // Special handling for admin routes
      if (route.startsWith('/admin')) {
        return await _checkAdminRouteAccess(route);
      }

      // Check if user is logged in
      if (!_authService.isLoggedIn) {
        return RouteAccessResult.denied(
          reason: 'Authentication required',
          redirectTo: _getAuthPageForRoute(route),
        );
      }

      // Get required user type for this route
      final requiredUserType = _getRequiredUserTypeForRoute(route);
      if (requiredUserType == null) {
        // Route doesn't have specific user type requirement
        return RouteAccessResult.allowed();
      }

      // Check user type match
      final currentUserType = _authService.currentUserType;
      if (currentUserType != requiredUserType) {
        // Log security event
        await _logSecurityEvent(
          eventType: 'user_type_mismatch',
          attemptedRoute: route,
          expectedUserType: requiredUserType,
          actualUserType: currentUserType,
        );

        return RouteAccessResult.denied(
          reason:
              'Insufficient permissions: This page is for ${requiredUserType}s only',
          redirectTo: _getHomePageForUserType(currentUserType),
          shouldLogout: true,
        );
      }

      // Validate session in database
      final sessionValid = await _validateSessionInDatabase();
      if (!sessionValid) {
        await _authService.logout();
        return RouteAccessResult.denied(
          reason: 'Session expired',
          redirectTo: _getAuthPageForRoute(route),
        );
      }

      return RouteAccessResult.allowed();
    } catch (e) {
      print('❌ Error checking route access: $e');
      return RouteAccessResult.denied(
        reason: 'Security check failed',
        redirectTo: '/',
      );
    }
  }

  /// Check admin route access using AdminAuthService
  Future<RouteAccessResult> _checkAdminRouteAccess(String route) async {
    try {
      // Allow access to admin start and login pages
      if (route == '/admin' || route == '/admin/login') {
        return RouteAccessResult.allowed();
      }

      // Check if admin is logged in
      if (!_adminAuth.isLoggedIn) {
        return RouteAccessResult.denied(
          reason: 'Admin authentication required',
          redirectTo: '/admin/login',
        );
      }

      // Validate admin session
      final sessionValid = await _adminAuth.validateSession();
      if (!sessionValid) {
        await _adminAuth.logout();
        return RouteAccessResult.denied(
          reason: 'Admin session expired',
          redirectTo: '/admin/login',
        );
      }

      // Log admin access
      await _adminAuth.logAction('access', 'route', actionDetails: {
        'route_accessed': route,
        'access_time': DateTime.now().toIso8601String(),
      });

      return RouteAccessResult.allowed();
    } catch (e) {
      print('❌ Error checking admin route access: $e');
      return RouteAccessResult.denied(
        reason: 'Admin security check failed',
        redirectTo: '/admin/login',
      );
    }
  }

  /// Get required user type for a route
  String? _getRequiredUserTypeForRoute(String route) {
    for (final entry in _routePermissions.entries) {
      if (route.startsWith(entry.key)) {
        return entry.value
            .first; // Return the first (and usually only) required user type
      }
    }
    return null;
  }

  /// Get appropriate auth page for a route
  String _getAuthPageForRoute(String route) {
    if (route.startsWith('/helpee')) {
      return '/helpee-login';
    } else if (route.startsWith('/helper')) {
      return '/helper-login';
    } else if (route.startsWith('/admin')) {
      return '/admin/login';
    }
    return '/user-selection';
  }

  /// Get home page for user type
  String _getHomePageForUserType(String? userType) {
    switch (userType) {
      case 'helpee':
        return '/helpee/home';
      case 'helper':
        return '/helper/home';
      case 'admin':
        return '/admin/home';
      default:
        return '/user-selection';
    }
  }

  /// Validate current session in database
  Future<bool> _validateSessionInDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      final currentUserType = _authService.currentUserType;

      if (sessionToken == null || currentUserType == null) {
        return false;
      }

      // Simplified session validation without database functions
      // Check if user is logged in with valid session data
      if (_authService.isLoggedIn && _authService.currentUser != null) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Session validation error: $e');
      return false;
    }
  }

  /// Log security events to database
  Future<void> _logSecurityEvent({
    required String eventType,
    required String attemptedRoute,
    String? expectedUserType,
    String? actualUserType,
    Map<String, dynamic>? eventDetails,
    String severity = 'medium',
  }) async {
    try {
      // Simplified security logging without database functions
      print('🔒 Security event: $eventType for route $attemptedRoute');
      print('   Expected: $expectedUserType, Actual: $actualUserType');
      print('   Details: $eventDetails');
    } catch (e) {
      print('❌ Failed to log security event: $e');
    }
  }

  /// Force logout for security reasons
  Future<void> forceLogoutForSecurity(String reason) async {
    try {
      // Log security logout event
      await _logSecurityEvent(
        eventType: 'forced_logout',
        attemptedRoute: 'security',
        eventDetails: {'logout_reason': reason},
        severity: 'high',
      );

      // Perform logout based on current user type
      if (_authService.isLoggedIn) {
        await _authService.logout();
      }

      if (_adminAuth.isLoggedIn) {
        await _adminAuth.logout();
      }

      print('🔒 Security logout completed: $reason');
    } catch (e) {
      print('❌ Error during security logout: $e');
    }
  }

  /// Get user permissions for UI display
  Future<Map<String, dynamic>> getUserPermissions() async {
    try {
      final currentUserType = _authService.currentUserType;
      final isAdminLoggedIn = _adminAuth.isLoggedIn;

      return {
        'user_type': currentUserType,
        'is_admin': isAdminLoggedIn,
        'can_access_helpee': currentUserType == 'helpee',
        'can_access_helper': currentUserType == 'helper',
        'can_access_admin': isAdminLoggedIn,
        'session_valid': await _validateSessionInDatabase(),
        'admin_session_valid':
            isAdminLoggedIn ? await _adminAuth.validateSession() : false,
      };
    } catch (e) {
      print('❌ Error getting user permissions: $e');
      return {
        'user_type': null,
        'is_admin': false,
        'can_access_helpee': false,
        'can_access_helper': false,
        'can_access_admin': false,
        'session_valid': false,
        'admin_session_valid': false,
      };
    }
  }

  /// Clear all user sessions (for complete logout)
  Future<void> clearAllSessions() async {
    try {
      await _authService.logout();
      await _adminAuth.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('🔒 All user sessions cleared');
    } catch (e) {
      print('❌ Error clearing sessions: $e');
    }
  }

  /// Create user session (called by CustomAuthService)
  Future<void> createUserSession(
    String userId,
    String userType,
    String sessionToken, {
    String? userAuthId,
  }) async {
    try {
      // Store session information
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_token', sessionToken);
      await prefs.setString('user_id', userId);
      await prefs.setString('user_type', userType);

      // Simplified session creation without database functions
      print('✅ User session created: $userType for user $userId');
    } catch (e) {
      print('❌ Error creating user session: $e');
    }
  }

  /// Invalidate current session (called by CustomAuthService)
  Future<void> invalidateCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear session data
      await prefs.remove('session_token');
      await prefs.remove('user_id');
      await prefs.remove('user_type');

      print('✅ Current session invalidated');
    } catch (e) {
      print('❌ Error invalidating session: $e');
    }
  }
}

/// Result of route access check
class RouteAccessResult {
  final bool isAllowed;
  final String? reason;
  final String? redirectTo;
  final bool shouldLogout;

  RouteAccessResult._({
    required this.isAllowed,
    this.reason,
    this.redirectTo,
    this.shouldLogout = false,
  });

  factory RouteAccessResult.allowed() {
    return RouteAccessResult._(isAllowed: true);
  }

  factory RouteAccessResult.denied({
    String? reason,
    String? redirectTo,
    bool shouldLogout = false,
  }) {
    return RouteAccessResult._(
      isAllowed: false,
      reason: reason,
      redirectTo: redirectTo,
      shouldLogout: shouldLogout,
    );
  }
}
