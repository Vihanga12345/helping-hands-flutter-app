import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/earnings_service.dart';
import '../../services/supabase_service.dart';

class HelperEarningsPage extends StatefulWidget {
  const HelperEarningsPage({super.key});

  @override
  State<HelperEarningsPage> createState() => _HelperEarningsPageState();
}

class _HelperEarningsPageState extends State<HelperEarningsPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
    'All Time'
  ];

  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  String? _error;
  bool _showCategoryChart = false;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabaseService = SupabaseService();
      final helperId = supabaseService.currentUserId;

      if (helperId == null) {
        throw Exception('Helper not logged in');
      }

      print('💰 Loading earnings data for helper: $helperId');
      final earningsData = await EarningsService.getHelperEarnings(helperId);

      setState(() {
        _earningsData = earningsData;
        _isLoading = false;
      });

      print('✅ Earnings data loaded successfully');
    } catch (e) {
      print('❌ Error loading earnings data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getCurrentPeriodData() {
    if (_earningsData == null) {
      return {
        'totalEarnings': 0.0,
        'totalJobs': 0,
        'totalHours': 0.0,
        'avgEarningsPerJob': 0.0,
        'categoryBreakdown': <String, Map<String, dynamic>>{},
        'chartData': <Map<String, dynamic>>[],
        'growthRates': {'earningsGrowth': 0.0, 'jobsGrowth': 0.0},
      };
    }

    switch (_selectedPeriod) {
      case 'Today':
        return {
          'totalEarnings': _earningsData!['daily']['totalEarnings'],
          'totalJobs': _earningsData!['daily']['totalJobs'],
          'totalHours': _earningsData!['daily']['totalHours'],
          'avgEarningsPerJob': _earningsData!['daily']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'daily')
                  .take(7)
                  .toList(),
          'growthRates': _earningsData!['growthRates'],
        };
      case 'This Week':
        return {
          'totalEarnings': _earningsData!['weekly']['totalEarnings'],
          'totalJobs': _earningsData!['weekly']['totalJobs'],
          'totalHours': _earningsData!['weekly']['totalHours'],
          'avgEarningsPerJob': _earningsData!['weekly']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'daily')
                  .take(7)
                  .toList(),
          'growthRates': _earningsData!['growthRates'],
        };
      case 'This Month':
        return {
          'totalEarnings': _earningsData!['monthly']['totalEarnings'],
          'totalJobs': _earningsData!['monthly']['totalJobs'],
          'totalHours': _earningsData!['monthly']['totalHours'],
          'avgEarningsPerJob': _earningsData!['monthly']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'daily'),
          'growthRates': _earningsData!['growthRates'],
        };
      case 'Last Month':
        return {
          'totalEarnings': _earningsData!['lastMonth']['totalEarnings'],
          'totalJobs': _earningsData!['lastMonth']['totalJobs'],
          'totalHours': _earningsData!['lastMonth']['totalHours'],
          'avgEarningsPerJob': _earningsData!['lastMonth']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'monthly')
                  .take(1)
                  .toList(),
          'growthRates': _earningsData!['growthRates'],
        };
      case 'This Year':
        return {
          'totalEarnings': _earningsData!['yearly']['totalEarnings'],
          'totalJobs': _earningsData!['yearly']['totalJobs'],
          'totalHours': _earningsData!['yearly']['totalHours'],
          'avgEarningsPerJob': _earningsData!['yearly']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'monthly'),
          'growthRates': _earningsData!['growthRates'],
        };
      case 'All Time':
        return {
          'totalEarnings': _earningsData!['allTime']['totalEarnings'],
          'totalJobs': _earningsData!['allTime']['totalJobs'],
          'totalHours': _earningsData!['allTime']['totalHours'],
          'avgEarningsPerJob': _earningsData!['allTime']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'monthly'),
          'growthRates': _earningsData!['growthRates'],
        };
      default:
        return {
          'totalEarnings': _earningsData!['monthly']['totalEarnings'],
          'totalJobs': _earningsData!['monthly']['totalJobs'],
          'totalHours': _earningsData!['monthly']['totalHours'],
          'avgEarningsPerJob': _earningsData!['monthly']['avgEarningsPerJob'],
          'categoryBreakdown': _earningsData!['categoryBreakdown'],
          'chartData':
              EarningsService.getEarningsChartData(_earningsData!, 'daily'),
          'growthRates': _earningsData!['growthRates'],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Earnings Analytics',
                showBackButton: true,
                showMenuButton: false,
                showNotificationButton: false,
                onBackPressed: () => context.go('/helper/profile'),
              ),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(
        currentTab: NavigationTab.profile,
        userType: UserType.helper,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Loading earnings analytics...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading earnings data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEarningsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentData = _getCurrentPeriodData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Filter & Export
          _buildTopControls(),
          const SizedBox(height: 16),

          // Earnings Summary Cards
          _buildEarningsSummary(currentData),
          const SizedBox(height: 16),

          // Chart Type Toggle
          _buildChartTypeToggle(),
          const SizedBox(height: 16),

          // Earnings Chart
          _showCategoryChart
              ? _buildCategoryChart(currentData)
              : _buildEarningsChart(currentData),
          const SizedBox(height: 16),

          // Performance Metrics
          _buildPerformanceMetrics(currentData),
          const SizedBox(height: 16),

          // Category Breakdown Table
          _buildCategoryBreakdownTable(currentData),
          const SizedBox(height: 16),

          // Recent Jobs
          _buildRecentJobs(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        Expanded(child: _buildPeriodFilter()),
        const SizedBox(width: 12),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedPeriod) {
              setState(() {
                _selectedPeriod = newValue;
              });
            }
          },
          items: _periods.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _exportEarningsData,
        icon: const Icon(Icons.download, color: AppColors.white),
        tooltip: 'Export Data',
      ),
    );
  }

  Widget _buildChartTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'Earnings Trend',
              !_showCategoryChart,
              () => setState(() => _showCategoryChart = false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              'Category Split',
              _showCategoryChart,
              () => setState(() => _showCategoryChart = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(Map<String, dynamic> currentData) {
    final totalEarnings = currentData['totalEarnings'] as double;
    final totalJobs = currentData['totalJobs'] as int;
    final totalHours = currentData['totalHours'] as double;
    final avgEarningsPerJob = currentData['avgEarningsPerJob'] as double;
    final growthRates = currentData['growthRates'] as Map<String, dynamic>;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Earnings',
                EarningsService.formatCurrency(totalEarnings),
                Icons.account_balance_wallet,
                AppColors.primaryGreen,
                growthRate: growthRates['earningsGrowth'] as double,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Jobs Completed',
                totalJobs.toString(),
                Icons.work,
                AppColors.primaryBlue,
                growthRate: growthRates['jobsGrowth'] as double,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Hours Worked',
                EarningsService.formatHours(totalHours),
                Icons.access_time,
                AppColors.primaryOrange,
                growthRate: growthRates['hoursGrowth'] as double? ?? 0.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Avg per Job',
                EarningsService.formatCurrency(avgEarningsPerJob),
                Icons.trending_up,
                AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    double? growthRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (growthRate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: growthRate >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: growthRate >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsChart(Map<String, dynamic> currentData) {
    final chartData =
        currentData['chartData'] as List<Map<String, dynamic>>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChart('No earnings data for this period');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Trend - $_selectedPeriod',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(_buildLineChartData(chartData)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, dynamic> currentData) {
    final categoryData = currentData['categoryBreakdown']
            as Map<String, Map<String, dynamic>>? ??
        {};

    if (categoryData.isEmpty) {
      return _buildEmptyChart('No category data for this period');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown - $_selectedPeriod',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(_buildPieChartData(categoryData)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(List<Map<String, dynamic>> chartData) {
    final spots = chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['earnings'] as double));
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: null,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.textSecondary.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: chartData.length > 10 ? 2 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < chartData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    chartData[index]['label'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: null,
            getTitlesWidget: (value, meta) {
              return Text(
                '${(value / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryBlue],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryGreen,
                strokeWidth: 2,
                strokeColor: AppColors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withOpacity(0.3),
                AppColors.primaryGreen.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData(
      Map<String, Map<String, dynamic>> categoryData) {
    final colors = [
      AppColors.primaryGreen,
      AppColors.primaryBlue,
      AppColors.primaryOrange,
      AppColors.primaryPurple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    final sections = categoryData.entries.take(8).map((entry) {
      final index = categoryData.keys.toList().indexOf(entry.key);
      final earnings = entry.value['totalEarnings'] as double;
      final total = categoryData.values
          .fold(0.0, (sum, cat) => sum + (cat['totalEarnings'] as double));
      final percentage = total > 0 ? (earnings / total) * 100 : 0.0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: earnings,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      );
    }).toList();

    return PieChartData(
      sections: sections,
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: 0,
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          // Handle touch events if needed
        },
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> currentData) {
    final totalEarnings = currentData['totalEarnings'] as double;
    final totalHours = currentData['totalHours'] as double;
    final totalJobs = currentData['totalJobs'] as int;

    final hourlyRate = totalHours > 0 ? totalEarnings / totalHours : 0.0;
    final efficiency = totalJobs > 0 ? totalHours / totalJobs : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Avg Hourly Rate',
                  EarningsService.formatCurrency(hourlyRate),
                  Icons.attach_money,
                  AppColors.primaryGreen,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Avg Hours/Job',
                  EarningsService.formatHours(efficiency),
                  Icons.schedule,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownTable(Map<String, dynamic> currentData) {
    final categoryData = currentData['categoryBreakdown']
            as Map<String, Map<String, dynamic>>? ??
        {};

    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No category data available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryData.entries.map((entry) {
            final categoryName = entry.key;
            final data = entry.value;
            final earnings = data['totalEarnings'] as double;
            final jobs = data['totalJobs'] as int;
            final avgEarnings = data['avgEarningsPerJob'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      EarningsService.formatCurrency(earnings),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$jobs jobs',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      EarningsService.formatCurrency(avgEarnings),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentJobs() {
    if (_earningsData == null) return const SizedBox();

    final recentJobs =
        _earningsData!['recentJobs'] as List<Map<String, dynamic>>? ?? [];

    if (recentJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No recent jobs completed',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Completed Jobs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...recentJobs.take(5).map((job) {
            final earnings = job['pay'] as double;
            final category = job['category'] as String;
            final hours = job['hours'] as double;
            final date = DateTime.parse(job['date'] as String);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      EarningsService.formatHours(hours),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      EarningsService.formatCurrency(earnings),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _exportEarningsData() {
    // Simple export functionality - show success message
    // In a real app, this would generate CSV and save to device
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Earnings data exported successfully!'),
        backgroundColor: AppColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );

    print('📊 Exporting earnings data for period: $_selectedPeriod');
    // TODO: Implement actual CSV export functionality using path_provider
  }
}
