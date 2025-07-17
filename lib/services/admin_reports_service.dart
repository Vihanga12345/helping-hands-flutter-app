import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getJobReports() async {
    // Fetch all job reports
    final response = await _supabase.from('job_reports').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserReports() async {
    // Fetch all user reports
    final response = await _supabase.from('user_reports').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getGeneralReports() async {
    // Fetch all general reports
    final response = await _supabase.from('general_reports').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateReportStatus(
      String reportType, String reportId, String status) async {
    // Update the status of a report
    String tableName;
    switch (reportType) {
      case 'job':
        tableName = 'job_reports';
        break;
      case 'user':
        tableName = 'user_reports';
        break;
      case 'general':
        tableName = 'general_reports';
        break;
      default:
        throw Exception('Invalid report type');
    }
    await _supabase
        .from(tableName)
        .update({'status': status}).eq('id', reportId);
  }
}
