import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../services/firestore/firestore_feedback.dart';
import '../services/auth/auth_service.dart';

class AdvancedDashboardPage extends StatefulWidget {
  const AdvancedDashboardPage({super.key});

  @override
  _AdvancedDashboardPageState createState() => _AdvancedDashboardPageState();
}

class _AdvancedDashboardPageState extends State<AdvancedDashboardPage>
    with SingleTickerProviderStateMixin {
  final FirestoreFeedback firestoreFeedback = FirestoreFeedback();
  late TabController _tabController;
  String selectedTimeRange = 'Week'.tr;
  bool isLoading = false;
  Map<String, double> sentimentData = {
    'Positive': 30,
    'Neutral': 50,
    'Negative': 20,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title:  Text('Advanced Analytics Dashboard'.tr),
        bottom: TabBar(
          unselectedLabelColor: Theme.of(context).colorScheme.secondary,
          controller: _tabController,
          tabs:  [
            Tab(text: 'Overview'.tr),
            Tab(text: 'Trends'.tr),
            Tab(text: 'Feedback Management'.tr),
          ],
          labelColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreFeedback.getFeedbackStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'.tr));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(child: Text('No feedback data available'.tr));
          }

          List<DocumentSnapshot> feedbacks = snapshot.data!.docs;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(feedbacks),
              _buildTrendsTab(feedbacks),
              FeedbackAdminPage(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportData,
        tooltip: 'Export Data'.tr,
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildOverviewTab(List<DocumentSnapshot> feedbacks) {
    int lastWeek = _countFeedbacksInPeriod(
        feedbacks, DateTime.now().subtract(const Duration(days: 7)));
    int lastDay = _countFeedbacksInPeriod(
        feedbacks, DateTime.now().subtract(const Duration(days: 1)));
    int lastMonth = _countFeedbacksInPeriod(
        feedbacks, DateTime.now().subtract(const Duration(days: 30)));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeRangeSelector(),
            const SizedBox(height: 20),
            _buildKPICards(lastDay, lastWeek, lastMonth),
            const SizedBox(height: 20),
            _buildSentimentAnalysis(),
            const SizedBox(height: 20),
            _buildRecentFeedbacks(feedbacks),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(List<DocumentSnapshot> feedbacks) {
    List<DailyFeedbackCount> dailyCounts = _getDailyFeedbackCounts(feedbacks);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('Feedback Volume Trend'.tr,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: _buildLineChart(dailyCounts),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('Category Distribution'.tr,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: _buildCategoryBarChart(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Day'.tr, 'Week'.tr, 'Month'.tr, 'Year'.tr].map((String range) {
            return ChoiceChip(
              selectedColor: Theme.of(context).colorScheme.primary,
              label: Text(range,style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
              selected: selectedTimeRange == range,
              onSelected: (bool selected) {
                setState(() {
                  selectedTimeRange = range;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKPICards(int lastDay, int lastWeek, int lastMonth) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Feedback'.tr,
            lastMonth.toString(),
            Icons.feedback,
            Colors.blue,
            '${((lastWeek - lastDay) / lastDay * 100).toStringAsFixed(1)}% vs last week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Average Rating'.tr,
            '4.2',
            Icons.star,
            Colors.amber,
            '+0.3 vs last week'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color,
      String comparison) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(16, 16, 12, 16), // Giảm padding bên phải
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              comparison,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Sentiment Analysis'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSentimentIndicator(
                    'Positive'.tr, sentimentData['Positive']!, Colors.green),
                _buildSentimentIndicator(
                    'Neutral'.tr, sentimentData['Neutral']!, Colors.grey),
                _buildSentimentIndicator(
                    'Negative'.tr, sentimentData['Negative']!, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentIndicator(
      String label, double percentage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
            ),
            Text('${percentage.toStringAsFixed(0)}%',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildRecentFeedbacks(List<DocumentSnapshot> feedbacks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Recent Feedback'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(5, feedbacks.length),
              itemBuilder: (context, index) {
                Map<String, dynamic>? data =
                    feedbacks[index].data() as Map<String, dynamic>?;

                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(data?['message']?.toString() ?? 'No message'),
                  subtitle: Text(DateFormat.yMMMd().format(
                      (data?['createdAt'] as Timestamp? ?? Timestamp.now())
                          .toDate())),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data?['rating']?.toString() ?? 'N/A'),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return  Text('Bug'.tr);
                  case 1:
                    return  Text('Feature'.tr);
                  case 2:
                    return  Text('UI/UX'.tr);
                  case 3:
                    return  Text('Other'.tr);
                  default:
                    return  Text(''.tr);
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
              interval: 20,
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
              x: 0, barRods: [BarChartRodData(toY: 75, color: Colors.blue)]),
          BarChartGroupData(
              x: 1, barRods: [BarChartRodData(toY: 45, color: Colors.blue)]),
          BarChartGroupData(
              x: 2, barRods: [BarChartRodData(toY: 60, color: Colors.blue)]),
          BarChartGroupData(
              x: 3, barRods: [BarChartRodData(toY: 30, color: Colors.blue)]),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<DailyFeedbackCount> dailyCounts) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
            show: true, drawHorizontalLine: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dailyCounts.length) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      DateFormat('MM/dd')
                          .format(dailyCounts[value.toInt()].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(),
                    style: const TextStyle(fontSize: 10));
              },
              interval: 5,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: dailyCounts.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  int _countFeedbacksInPeriod(
      List<DocumentSnapshot> feedbacks, DateTime startDate) {
    return feedbacks.where((feedback) {
      Timestamp createdAt = feedback['createdAt'] as Timestamp;
      return createdAt.toDate().isAfter(startDate);
    }).length;
  }

  List<DailyFeedbackCount> _getDailyFeedbackCounts(
      List<DocumentSnapshot> feedbacks) {
    Map<DateTime, int> dailyCounts = {};

    for (var feedback in feedbacks) {
      Timestamp createdAt = feedback['createdAt'] as Timestamp;
      DateTime date = DateTime(
        createdAt.toDate().year,
        createdAt.toDate().month,
        createdAt.toDate().day,
      );

      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }

    List<DailyFeedbackCount> result = dailyCounts.entries
        .map((e) => DailyFeedbackCount(e.key, e.value))
        .toList();

    result.sort((a, b) => a.date.compareTo(b.date));

    // Ensure we have data for the last 7 days
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (!result.any((item) => _isSameDay(item.date, date))) {
        result.add(DailyFeedbackCount(date, 0));
      }
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result.take(7).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _exportData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate export process
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Data exported successfully'.tr)),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackAdminPage> {
  final _auth = AuthService();
  final FirestoreFeedback _firestoreFeedback = FirestoreFeedback();
  final TextEditingController _replyController = TextEditingController();
  String? _selectedFeedbackId;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreFeedback.getFeedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return  Text('Something went wrong'.tr);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            bool isSelected = _selectedFeedbackId == document.id;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(data['message']),
                    subtitle: Row(
                      children: [
                         Text('Rating:'.tr),
                        ...List.generate(
                          data['rating'],
                          (index) => const Icon(Icons.star,
                              size: 18, color: Colors.amber),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.reply),
                          onPressed: () {
                            setState(() {
                              _selectedFeedbackId =
                                  isSelected ? null : document.id;
                            });
                          },
                        ),
                        if (data['userId'] == _auth.getCurrentUID())
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _firestoreFeedback.deleteFeedback(document.id);
                            },
                          ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreFeedback.getRepliesStream(document.id),
                      builder: (context, repliesSnapshot) {
                        if (!repliesSnapshot.hasData) {
                          return const SizedBox();
                        }

                        return Column(
                          children: repliesSnapshot.data!.docs.map((reply) {
                            Map<String, dynamic> replyData =
                                reply.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: ListTile(
                                title: Text(replyData['message']),
                                subtitle:
                                    // Text('Reply from: ${replyData['userId']}'),
                                Text('reply_from'.tr + ': ${replyData['userId']}'),
                                trailing:
                                    replyData['userId'] == _auth.getCurrentUID()
                                        ? IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              _firestoreFeedback.deleteReply(
                                                  document.id, reply.id);
                                            },
                                          )
                                        : null,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              decoration:  InputDecoration(
                                hintText: 'Write a reply...'.tr,
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              if (_replyController.text.isNotEmpty) {
                                _firestoreFeedback.addReply(
                                  document.id,
                                  _auth.getCurrentUID(),
                                  _replyController.text,
                                );
                                _replyController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class DailyFeedbackCount {
  final DateTime date;
  final int count;

  DailyFeedbackCount(this.date, this.count);
}
