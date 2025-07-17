import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import '../../services/admin_reports_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';

class AdminReportListPage extends StatefulWidget {
  final String reportType; // 'job', 'user', or 'general'

  const AdminReportListPage({super.key, required this.reportType});

  @override
  _AdminReportListPageState createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage> {
  final AdminReportsService _reportsService = AdminReportsService();
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<List<Map<String, dynamic>>> _fetchReports() {
    switch (widget.reportType) {
      case 'job':
        return _reportsService.getJobReports();
      case 'user':
        return _reportsService.getUserReports();
      case 'general':
        return _reportsService.getGeneralReports();
      default:
        throw Exception('Invalid report type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeader(title: '${widget.reportType.capitalize()} Reports'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          final reports = snapshot.data!;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ListTile(
                title: Text(
                    report['subject'] ?? report['report_type'] ?? 'No Title'),
                subtitle: Text('Status: ${report['status']}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to report detail page
                },
              );
            },
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
