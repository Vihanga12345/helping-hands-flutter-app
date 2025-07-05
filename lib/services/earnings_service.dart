import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive earnings data for helper
  static Future<Map<String, dynamic>> getHelperEarnings(String helperId) async {
    try {
      print('💰 Fetching earnings data for helper: $helperId');

      // Get all completed jobs for this helper
      final completedJobs = await _supabase
          .from('jobs')
          .select('''
            id, pay, created_at, time_taken_hours, category_id, date, time, status,
            category:job_categories!jobs_category_id_fkey(name)
          ''')
          .eq('assigned_helper_id', helperId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      // Calculate current date boundaries
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      final thisYearStart = DateTime(now.year, 1, 1);

      // Initialize counters
      Map<String, dynamic> stats = {
        'daily': _initializeStats(),
        'weekly': _initializeStats(),
        'monthly': _initializeStats(),
        'lastMonth': _initializeStats(),
        'yearly': _initializeStats(),
        'allTime': _initializeStats(),
        'categoryBreakdown': <String, Map<String, dynamic>>{},
        'dailyEarnings': <String, double>{}, // date -> earnings
        'weeklyEarnings': <String, double>{}, // week -> earnings
        'monthlyEarnings': <String, double>{}, // month -> earnings
        'recentJobs': <Map<String, dynamic>>[],
      };

      // Process each completed job
      for (var job in completedJobs) {
        final jobDate = DateTime.parse(job['created_at']);
        final pay = (job['pay'] ?? 0).toDouble();
        final hours = ((job['time_taken_hours'] ?? 3) as num).toDouble();
        final categoryName = job['category']?['name'] ?? 'Unknown';

        // Update all-time stats
        _updateStats(stats['allTime'], pay, hours, 1);

        // Update yearly stats
        if (jobDate.isAfter(thisYearStart)) {
          _updateStats(stats['yearly'], pay, hours, 1);
        }

        // Update monthly stats
        if (jobDate.isAfter(thisMonthStart)) {
          _updateStats(stats['monthly'], pay, hours, 1);
        }

        // Update last month stats
        if (jobDate.isAfter(lastMonthStart) && jobDate.isBefore(lastMonthEnd)) {
          _updateStats(stats['lastMonth'], pay, hours, 1);
        }

        // Update weekly stats
        if (jobDate.isAfter(thisWeekStart)) {
          _updateStats(stats['weekly'], pay, hours, 1);
        }

        // Update daily stats
        if (jobDate.isAfter(today)) {
          _updateStats(stats['daily'], pay, hours, 1);
        }

        // Update category breakdown
        if (!stats['categoryBreakdown'].containsKey(categoryName)) {
          stats['categoryBreakdown'][categoryName] = _initializeStats();
        }
        _updateStats(stats['categoryBreakdown'][categoryName], pay, hours, 1);

        // Daily earnings tracking (last 30 days)
        final dateKey =
            '${jobDate.year}-${jobDate.month.toString().padLeft(2, '0')}-${jobDate.day.toString().padLeft(2, '0')}';
        if (jobDate.isAfter(now.subtract(const Duration(days: 30)))) {
          stats['dailyEarnings'][dateKey] =
              (stats['dailyEarnings'][dateKey] ?? 0) + pay;
        }

        // Weekly earnings tracking (last 12 weeks)
        final weekKey =
            '${jobDate.year}-W${((jobDate.dayOfYear - 1) / 7).floor() + 1}';
        if (jobDate.isAfter(now.subtract(const Duration(days: 84)))) {
          stats['weeklyEarnings'][weekKey] =
              (stats['weeklyEarnings'][weekKey] ?? 0) + pay;
        }

        // Monthly earnings tracking (last 12 months)
        final monthKey =
            '${jobDate.year}-${jobDate.month.toString().padLeft(2, '0')}';
        if (jobDate.isAfter(now.subtract(const Duration(days: 365)))) {
          stats['monthlyEarnings'][monthKey] =
              (stats['monthlyEarnings'][monthKey] ?? 0) + pay;
        }

        // Recent jobs (last 10)
        if (stats['recentJobs'].length < 10) {
          stats['recentJobs'].add({
            'id': job['id'],
            'pay': pay,
            'date': jobDate.toIso8601String(),
            'hours': hours,
            'category': categoryName,
          });
        }
      }

      // Calculate growth rates
      stats['growthRates'] = _calculateGrowthRates(stats);

      print('✅ Earnings data fetched successfully');
      return stats;
    } catch (e) {
      print('❌ Error fetching earnings data: $e');
      return {
        'daily': _initializeStats(),
        'weekly': _initializeStats(),
        'monthly': _initializeStats(),
        'lastMonth': _initializeStats(),
        'yearly': _initializeStats(),
        'allTime': _initializeStats(),
        'categoryBreakdown': <String, Map<String, dynamic>>{},
        'dailyEarnings': <String, double>{},
        'weeklyEarnings': <String, double>{},
        'monthlyEarnings': <String, double>{},
        'recentJobs': <Map<String, dynamic>>[],
        'growthRates': {
          'earningsGrowth': 0.0,
          'jobsGrowth': 0.0,
          'hoursGrowth': 0.0,
        },
      };
    }
  }

  /// Initialize statistics structure
  static Map<String, dynamic> _initializeStats() {
    return {
      'totalEarnings': 0.0,
      'totalJobs': 0,
      'totalHours': 0.0,
      'avgEarningsPerJob': 0.0,
      'avgHoursPerJob': 0.0,
      'avgEarningsPerHour': 0.0,
    };
  }

  /// Update statistics with new job data
  static void _updateStats(
      Map<String, dynamic> stats, double pay, double hours, int jobs) {
    stats['totalEarnings'] += pay;
    stats['totalJobs'] += jobs;
    stats['totalHours'] += hours;

    // Calculate averages
    if (stats['totalJobs'] > 0) {
      stats['avgEarningsPerJob'] = stats['totalEarnings'] / stats['totalJobs'];
    }
    if (stats['totalHours'] > 0) {
      stats['avgEarningsPerHour'] =
          stats['totalEarnings'] / stats['totalHours'];
    }
    if (stats['totalJobs'] > 0) {
      stats['avgHoursPerJob'] = stats['totalHours'] / stats['totalJobs'];
    }
  }

  /// Calculate growth rates
  static Map<String, dynamic> _calculateGrowthRates(
      Map<String, dynamic> stats) {
    final currentMonth = stats['monthly'];
    final lastMonth = stats['lastMonth'];

    double earningsGrowth = 0.0;
    double jobsGrowth = 0.0;
    double hoursGrowth = 0.0;

    if (lastMonth['totalEarnings'] > 0) {
      earningsGrowth =
          ((currentMonth['totalEarnings'] - lastMonth['totalEarnings']) /
                  lastMonth['totalEarnings']) *
              100;
    }

    if (lastMonth['totalJobs'] > 0) {
      jobsGrowth = ((currentMonth['totalJobs'] - lastMonth['totalJobs']) /
              lastMonth['totalJobs']) *
          100;
    }

    if (lastMonth['totalHours'] > 0) {
      hoursGrowth = ((currentMonth['totalHours'] - lastMonth['totalHours']) /
              lastMonth['totalHours']) *
          100;
    }

    return {
      'earningsGrowth': earningsGrowth,
      'jobsGrowth': jobsGrowth,
      'hoursGrowth': hoursGrowth,
    };
  }

  /// Get earnings chart data for specific period
  static List<Map<String, dynamic>> getEarningsChartData(
      Map<String, dynamic> earningsData, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return _getDailyChartData(earningsData['dailyEarnings']);
      case 'weekly':
        return _getWeeklyChartData(earningsData['weeklyEarnings']);
      case 'monthly':
        return _getMonthlyChartData(earningsData['monthlyEarnings']);
      default:
        return _getDailyChartData(earningsData['dailyEarnings']);
    }
  }

  /// Get daily chart data (last 30 days)
  static List<Map<String, dynamic>> _getDailyChartData(
      Map<String, double> dailyEarnings) {
    final now = DateTime.now();
    final chartData = <Map<String, dynamic>>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final earnings = dailyEarnings[dateKey] ?? 0.0;

      chartData.add({
        'date': date,
        'earnings': earnings,
        'label': '${date.day}/${date.month}',
      });
    }

    return chartData;
  }

  /// Get weekly chart data (last 12 weeks)
  static List<Map<String, dynamic>> _getWeeklyChartData(
      Map<String, double> weeklyEarnings) {
    final now = DateTime.now();
    final chartData = <Map<String, dynamic>>[];

    for (int i = 11; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * 7));
      final weekKey = '${date.year}-W${((date.dayOfYear - 1) / 7).floor() + 1}';
      final earnings = weeklyEarnings[weekKey] ?? 0.0;

      chartData.add({
        'date': date,
        'earnings': earnings,
        'label': 'W${((date.dayOfYear - 1) / 7).floor() + 1}',
      });
    }

    return chartData;
  }

  /// Get monthly chart data (last 12 months)
  static List<Map<String, dynamic>> _getMonthlyChartData(
      Map<String, double> monthlyEarnings) {
    final now = DateTime.now();
    final chartData = <Map<String, dynamic>>[];

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final earnings = monthlyEarnings[monthKey] ?? 0.0;

      chartData.add({
        'date': date,
        'earnings': earnings,
        'label': '${date.month}/${date.year}',
      });
    }

    return chartData;
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Format hours for display
  static String formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()} mins';
    }
    return '${hours.toStringAsFixed(1)} hrs';
  }
}

extension on DateTime {
  int get dayOfYear {
    return this.difference(DateTime(this.year, 1, 1)).inDays + 1;
  }
}
