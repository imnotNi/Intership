import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/pages/user_page.dart';
import '../models/user.dart';
import '../services/database/database_service.dart';

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  _DashboardUserPageState createState() => _DashboardUserPageState();
}

class _DashboardUserPageState extends State<DashboardUserPage> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  bool _isLoading = true;
  int _weeklyUsers = 0;
  int _monthlyUsers = 0;
  int _yearlyUsers = 0;
  double _weeklyGrowthRate = 0;
  double _monthlyGrowthRate = 0;
  List<Map<String, dynamic>> _weeklyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final weekly = await _databaseService.getNewUsersCount(period: const Duration(days: 7));
      final monthly = await _databaseService.getNewUsersCount(period: const Duration(days: 30));
      final yearly = await _databaseService.getNewUsersCount(period: const Duration(days: 365));

      final weeklyGrowth = await _databaseService.getUserGrowthRate(period: const Duration(days: 7));
      final monthlyGrowth = await _databaseService.getUserGrowthRate(period: const Duration(days: 30));

      final weeklyData = await _databaseService.getWeeklyNewUsersData();

      setState(() {
        _weeklyUsers = weekly;
        _monthlyUsers = monthly;
        _yearlyUsers = yearly;
        _weeklyGrowthRate = weeklyGrowth;
        _monthlyGrowthRate = monthlyGrowth;
        _weeklyData = weeklyData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e'.tr);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title:  Text('Users Dashboard'.tr),
        bottom: TabBar(
          unselectedLabelColor: Theme.of(context).colorScheme.secondary,
          controller: _tabController,
          tabs:  [
            Tab(text: 'Statistics'.tr),
            Tab(text: 'Manage Users'.tr),
          ],
          labelColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          const UsersPage(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 14),
            _buildWeeklyChart(),
            const SizedBox(height: 14),
            _buildRecentUsersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Weekly New Users'.tr,
          _weeklyUsers,
          _weeklyGrowthRate,
          Colors.blue,
        ),
        _buildStatCard(
          'Monthly New Users'.tr,
          _monthlyUsers,
          _monthlyGrowthRate,
          Colors.green,
        ),
        _buildStatCard(
          'Yearly New Users'.tr,
          _yearlyUsers,
          null,
          Colors.orange,
        ),
        _buildRetentionCard(),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, double? growthRate, Color color) {
    return Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionCard() {
    return FutureBuilder<double>(
      future: _databaseService.getUserRetentionRate(period: const Duration(days: 30)),
      builder: (context, snapshot) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Retention'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (snapshot.hasData)
                  Expanded(
                    child: Text(
                      '${snapshot.data!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  Expanded(
                    child: Text('Error loading retention'.tr),
                  )
                else
                  const Expanded(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Growth Trend'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _weeklyData.isEmpty
                      ? 10
                      : (_weeklyData.map((e) => e['users'] as int).reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _weeklyData.length) return const Text('');
                          return Text(
                            _weeklyData[value.toInt()]['week'],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['users'].toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    return FutureBuilder<List<UserProfile>>(
      future: _databaseService.getRecentNewUsers(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'.tr));
        }
        final users = snapshot.data ?? [];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent New Users'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name[0]),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Text(
                        _databaseService.formatTimestamp(user.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}