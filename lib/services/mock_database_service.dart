import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal();

  // In-memory storage for development
  static final Map<String, List<Map<String, dynamic>>> _tables = {
    'users': [],
    'user_authentication': [],
    'user_sessions': [],
    'job_categories': [],
    'job_category_questions': [],
    'jobs': [],
    'job_question_answers': [],
  };

  // Initialize with sample data
  Future<void> initialize() async {
    if (_tables['job_categories']!.isEmpty) {
      _initializeSampleData();
    }
  }

  void _initializeSampleData() {
    // Add job categories
    _tables['job_categories'] = [
      {
        'id': '1',
        'name': 'House Cleaning',
        'description': 'General house cleaning services',
        'default_hourly_rate': 2500.0,
        'is_active': true,
      },
      {
        'id': '2',
        'name': 'Deep Cleaning',
        'description': 'Thorough deep cleaning services',
        'default_hourly_rate': 3000.0,
        'is_active': true,
      },
      {
        'id': '3',
        'name': 'Gardening',
        'description': 'Garden maintenance and landscaping',
        'default_hourly_rate': 2000.0,
        'is_active': true,
      },
      {
        'id': '4',
        'name': 'Cooking',
        'description': 'Meal preparation and cooking services',
        'default_hourly_rate': 2200.0,
        'is_active': true,
      },
      {
        'id': '5',
        'name': 'Elderly Care',
        'description': 'Care and assistance for elderly individuals',
        'default_hourly_rate': 2800.0,
        'is_active': true,
      },
    ];

    // Add job category questions
    _tables['job_category_questions'] = [
      {
        'id': '1',
        'category_id': '1',
        'question': 'How many rooms need cleaning?',
        'question_type': 'number',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '2',
        'category_id': '1',
        'question': 'Do you have cleaning supplies?',
        'question_type': 'yes_no',
        'is_required': true,
        'order_index': 2,
      },
      {
        'id': '3',
        'category_id': '2',
        'question': 'What areas need deep cleaning?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '4',
        'category_id': '3',
        'question': 'What type of gardening work is needed?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '5',
        'category_id': '4',
        'question': 'How many people will be served?',
        'question_type': 'number',
        'is_required': true,
        'order_index': 1,
      },
      {
        'id': '6',
        'category_id': '5',
        'question': 'What type of care is needed?',
        'question_type': 'text',
        'is_required': true,
        'order_index': 1,
      },
    ];
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(
    String tableName, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    await initialize();

    if (!_tables.containsKey(tableName)) {
      throw Exception('Table $tableName not found');
    }

    List<Map<String, dynamic>> results = List.from(_tables[tableName]!);

    // Apply where conditions
    if (where != null) {
      results = results.where((row) {
        return where.entries.every((entry) {
          final key = entry.key;
          final value = entry.value;

          if (key.contains('.eq.')) {
            final field = key.split('.eq.')[0];
            return row[field] == value;
          } else if (key.contains('.or.')) {
            // Handle OR conditions (simplified)
            final conditions = value.toString().split(',');
            return conditions.any((condition) {
              final parts = condition.split('.eq.');
              if (parts.length == 2) {
                return row[parts[0]] == parts[1];
              }
              return false;
            });
          } else {
            return row[key] == value;
          }
        });
      }).toList();
    }

    // Apply ordering
    if (orderBy != null) {
      results.sort((a, b) {
        final aVal = a[orderBy];
        final bVal = b[orderBy];

        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return ascending ? -1 : 1;
        if (bVal == null) return ascending ? 1 : -1;

        final comparison = aVal.toString().compareTo(bVal.toString());
        return ascending ? comparison : -comparison;
      });
    }

    // Apply limit
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  // Insert method
  Future<Map<String, dynamic>> insert(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    await initialize();

    if (!_tables.containsKey(tableName)) {
      throw Exception('Table $tableName not found');
    }

    // Generate ID if not provided
    if (!data.containsKey('id')) {
      data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Add timestamps
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();

    _tables[tableName]!.add(Map.from(data));
    return data;
  }

  // Update method
  Future<bool> update(
    String tableName,
    Map<String, dynamic> data,
    Map<String, dynamic> where,
  ) async {
    await initialize();

    if (!_tables.containsKey(tableName)) {
      throw Exception('Table $tableName not found');
    }

    bool updated = false;
    for (int i = 0; i < _tables[tableName]!.length; i++) {
      final row = _tables[tableName]![i];

      bool matches = where.entries.every((entry) {
        return row[entry.key] == entry.value;
      });

      if (matches) {
        _tables[tableName]![i] = {
          ...row,
          ...data,
          'updated_at': DateTime.now().toIso8601String()
        };
        updated = true;
      }
    }

    return updated;
  }

  // Delete method
  Future<bool> delete(
    String tableName,
    Map<String, dynamic> where,
  ) async {
    await initialize();

    if (!_tables.containsKey(tableName)) {
      throw Exception('Table $tableName not found');
    }

    final initialLength = _tables[tableName]!.length;

    _tables[tableName]!.removeWhere((row) {
      return where.entries.every((entry) {
        return row[entry.key] == entry.value;
      });
    });

    return _tables[tableName]!.length < initialLength;
  }

  // RPC method for stored procedures
  Future<dynamic> rpc(String functionName, Map<String, dynamic> params) async {
    await initialize();

    switch (functionName) {
      case 'create_user_with_auth':
        return await _createUserWithAuth(params);
      case 'create_job_with_helpee_details':
        return await _createJobWithHelpeeDetails(params);
      case 'assign_helper_to_job':
        return await _assignHelperToJob(params);
      default:
        throw Exception('RPC function $functionName not implemented');
    }
  }

  // Mock RPC implementations
  Future<String> _createUserWithAuth(Map<String, dynamic> params) async {
    // Create user
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final user = {
      'id': userId,
      'first_name': params['p_first_name'],
      'last_name': params['p_last_name'],
      'phone': params['p_phone'],
      'user_type': params['p_user_type'],
      'email': params['p_email'],
      'username': params['p_username'],
      'display_name': '${params['p_first_name']} ${params['p_last_name']}',
      'is_active': true,
    };

    await insert('users', user);

    // Create authentication record
    final authId = DateTime.now().millisecondsSinceEpoch.toString() + '_auth';
    final auth = {
      'id': authId,
      'user_id': userId,
      'username': params['p_username'],
      'email': params['p_email'],
      'password_hash': params['p_password_hash'],
      'user_type': params['p_user_type'],
      'is_active': true,
      'login_attempts': 0,
    };

    await insert('user_authentication', auth);

    return userId;
  }

  Future<String> _createJobWithHelpeeDetails(
      Map<String, dynamic> params) async {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    final job = {
      'id': jobId,
      'helpee_id': params['p_helpee_id'],
      'category_id': params['p_category_id'],
      'title': params['p_title'],
      'description': params['p_description'],
      'job_type': params['p_job_type'],
      'hourly_rate': params['p_hourly_rate'],
      'scheduled_date': params['p_scheduled_date'],
      'scheduled_start_time': params['p_scheduled_start_time'],
      'location_latitude': params['p_location_latitude'],
      'location_longitude': params['p_location_longitude'],
      'location_address': params['p_location_address'],
      'status': 'pending',
    };

    await insert('jobs', job);
    return jobId;
  }

  Future<bool> _assignHelperToJob(Map<String, dynamic> params) async {
    return await update('jobs', {
      'assigned_helper_id': params['p_helper_id'],
      'status': 'accepted',
    }, {
      'id': params['p_job_id']
    });
  }

  // Helper method to get data from tables
  Map<String, List<Map<String, dynamic>>> get tables => _tables;
}
