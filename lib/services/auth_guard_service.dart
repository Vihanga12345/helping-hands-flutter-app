import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_auth_service.dart';

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
      return '/admin-login';
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
        return '/admin/dashboard';
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

      final result =
          await _supabase.rpc('validate_user_session_and_type', params: {
        'p_session_token': sessionToken,
        'p_required_user_type': currentUserType,
      });

      if (result is List && result.isNotEmpty) {
        final validation = result.first;
        return validation['is_valid'] == true;
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
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');

      await _supabase.rpc('log_security_event', params: {
        'p_user_id': _authService.currentUserId,
        'p_session_token': sessionToken,
        'p_event_type': eventType,
        'p_attempted_route': attemptedRoute,
        'p_expected_user_type': expectedUserType,
        'p_actual_user_type': actualUserType,
        'p_event_details': eventDetails,
        'p_severity': severity,
      });

      print('🔒 Security event logged: $eventType for route $attemptedRoute');
    } catch (e) {
      print('❌ Failed to log security event: $e');
    }
  }

  /// Force logout user due to security violation
  Future<void> forceLogoutForSecurity(String reason) async {
    try {
      // Log the forced logout
      await _logSecurityEvent(
        eventType: 'forced_logout',
        attemptedRoute: 'security_violation',
        eventDetails: {'reason': reason},
        severity: 'high',
      );

      // Invalidate all user sessions in database
      if (_authService.currentUserId != null) {
        await _supabase.rpc('invalidate_user_sessions', params: {
          'p_user_id': _authService.currentUserId,
          'p_reason': reason,
        });
      }

      // Logout locally
      await _authService.logout();

      print('🔒 User force logged out due to: $reason');
    } catch (e) {
      print('❌ Error during force logout: $e');
    }
  }

  /// Create new session in database
  Future<bool> createUserSession(
      String userId, String userType, String sessionToken,
      {String? userAuthId}) async {
    try {
      // Need to get the user_auth_id if not provided
      String? authId = userAuthId;

      if (authId == null) {
        // Get the user_auth_id from the user_authentication table
        final authResult = await _supabase
            .from('user_authentication')
            .select('id')
            .eq('user_id', userId)
            .eq('user_type', userType)
            .maybeSingle();

        if (authResult != null) {
          authId = authResult['id'];
        }
      }

      await _supabase.from('user_sessions').insert({
        'user_auth_id': authId, // Required field
        'user_id': userId, // Added for backwards compatibility
        'session_token': sessionToken,
        'user_type': userType,
        'device_info': kIsWeb ? 'Web Browser' : 'Mobile Device',
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      print('✅ User session created in database');
      return true;
    } catch (e) {
      print('❌ Failed to create user session: $e');
      return false;
    }
  }

  /// Invalidate current session
  Future<void> invalidateCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');

      if (sessionToken != null) {
        await _supabase
            .from('user_sessions')
            .update({'is_active': false}).eq('session_token', sessionToken);
      }
    } catch (e) {
      print('❌ Failed to invalidate session: $e');
    }
  }

  /// Check if route permission exists in database
  Future<bool> checkRoutePermissionInDatabase(
      String route, String userType) async {
    try {
      final result = await _supabase.rpc('check_route_permission', params: {
        'p_route': route,
        'p_user_type': userType,
      });

      return result == true;
    } catch (e) {
      print('❌ Error checking route permission: $e');
      return false;
    }
  }

  /// Get security audit logs for admin
  Future<List<Map<String, dynamic>>> getSecurityAuditLogs({
    int limit = 100,
    String? eventType,
    String? severity,
  }) async {
    try {
      dynamic query = _supabase.from('security_audit_log').select(
          '*, users!security_audit_log_user_id_fkey(first_name, last_name, email)');

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final result = await query;
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('❌ Error fetching security audit logs: $e');
      return [];
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
    required String reason,
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
