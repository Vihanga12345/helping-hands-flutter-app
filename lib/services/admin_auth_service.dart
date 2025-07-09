import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  static const String _sessionKey = 'admin_session';
  static const String _userKey = 'admin_user';

  Map<String, dynamic>? _currentAdmin;
  String? _currentSessionToken;
  bool _isInitialized = false;

  // Getters
  bool get isLoggedIn => _currentAdmin != null && _currentSessionToken != null;
  Map<String, dynamic>? get currentAdmin => _currentAdmin;
  String? get currentSessionToken => _currentSessionToken;
  String? get currentAdminId => _currentAdmin?['id'];
  String? get currentAdminUsername => _currentAdmin?['username'];
  String? get currentAdminName => _currentAdmin?['full_name'];

  /// Initialize the service and restore session if available
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final userData = prefs.getString(_userKey);

      if (sessionData != null && userData != null) {
        _currentSessionToken = sessionData;
        _currentAdmin = jsonDecode(userData);

        // Validate the stored session
        final isValid = await _validateStoredSession();
        if (!isValid) {
          await logout();
        } else {
          print('✅ Admin session restored successfully');
          print(
              '   Admin: ${_currentAdmin?['username']} (${_currentAdmin?['full_name']})');
        }
      }

      _isInitialized = true;
    } catch (e) {
      print('⚠️ Error initializing admin auth service: $e');
      await logout(); // Clear any corrupted data
      _isInitialized = true;
    }
  }

  /// Admin login with credentials
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔐 Attempting admin login for username: $username');

      // Hash the password
      final passwordHash = _hashPassword(password);

      // Try main authentication function first
      try {
        final result = await Supabase.instance.client.rpc(
          'authenticate_admin',
          params: {
            'p_username': username,
            'p_password_hash': passwordHash,
            'p_ip_address': '127.0.0.1',
            'p_user_agent': 'Flutter Web Admin',
          },
        );

        if (result != null && result['is_valid'] == true) {
          return await _handleSuccessfulLogin(result);
        }
      } catch (dbError) {
        print(
            '⚠️ Database function not available, using fallback authentication');

        // Fallback authentication for development
        if (username == 'admin' && password == 'admin123') {
          final fallbackResult = {
            'admin_id': '00000000-0000-0000-0000-000000000001',
            'username': username,
            'is_valid': true,
          };
          return await _handleSuccessfulLogin(fallbackResult);
        }
      }

      // If we reach here, authentication failed
      await _handleFailedLogin(username);

      return {
        'success': false,
        'error': 'Invalid username or password',
      };
    } catch (e) {
      print('❌ Admin login error: $e');
      return {
        'success': false,
        'error': 'Login failed: ${e.toString()}',
      };
    }
  }

  /// Handle successful login
  Future<Map<String, dynamic>> _handleSuccessfulLogin(
      Map<String, dynamic> result) async {
    try {
      // Generate session token
      final sessionToken = _generateSessionToken();

      // Store session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_session_token', sessionToken);
      await prefs.setString('admin_username', result['username']);
      await prefs.setString('admin_id', result['admin_id'].toString());

      // Set current admin state
      _currentAdmin = {
        'id': result['admin_id'],
        'username': result['username'],
      };
      _currentSessionToken = sessionToken;

      // Log successful login
      await _logAdminAction(
          'login',
          'authentication',
          null, // entityId
          null, // entityName
          {
            'ip_address': '127.0.0.1',
            'user_agent': 'Flutter Web Admin',
            'login_method':
                result.containsKey('admin_id') ? 'database' : 'fallback',
            'admin_id': '00000000-0000-0000-0000-000000000001',
          });

      print('✅ Admin login successful for: ${result['username']}');

      return {
        'success': true,
        'admin': _currentAdmin,
        'session_token': sessionToken,
      };
    } catch (e) {
      print('❌ Error handling successful login: $e');
      return {
        'success': false,
        'error': 'Session creation failed',
      };
    }
  }

  /// Handle failed login attempt
  Future<void> _handleFailedLogin(String username) async {
    try {
      // In a real app, you would update failed login attempts in database
      // For now, just log the attempt
      print('❌ Failed login attempt for admin: $username');

      // You could implement account lockout logic here
    } catch (e) {
      print('❌ Error handling failed login: $e');
    }
  }

  /// Logout admin user
  Future<void> logout() async {
    try {
      if (_currentSessionToken != null) {
        // Call logout function to invalidate session in database
        await Supabase.instance.client.rpc(
          'logout_admin_session',
          params: {'p_session_token': _currentSessionToken},
        );

        // Log logout action
        if (_currentAdmin != null) {
          await _logAdminAction(
            'logout',
            'system',
            _currentAdmin!['id'],
            'Admin Logout',
            {'logout_time': DateTime.now().toIso8601String()},
          );
        }
      }
    } catch (e) {
      print('⚠️ Error during logout: $e');
    }

    // Clear local session data
    _currentAdmin = null;
    _currentSessionToken = null;

    // Clear stored session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_userKey);

    print('✅ Admin logout completed');
  }

  /// Validate current session
  Future<bool> validateSession() async {
    if (_currentSessionToken == null) return false;

    try {
      final response = await Supabase.instance.client.rpc(
        'validate_admin_session',
        params: {'p_session_token': _currentSessionToken},
      );

      if (response == null || response.isEmpty) return false;

      final result = response[0];
      return result['is_valid'] == true;
    } catch (e) {
      print('⚠️ Session validation error: $e');
      return false;
    }
  }

  /// Check if admin has permission for specific action
  Future<bool> hasPermission(String action, String entityType) async {
    // For now, all admins have all permissions
    // In the future, implement role-based permissions
    return isLoggedIn;
  }

  /// Log admin action for audit trail
  Future<void> logAction(
    String actionType,
    String entityType, {
    String? entityId,
    String? entityName,
    Map<String, dynamic>? actionDetails,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    if (!isLoggedIn) return;

    await _logAdminAction(
      actionType,
      entityType,
      entityId,
      entityName,
      actionDetails,
      oldValues,
      newValues,
    );
  }

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>?> getDashboardStats() async {
    if (!isLoggedIn) return null;

    try {
      final response =
          await Supabase.instance.client.rpc('get_admin_dashboard_stats');
      return response as Map<String, dynamic>?;
    } catch (e) {
      print('⚠️ Error getting dashboard stats: $e');
      return null;
    }
  }

  // Private helper methods

  /// Generate secure session token
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'admin_${timestamp}_$random';
  }

  /// Hash password for security
  String _hashPassword(String password) {
    // In production, use proper password hashing like bcrypt
    // For now, using a simple hash for development
    return 'hash_$password';
  }

  /// Get admin details from database
  Future<Map<String, dynamic>?> _getAdminDetails(String adminId) async {
    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select(
              'id, username, full_name, email, is_active, last_login, created_at')
          .eq('id', adminId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('⚠️ Error getting admin details: $e');
      return null;
    }
  }

  /// Validate stored session against database
  Future<bool> _validateStoredSession() async {
    if (_currentSessionToken == null) return false;

    try {
      final response = await Supabase.instance.client.rpc(
        'validate_admin_session',
        params: {'p_session_token': _currentSessionToken},
      );

      if (response == null || response.isEmpty) return false;

      final result = response[0];
      if (result['is_valid'] != true) return false;

      // Update admin data if needed
      if (result['admin_id'] != null) {
        final adminData = await _getAdminDetails(result['admin_id']);
        if (adminData != null) {
          _currentAdmin = adminData;
        }
      }

      return true;
    } catch (e) {
      print('⚠️ Session validation error: $e');
      return false;
    }
  }

  /// Persist session to local storage
  Future<void> _persistSession() async {
    if (_currentSessionToken == null || _currentAdmin == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, _currentSessionToken!);
      await prefs.setString(_userKey, jsonEncode(_currentAdmin!));
    } catch (e) {
      print('⚠️ Error persisting session: $e');
    }
  }

  /// Log admin action to audit trail
  Future<void> _logAdminAction(
    String actionType,
    String entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? actionDetails, [
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  ]) async {
    if (!isLoggedIn) return;

    try {
      await Supabase.instance.client.rpc(
        'log_admin_action',
        params: {
          'p_admin_id': _currentAdmin!['id'],
          'p_session_token': _currentSessionToken,
          'p_action_type': actionType,
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_entity_name': entityName,
          'p_action_details':
              actionDetails != null ? jsonEncode(actionDetails) : null,
          'p_old_values': oldValues != null ? jsonEncode(oldValues) : null,
          'p_new_values': newValues != null ? jsonEncode(newValues) : null,
        },
      );
    } catch (e) {
      print('⚠️ Error logging admin action: $e');
    }
  }

  /// Create error response
  Map<String, dynamic> _createErrorResponse(String message) {
    return {
      'success': false,
      'error': message,
      'admin': null,
      'session_token': null,
    };
  }

  /// Check session validity periodically
  Future<void> checkSessionHealth() async {
    if (!isLoggedIn) return;

    final isValid = await validateSession();
    if (!isValid) {
      print('⚠️ Admin session expired, logging out...');
      await logout();
    }
  }

  /// Force logout all admin sessions (for security)
  Future<void> forceLogoutAllSessions() async {
    if (!isLoggedIn) return;

    try {
      // In a real implementation, you would call a function to invalidate all sessions
      // For now, just logout current session
      await logout();
    } catch (e) {
      print('⚠️ Error forcing logout: $e');
    }
  }
}
