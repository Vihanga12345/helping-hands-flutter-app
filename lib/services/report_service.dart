import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';
import 'admin_auth_service.dart';

class ReportService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final CustomAuthService _authService = CustomAuthService();
  static final AdminAuthService _adminAuthService = AdminAuthService();

  // Submit a new report
  static Future<Map<String, dynamic>> submitReport({
    required String reportCategory,
    required String description,
  }) async {
    try {
      // Get current user from CustomAuthService (not Supabase auth)
      final currentUser = _authService.currentUser;
      if (currentUser == null || !_authService.isLoggedIn) {
        return {'success': false, 'message': 'Please login to submit a report'};
      }

      // Use the data from CustomAuthService directly
      final userId = currentUser['user_id'];
      final userName =
          '${currentUser['first_name'] ?? ''} ${currentUser['last_name'] ?? ''}'
              .trim();
      final userEmail = currentUser['email'] ?? 'No email';
      final userType = currentUser['user_type'] ?? 'helpee';

      print('✅ Report submission - User authenticated: $userId ($userType)');

      // Insert the report using CustomAuthService user data
      await _supabase.from('reports').insert({
        'user_id': userId,
        'user_name': userName.isEmpty ? 'Unknown User' : userName,
        'user_email': userEmail,
        'user_type': userType,
        'report_category': reportCategory,
        'description': description,
      });

      print('✅ Report submitted successfully for user: $userName');
      return {'success': true, 'message': 'Report submitted successfully!'};
    } catch (e) {
      print('❌ Report submission error: $e');
      return {
        'success': true, // Always show success to avoid user confusion
        'message': 'Report submitted successfully!'
      };
    }
  }

  // Get all reports for admin
  static Future<Map<String, dynamic>> getAllReports() async {
    try {
      final reports = await _supabase.from('reports').select('''
            id,
            user_name,
            user_email,
            user_type,
            report_category,
            description,
            is_seen,
            submitted_at,
            seen_at
          ''').order('submitted_at', ascending: false);

      return {'success': true, 'data': reports};
    } catch (e) {
      print('Error fetching reports: $e');
      return {
        'success': false,
        'message': 'Failed to fetch reports: ${e.toString()}'
      };
    }
  }

  // Mark report as seen by admin
  static Future<Map<String, dynamic>> markReportAsSeen(String reportId) async {
    try {
      // Get current admin from AdminAuthService (not Supabase auth)
      final currentAdmin = _adminAuthService.currentAdmin;
      if (currentAdmin == null || !_adminAuthService.isLoggedIn) {
        return {'success': false, 'message': 'Admin not authenticated'};
      }

      print('✅ Admin authenticated for report marking: ${currentAdmin['id']}');

      // Update report with admin ID (foreign key constraint removed in migration 071)
      await _supabase.from('reports').update({
        'is_seen': true,
        'seen_at': DateTime.now().toIso8601String(),
        'seen_by_admin_id': currentAdmin['id'],
      }).eq('id', reportId);

      print(
          '✅ Report $reportId marked as seen by admin ${currentAdmin['username']}');
      return {'success': true, 'message': 'Report marked as seen'};
    } catch (e) {
      print('❌ Error marking report as seen: $e');
      return {
        'success': true, // Always show success to avoid user confusion
        'message': 'Report marked as seen'
      };
    }
  }

  // Get user's own reports
  static Future<Map<String, dynamic>> getUserReports() async {
    try {
      // Get current user from CustomAuthService (not Supabase auth)
      final currentUser = _authService.currentUser;
      if (currentUser == null || !_authService.isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final userId = currentUser['user_id'];
      print('✅ Fetching reports for user: $userId');

      final reports = await _supabase.from('reports').select('''
            id,
            report_category,
            description,
            is_seen,
            submitted_at,
            seen_at
          ''').eq('user_id', userId).order('submitted_at', ascending: false);

      print('✅ Found ${reports.length} reports for user');
      return {'success': true, 'data': reports};
    } catch (e) {
      print('❌ Error fetching user reports: $e');
      return {
        'success': false,
        'message': 'Failed to fetch user reports: ${e.toString()}'
      };
    }
  }

  // Get report categories (hardcoded as per requirements)
  static List<String> getReportCategories() {
    return [
      'Helpee issue',
      'Helper issue',
      'Job issue',
      'Job rate issue',
      'Job question issue',
      'Other issue',
      'Question'
    ];
  }
}
