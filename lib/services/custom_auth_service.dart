import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_guard_service.dart';

class CustomAuthService {
  static final CustomAuthService _instance = CustomAuthService._internal();
  factory CustomAuthService() => _instance;
  CustomAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Lazy initialization to avoid circular dependency
  AuthGuardService? _authGuardInstance;
  AuthGuardService get _authGuard {
    _authGuardInstance ??= AuthGuardService();
    return _authGuardInstance!;
  }

  // Mock in-memory database for development
  static final Map<String, List<Map<String, dynamic>>> _mockTables = {
    'users': [],
    'user_authentication': [],
    'user_sessions': [],
  };

  // Flag to determine if we're using mock data
  bool _useMockData = false;

  // Current user session data
  Map<String, dynamic>? _currentUser;
  String? _currentSessionToken;

  // Getters for current user
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentUserType => _currentUser?['user_type'];
  String? get currentUserId => _currentUser?['user_id'];
  String? get currentUsername => _currentUser?['username'];
  bool get isLoggedIn => _currentUser != null;

  /// Initialize authentication service and check for existing session
  Future<bool> initialize() async {
    try {
      // Always use real Supabase database
      _useMockData = false;
      print('✅ CustomAuthService connected to Supabase database');

      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');

      if (sessionToken != null) {
        print('🔍 Found existing session token, validating...');
        final isValid = await _validateSession(sessionToken);
        if (isValid) {
          print(
              '✅ Session restored for user: ${_currentUser?['username']} (${_currentUser?['user_type']})');
          return true;
        } else {
          print('❌ Session invalid, clearing...');
          await logout();
        }
      } else {
        print('ℹ️ No existing session found');
      }
      return false;
    } catch (e) {
      print('Auth initialization error: $e');
      return false;
    }
  }

  /// Force clear session and logout (for debugging user type issues)
  Future<void> forceClearSession() async {
    print('🧹 Force clearing session...');
    await logout();
  }

  void _initializeMockData() {
    // Add sample users for testing
    _mockTables['users'] = [
      {
        'id': 'user_1',
        'first_name': 'John',
        'last_name': 'Doe',
        'display_name': 'John Doe',
        'profile_image_url': null,
        'phone': '+94771234567',
        'location_city': 'Colombo',
        'user_type': 'helpee',
        'email': 'john@example.com',
        'username': 'johndoe',
        'is_active': true,
      },
      {
        'id': 'user_2',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'display_name': 'Jane Smith',
        'profile_image_url': null,
        'phone': '+94777654321',
        'location_city': 'Kandy',
        'user_type': 'helper',
        'email': 'jane@example.com',
        'username': 'janesmith',
        'is_active': true,
      },
    ];

    _mockTables['user_authentication'] = [
      {
        'id': 'auth_1',
        'user_id': 'user_1',
        'username': 'johndoe',
        'email': 'john@example.com',
        'password_hash': _hashPassword('password123'),
        'user_type': 'helpee',
        'is_active': true,
        'login_attempts': 0,
        'account_locked_until': null,
        'last_login': null,
      },
      {
        'id': 'auth_2',
        'user_id': 'user_2',
        'username': 'janesmith',
        'email': 'jane@example.com',
        'password_hash': _hashPassword('password123'),
        'user_type': 'helper',
        'is_active': true,
        'login_attempts': 0,
        'account_locked_until': null,
        'last_login': null,
      },
    ];

    _mockTables['user_sessions'] = [];
  }

  /// Register a new user (helper or helpee)
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String userType, // 'helper' or 'helpee'
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      if (_useMockData) {
        return await _registerMock(
          username: username,
          email: email,
          password: password,
          userType: userType,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
      }

      // Check if username already exists for the same user type
      final existingUsername = await _supabase
          .from('user_authentication')
          .select('id')
          .eq('username', username)
          .eq('user_type', userType)
          .maybeSingle();

      if (existingUsername != null) {
        return {
          'success': false,
          'error': 'Username already exists for ${userType}s'
        };
      }

      final existingEmail = await _supabase
          .from('user_authentication')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        return {'success': false, 'error': 'Email already exists'};
      }

      // Hash password
      final passwordHash = _hashPassword(password);

      // Create user with authentication using stored function
      final result = await _supabase.rpc('create_user_with_auth', params: {
        'p_username': username,
        'p_email': email,
        'p_password_hash': passwordHash,
        'p_user_type': userType,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_phone': phone,
      });

      if (result != null) {
        // Auto-login after successful registration
        final loginResult = await login(
          usernameOrEmail: username,
          password: password,
          userType: userType,
        );

        return loginResult;
      } else {
        return {'success': false, 'error': 'Failed to create user'};
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'error': 'Registration failed: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> _registerMock({
    required String username,
    required String email,
    required String password,
    required String userType,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    // Check if username already exists for the same user type
    final existingUsername = _mockTables['user_authentication']!
        .where((auth) =>
            auth['username'] == username && auth['user_type'] == userType)
        .toList();

    if (existingUsername.isNotEmpty) {
      return {
        'success': false,
        'error': 'Username already exists for ${userType}s'
      };
    }

    // Check if email already exists (email should be unique across all user types)
    final existingEmail = _mockTables['user_authentication']!
        .where((auth) => auth['email'] == email)
        .toList();

    if (existingEmail.isNotEmpty) {
      return {'success': false, 'error': 'Email already exists'};
    }

    // Create user
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final user = {
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': '$firstName $lastName',
      'profile_image_url': null,
      'phone': phone,
      'location_city': 'Colombo',
      'user_type': userType,
      'email': email,
      'username': username,
      'is_active': true,
    };
    _mockTables['users']!.add(user);

    // Create authentication record
    final authId = 'auth_${DateTime.now().millisecondsSinceEpoch}';
    final auth = {
      'id': authId,
      'user_id': userId,
      'username': username,
      'email': email,
      'password_hash': _hashPassword(password),
      'user_type': userType,
      'is_active': true,
      'login_attempts': 0,
      'account_locked_until': null,
      'last_login': null,
    };
    _mockTables['user_authentication']!.add(auth);

    // Auto-login after successful registration
    return await login(
      usernameOrEmail: username,
      password: password,
      userType: userType,
    );
  }

  /// Login user with username/email and password
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
    required String userType,
  }) async {
    try {
      if (_useMockData) {
        return await _loginMock(
          usernameOrEmail: usernameOrEmail,
          password: password,
          userType: userType,
        );
      }

      // Hash the provided password
      final passwordHash = _hashPassword(password);

      // Step 1: Find user by username/email and user_type first
      print('🔍 Looking for user: $usernameOrEmail, type: $userType');

      final baseSelect = '''
            id, username, email, user_type, user_id, is_active, login_attempts, account_locked_until, password_hash,
            users!inner(id, first_name, last_name, display_name, profile_image_url, phone, location_city)
          ''';

      // Build query based on login type
      final authResult = await (() async {
        if (usernameOrEmail.contains('@')) {
          print('🔍 Searching by email: $usernameOrEmail');
          return await _supabase
              .from('user_authentication')
              .select(baseSelect)
              .eq('user_type', userType)
              .eq('is_active', true)
              .eq('email', usernameOrEmail)
              .maybeSingle();
        } else {
          print('🔍 Searching by username: $usernameOrEmail');
          return await _supabase
              .from('user_authentication')
              .select(baseSelect)
              .eq('user_type', userType)
              .eq('is_active', true)
              .eq('username', usernameOrEmail)
              .maybeSingle();
        }
      })();

      if (authResult == null) {
        // User not found
        await _incrementLoginAttempts(usernameOrEmail, userType);
        return {'success': false, 'error': 'Invalid username or password'};
      }

      // Step 2: Verify password hash matches
      if (authResult['password_hash'] != passwordHash) {
        // Password doesn't match
        await _incrementLoginAttempts(usernameOrEmail, userType);
        return {'success': false, 'error': 'Invalid username or password'};
      }

      // Check if account is locked
      if (authResult['account_locked_until'] != null) {
        final lockedUntil = DateTime.parse(authResult['account_locked_until']);
        if (DateTime.now().isBefore(lockedUntil)) {
          return {
            'success': false,
            'error': 'Account temporarily locked. Try again later.'
          };
        }
      }

      // Create session token
      final sessionToken = _generateSessionToken();

      // Store session in database using AuthGuardService
      await _authGuard.createUserSession(
        authResult['user_id'],
        authResult['user_type'],
        sessionToken,
        userAuthId: authResult['id'], // Pass the user_auth_id directly
      );

      // Update last login and reset login attempts
      await _supabase.from('user_authentication').update({
        'last_login': DateTime.now().toIso8601String(),
        'login_attempts': 0,
        'account_locked_until': null,
      }).eq('id', authResult['id']);

      // Store session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_token', sessionToken);

      // Set current user data
      _currentUser = {
        'auth_id': authResult['id'],
        'user_id': authResult['user_id'],
        'username': authResult['username'],
        'email': authResult['email'],
        'user_type': authResult['user_type'],
        'first_name': authResult['users']['first_name'],
        'last_name': authResult['users']['last_name'],
        'display_name': authResult['users']['display_name'],
        'profile_image_url': authResult['users']['profile_image_url'],
        'phone': authResult['users']['phone'],
        'location_city': authResult['users']['location_city'],
      };
      _currentSessionToken = sessionToken;

      return {
        'success': true,
        'user': _currentUser,
        'message': 'Login successful'
      };
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': 'Login failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _loginMock({
    required String usernameOrEmail,
    required String password,
    required String userType,
  }) async {
    final passwordHash = _hashPassword(password);

    // Find authentication record
    final authResults = _mockTables['user_authentication']!.where((auth) {
      final matchesCredentials = (auth['username'] == usernameOrEmail ||
          auth['email'] == usernameOrEmail);
      final matchesPassword = auth['password_hash'] == passwordHash;
      final matchesType = auth['user_type'] == userType;
      final isActive = auth['is_active'] == true;

      return matchesCredentials && matchesPassword && matchesType && isActive;
    }).toList();

    if (authResults.isEmpty) {
      return {'success': false, 'error': 'Invalid credentials'};
    }

    final authResult = authResults.first;

    // Find user record
    final userResults = _mockTables['users']!
        .where((user) => user['id'] == authResult['user_id'])
        .toList();

    if (userResults.isEmpty) {
      return {'success': false, 'error': 'User not found'};
    }

    final userResult = userResults.first;

    // Create session token
    final sessionToken = _generateSessionToken();

    // Store session locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', sessionToken);

    // Set current user data
    _currentUser = {
      'auth_id': authResult['id'],
      'user_id': authResult['user_id'],
      'username': authResult['username'],
      'email': authResult['email'],
      'user_type': authResult['user_type'],
      'first_name': userResult['first_name'],
      'last_name': userResult['last_name'],
      'display_name': userResult['display_name'],
      'profile_image_url': userResult['profile_image_url'],
      'phone': userResult['phone'],
      'location_city': userResult['location_city'],
    };
    _currentSessionToken = sessionToken;

    return {
      'success': true,
      'user': _currentUser,
      'message': 'Login successful'
    };
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      if (!_useMockData) {
        // Invalidate session using AuthGuardService
        await _authGuard.invalidateCurrentSession();
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_token');

      // Clear current user data
      _currentUser = null;
      _currentSessionToken = null;

      print('✅ User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Check if username is available for a specific user type
  Future<bool> isUsernameAvailable(String username, {String? userType}) async {
    try {
      if (_useMockData) {
        final existing = _mockTables['user_authentication']!
            .where((auth) =>
                auth['username'] == username &&
                (userType == null || auth['user_type'] == userType))
            .toList();
        return existing.isEmpty;
      }

      var query = _supabase
          .from('user_authentication')
          .select('username')
          .eq('username', username);

      if (userType != null) {
        query = query.eq('user_type', userType);
      }

      final result = await query.maybeSingle();

      return result == null;
    } catch (e) {
      print('Username check error: $e');
      return false;
    }
  }

  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      if (_useMockData) {
        final existing = _mockTables['user_authentication']!
            .where((auth) => auth['email'] == email)
            .toList();
        return existing.isEmpty;
      }

      final result = await _supabase
          .from('user_authentication')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return result == null;
    } catch (e) {
      print('Email check error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (_currentUser == null) return false;

      if (_useMockData) {
        // Update mock data
        final userIndex = _mockTables['users']!
            .indexWhere((user) => user['id'] == _currentUser!['user_id']);
        if (userIndex != -1) {
          _mockTables['users']![userIndex] = {
            ..._mockTables['users']![userIndex],
            ...updates
          };
        }
      } else {
        // Update users table
        await _supabase
            .from('users')
            .update(updates)
            .eq('id', _currentUser!['user_id']);
      }

      // Update current user data
      _currentUser!.addAll(updates);

      return true;
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        return {'success': false, 'error': 'Not logged in'};
      }

      // Verify current password
      final currentHash = _hashPassword(currentPassword);

      if (_useMockData) {
        final authIndex = _mockTables['user_authentication']!
            .indexWhere((auth) => auth['id'] == _currentUser!['auth_id']);

        if (authIndex == -1 ||
            _mockTables['user_authentication']![authIndex]['password_hash'] !=
                currentHash) {
          return {'success': false, 'error': 'Current password is incorrect'};
        }

        // Update password in mock data
        final newHash = _hashPassword(newPassword);
        _mockTables['user_authentication']![authIndex]['password_hash'] =
            newHash;
      } else {
        final authCheck = await _supabase
            .from('user_authentication')
            .select('id')
            .eq('id', _currentUser!['auth_id'])
            .eq('password_hash', currentHash)
            .maybeSingle();

        if (authCheck == null) {
          return {'success': false, 'error': 'Current password is incorrect'};
        }

        // Update password
        final newHash = _hashPassword(newPassword);
        await _supabase.from('user_authentication').update(
            {'password_hash': newHash}).eq('id', _currentUser!['auth_id']);
      }

      return {'success': true, 'message': 'Password updated successfully'};
    } catch (e) {
      print('Password change error: $e');
      return {'success': false, 'error': 'Failed to update password'};
    }
  }

  /// Private helper methods

  String _hashPassword(String password) {
    final bytes =
        utf8.encode(password + 'helping_hands_salt'); // Add salt for security
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp + _currentUser.toString()).hashCode.toString();
    final bytes = utf8.encode(timestamp + random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> _validateSession(String sessionToken) async {
    try {
      if (_useMockData) {
        // For mock data, just check if we have a stored session
        return sessionToken.isNotEmpty;
      }

      print('🔍 Validating session token...');
      final session = await _supabase
          .from('user_sessions')
          .select('''
            id, user_auth_id, expires_at, is_active,
            user_authentication!inner(
              id, username, email, user_type, user_id,
              users!inner(id, first_name, last_name, display_name, profile_image_url, phone, location_city)
            )
          ''')
          .eq('session_token', sessionToken)
          .eq('is_active', true)
          .maybeSingle();

      if (session == null) {
        print('❌ No active session found for token');
        return false;
      }

      // Check if session is expired
      final expiresAt = DateTime.parse(session['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        print('❌ Session expired at: $expiresAt');
        await _supabase
            .from('user_sessions')
            .update({'is_active': false}).eq('session_token', sessionToken);
        return false;
      }

      // Update last activity
      await _supabase
          .from('user_sessions')
          .update({'last_activity': DateTime.now().toIso8601String()}).eq(
              'session_token', sessionToken);

      // Set current user data
      final auth = session['user_authentication'];
      final user = auth['users'];

      _currentUser = {
        'auth_id': auth['id'],
        'user_id': auth['user_id'],
        'username': auth['username'],
        'email': auth['email'],
        'user_type': auth['user_type'],
        'first_name': user['first_name'],
        'last_name': user['last_name'],
        'display_name': user['display_name'],
        'profile_image_url': user['profile_image_url'],
        'phone': user['phone'],
        'location_city': user['location_city'],
      };
      _currentSessionToken = sessionToken;

      print('✅ Session validated successfully');
      print('   User: ${_currentUser!['username']}');
      print('   Type: ${_currentUser!['user_type']}');
      print('   ID: ${_currentUser!['user_id']}');

      return true;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  Future<void> _incrementLoginAttempts(
      String usernameOrEmail, String userType) async {
    try {
      if (_useMockData) {
        // For mock data, we'll skip this security feature for simplicity
        return;
      }

      final query = _supabase
          .from('user_authentication')
          .select('id, login_attempts')
          .eq('user_type', userType);

      if (usernameOrEmail.contains('@')) {
        query.eq('email', usernameOrEmail);
      } else {
        query.eq('username', usernameOrEmail);
      }

      final result = await query.maybeSingle();

      if (result != null) {
        final attempts = (result['login_attempts'] ?? 0) + 1;
        final updates = {'login_attempts': attempts};

        // Lock account after 5 failed attempts
        if (attempts >= 5) {
          updates['account_locked_until'] =
              DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
        }

        await _supabase
            .from('user_authentication')
            .update(updates)
            .eq('id', result['id']);
      }
    } catch (e) {
      print('Login attempts increment error: $e');
    }
  }
}
