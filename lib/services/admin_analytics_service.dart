import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_auth_service.dart';

class AdminAnalyticsService {
  static final AdminAnalyticsService _instance =
      AdminAnalyticsService._internal();
  factory AdminAnalyticsService() => _instance;
  AdminAnalyticsService._internal();

  final _supabase = Supabase.instance.client;
  final _adminAuth = AdminAuthService();

  // ============================================================================
  // DASHBOARD METRICS
  // ============================================================================

  /// Get comprehensive dashboard statistics
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      await _logAnalyticsAction('get_dashboard_metrics');

      final stats = await _supabase.rpc('get_admin_dashboard_stats');

      return {
        'overview': stats,
        'timestamp': DateTime.now().toIso8601String(),
        'generated_by': _adminAuth.currentAdminUsername,
      };
    } catch (e) {
      print('❌ Error getting dashboard metrics: $e');
      rethrow;
    }
  }

  /// Get daily job statistics for charts
  Future<List<Map<String, dynamic>>> getDailyJobStats({int days = 30}) async {
    try {
      await _logAnalyticsAction('get_daily_job_stats', {'days': days});

      final response = await _supabase
          .from('daily_job_stats')
          .select('*')
          .order('job_date', ascending: false)
          .limit(days);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting daily job stats: $e');
      rethrow;
    }
  }

  /// Get category performance data
  Future<List<Map<String, dynamic>>> getCategoryPerformance() async {
    try {
      await _logAnalyticsAction('get_category_performance');

      final response = await _supabase
          .from('category_performance_stats')
          .select('*')
          .order('total_jobs', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting category performance: $e');
      rethrow;
    }
  }

  /// Get user registration trends
  Future<List<Map<String, dynamic>>> getUserRegistrationTrends(
      {int days = 30}) async {
    try {
      await _logAnalyticsAction('get_user_registration_trends', {'days': days});

      final response = await _supabase
          .from('user_registration_stats')
          .select('*')
          .order('registration_date', ascending: false)
          .limit(days);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting user registration trends: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CHART DATA PREPARATION
  // ============================================================================

  /// Prepare line chart data for daily job trends
  Map<String, dynamic> prepareJobTrendChartData(
      List<Map<String, dynamic>> dailyStats) {
    final chartData = <Map<String, dynamic>>[];
    final dates = <String>[];

    for (final stat in dailyStats.reversed) {
      final date = DateTime.parse(stat['job_date']);
      dates.add(_formatDateForChart(date));

      chartData.add({
        'date': date,
        'dateLabel': _formatDateForChart(date),
        'pending': stat['pending_jobs'] ?? 0,
        'accepted': stat['accepted_jobs'] ?? 0,
        'completed': stat['completed_jobs'] ?? 0,
        'total': stat['total_jobs'] ?? 0,
      });
    }

    return {
      'data': chartData,
      'dates': dates,
      'maxValue': chartData.isNotEmpty
          ? chartData
              .map((d) => d['total'] as int)
              .reduce((a, b) => a > b ? a : b)
          : 0,
    };
  }

  /// Prepare pie chart data for category distribution
  Map<String, dynamic> prepareCategoryChartData(
      List<Map<String, dynamic>> categoryStats) {
    final chartData = <Map<String, dynamic>>[];
    final total = categoryStats.fold<int>(
        0, (sum, cat) => sum + (cat['total_jobs'] as int? ?? 0));

    for (final category in categoryStats) {
      final jobCount = category['total_jobs'] as int? ?? 0;
      final percentage = total > 0 ? (jobCount / total * 100).round() : 0;

      chartData.add({
        'category': category['category_name'] ?? 'Unknown',
        'count': jobCount,
        'percentage': percentage,
        'avgRating': category['avg_rating'] ?? 0.0,
        'color': _getCategoryColor(category['category_name']),
      });
    }

    return {
      'data': chartData,
      'total': total,
    };
  }

  /// Prepare bar chart data for user growth
  Map<String, dynamic> prepareUserGrowthChartData(
      List<Map<String, dynamic>> registrationStats) {
    final chartData = <Map<String, dynamic>>[];

    for (final stat in registrationStats.reversed) {
      final date = DateTime.parse(stat['registration_date']);

      chartData.add({
        'date': date,
        'dateLabel': _formatDateForChart(date),
        'helpees': stat['helpee_registrations'] ?? 0,
        'helpers': stat['helper_registrations'] ?? 0,
        'total': stat['total_registrations'] ?? 0,
      });
    }

    final maxValue = chartData.isNotEmpty
        ? chartData
            .map((d) => d['total'] as int)
            .reduce((a, b) => a > b ? a : b)
        : 0;

    return {
      'data': chartData,
      'maxValue': maxValue,
    };
  }

  // ============================================================================
  // PERFORMANCE METRICS
  // ============================================================================

  /// Calculate system performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      await _logAnalyticsAction('get_performance_metrics');

      // Get current stats
      final currentStats = await _supabase.rpc('get_admin_dashboard_stats');

      // Get previous period stats for comparison
      final previousPeriodDate =
          DateTime.now().subtract(const Duration(days: 30));
      final previousStats = await _supabase
          .from('system_analytics')
          .select('*')
          .gte('created_at', previousPeriodDate.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return {
        'current': currentStats,
        'previous': previousStats,
        'trends': _calculateTrends(currentStats, previousStats),
        'calculated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting performance metrics: $e');
      rethrow;
    }
  }

  /// Calculate revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics() async {
    try {
      await _logAnalyticsAction('get_revenue_analytics');

      // Get completed jobs with payment information
      final completedJobs = await _supabase
          .from('jobs')
          .select('total_amount, created_at, helper_id, helpee_id')
          .eq('status', 'completed')
          .not('total_amount', 'is', null)
          .order('created_at', ascending: false);

      final totalRevenue = completedJobs.fold<double>(
        0.0,
        (sum, job) => sum + (job['total_amount'] as num? ?? 0).toDouble(),
      );

      final averageJobValue =
          completedJobs.isNotEmpty ? totalRevenue / completedJobs.length : 0.0;

      return {
        'total_revenue': totalRevenue,
        'total_completed_jobs': completedJobs.length,
        'average_job_value': averageJobValue,
        'monthly_breakdown': _calculateMonthlyRevenue(completedJobs),
      };
    } catch (e) {
      print('❌ Error getting revenue analytics: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Calculate trends between current and previous periods
  Map<String, dynamic> _calculateTrends(
    Map<String, dynamic> current,
    Map<String, dynamic>? previous,
  ) {
    if (previous == null) {
      return {
        'users_trend': 0.0,
        'jobs_trend': 0.0,
        'revenue_trend': 0.0,
        'completion_rate_trend': 0.0,
      };
    }

    return {
      'users_trend': _calculatePercentageChange(
        current['total_users'],
        previous['total_users'],
      ),
      'jobs_trend': _calculatePercentageChange(
        current['total_jobs'],
        previous['total_jobs'],
      ),
      'revenue_trend': _calculatePercentageChange(
        current['total_revenue'],
        previous['total_revenue'],
      ),
      'completion_rate_trend': _calculatePercentageChange(
        current['completion_rate'],
        previous['completion_rate'],
      ),
    };
  }

  /// Calculate percentage change between two values
  double _calculatePercentageChange(dynamic current, dynamic previous) {
    final currentVal = (current as num?)?.toDouble() ?? 0.0;
    final previousVal = (previous as num?)?.toDouble() ?? 0.0;

    if (previousVal == 0) return currentVal > 0 ? 100.0 : 0.0;

    return ((currentVal - previousVal) / previousVal) * 100.0;
  }

  /// Calculate monthly revenue breakdown
  List<Map<String, dynamic>> _calculateMonthlyRevenue(List<dynamic> jobs) {
    final monthlyData = <String, double>{};

    for (final job in jobs) {
      final date = DateTime.parse(job['created_at']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = (job['total_amount'] as num?)?.toDouble() ?? 0.0;

      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + amount;
    }

    return monthlyData.entries
        .map((entry) => {
              'month': entry.key,
              'revenue': entry.value,
            })
        .toList()
      ..sort((a, b) => a['month'].compareTo(b['month']));
  }

  /// Format date for chart display
  String _formatDateForChart(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get color for category (for charts)
  String _getCategoryColor(String? categoryName) {
    final colors = [
      '#2196F3',
      '#4CAF50',
      '#FF9800',
      '#9C27B0',
      '#F44336',
      '#009688',
      '#795548',
      '#607D8B'
    ];

    if (categoryName == null) return colors[0];

    final index = categoryName.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Log analytics action for audit trail
  Future<void> _logAnalyticsAction(String action,
      [Map<String, dynamic>? details]) async {
    try {
      if (_adminAuth.isLoggedIn) {
        await _adminAuth.logAction(
          'view',
          'analytics',
          actionDetails: {
            'analytics_action': action,
            ...?details,
          },
        );
      }
    } catch (e) {
      print('⚠️ Warning: Failed to log analytics action: $e');
    }
  }
}
