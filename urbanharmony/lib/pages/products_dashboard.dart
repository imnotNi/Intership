import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/firestore/firestore_product.dart';
import './product_admin_page.dart'; // Import the ProductAdminPage

class ProductsDashboardPage extends StatefulWidget {
  const ProductsDashboardPage({super.key});

  @override
  _ProductsDashboardPageState createState() => _ProductsDashboardPageState();
}

class _ProductsDashboardPageState extends State<ProductsDashboardPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  String selectedTimeRange = 'Week'.tr;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to safely get a field from a DocumentSnapshot
  T? getField<T>(DocumentSnapshot doc, String field) {
    try {
      return doc.get(field) as T?;
    } catch (e) {
      print('Field $field does not exist in document ${doc.id}'.tr);
      return null;
    }
  }

  // Helper function to safely get timestamp
  DateTime? getTimestamp(DocumentSnapshot doc, String field) {
    try {
      final timestamp = getField<Timestamp>(doc, field);
      return timestamp?.toDate();
    } catch (e) {
      print('Error getting timestamp for field $field: $e'.tr);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Products'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          unselectedLabelColor: Theme.of(context).colorScheme.secondary,
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'.tr),
            Tab(text: 'Trends'.tr),
            Tab(text: 'Categories'.tr),
            Tab(text: 'Add Products'.tr),
          ],
          labelColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'.tr));
          }

          List<DocumentSnapshot> products = snapshot.data?.docs ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(products),
              _buildTrendsTab(products),
              _buildCategoriesTab(products),
              const ProductAdminPage(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(List<DocumentSnapshot> products) {
    int todayProducts = _countProductsInPeriod(
        products, DateTime.now().subtract(const Duration(days: 1)));
    int weekProducts = _countProductsInPeriod(
        products, DateTime.now().subtract(const Duration(days: 7)));
    int monthProducts = _countProductsInPeriod(
        products, DateTime.now().subtract(const Duration(days: 30)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 20),
          _buildKPICards(todayProducts, weekProducts, monthProducts),
          const SizedBox(height: 20),
          _buildPriceRangeDistribution(products),
          const SizedBox(height: 20),
          _buildRecentProducts(products),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Day'.tr, 'Week'.tr, 'Month'.tr, 'Year'.tr]
                .map((String range) {
              return ChoiceChip(
                selectedColor: Theme.of(context).colorScheme.primary,
                label: Text(
                  range,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary),
                ),
                selected: selectedTimeRange == range,
                onSelected: (bool selected) {
                  setState(() {
                    selectedTimeRange = range;
                  });
                },
              );
            }).toList()),
      ),
    );
  }

  Widget _buildKPICards(
      int todayProducts, int weekProducts, int monthProducts) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'New Products'.tr,
            todayProducts.toString(),
            Icons.add_box,
            Colors.blue,
            weekProducts > 0
                ? '${((todayProducts - weekProducts) / weekProducts * 100).toStringAsFixed(1)}% vs last week'
                : 'No data for comparison'.tr,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Total Products'.tr,
            weekProducts.toString(),
            Icons.inventory_2,
            Colors.green,
            '+${monthProducts - weekProducts} this month',
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color,
      String comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(comparison,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeDistribution(List<DocumentSnapshot> products) {
    Map<String, int> priceRanges = {
      '0-50': 0,
      '51-100': 0,
      '101-500': 0,
      '500+': 0,
    };

    for (var product in products) {
      double price = (getField<num>(product, 'Price') ?? 0).toDouble();
      if (price <= 50) {
        priceRanges['0-50'] = (priceRanges['0-50'] ?? 0) + 1;
      } else if (price <= 100) {
        priceRanges['51-100'] = (priceRanges['51-100'] ?? 0) + 1;
      } else if (price <= 500) {
        priceRanges['101-500'] = (priceRanges['101-500'] ?? 0) + 1;
      } else {
        priceRanges['500+'] = (priceRanges['500+'] ?? 0) + 1;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Range Distribution'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...priceRanges.entries.map((entry) => Column(
                  children: [
                    Row(
                      children: [
                        Text('${entry.key}: '),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: products.isNotEmpty
                                ? entry.value / products.length
                                : 0,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${entry.value}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProducts(List<DocumentSnapshot> products) {
    var sortedProducts = List<DocumentSnapshot>.from(products)
      ..sort((a, b) {
        DateTime? timeA = getTimestamp(a, 'CreatedAt');
        DateTime? timeB = getTimestamp(b, 'CreatedAt');
        if (timeA == null || timeB == null) return 0;
        return timeB.compareTo(timeA);
      });

    var recentProducts = sortedProducts.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recently Added Products'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentProducts.length,
              itemBuilder: (context, index) {
                var product = recentProducts[index];
                DateTime? createdAt = getTimestamp(product, 'CreatedAt');
                String imageUrl = getField<String>(product, 'ImageUrl') ?? '';
                double price =
                    (getField<num>(product, 'Price') ?? 0).toDouble();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.image) : null,
                  ),
                  title: Text(getField<String>(product, 'ProductName') ??
                      'Unnamed Product'),
                  subtitle: Text('\$${price.toStringAsFixed(2)}'),
                  trailing: Text(
                    createdAt != null
                        ? DateFormat.yMMMd().format(createdAt)
                        : 'Date unknown',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(List<DocumentSnapshot> products) {
    List<DailyProductCount> dailyCounts = _getDailyProductCounts(products);

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
                    Text('Product Addition Trend'.tr,
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
            _buildBrandDistributionChart(products),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<DailyProductCount> dailyCounts) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
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
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDistributionChart(List<DocumentSnapshot> products) {
    Map<String, int> brandCounts = {};
    for (var product in products) {
      String brand = getField<String>(product, 'Brand') ?? 'Unknown';
      brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('brand_distribution'.tr, // Dịch tiêu đề
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: brandCounts.values.isEmpty
                      ? 1
                      : brandCounts.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < brandCounts.keys.length) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                brandCounts.keys
                                    .elementAt(value.toInt())
                                    .tr, // Dịch tên thương hiệu
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: brandCounts.entries.map((entry) {
                    return BarChartGroupData(
                      x: brandCounts.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                            toY: entry.value.toDouble(), color: Colors.blue),
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

  Widget _buildCategoriesTab(List<DocumentSnapshot> products) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('error_loading_categories'.tr)); // Dịch lỗi
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
                  'no_categories_found'.tr)); // Dịch thông báo không tìm thấy
        }

        List<DocumentSnapshot> categories = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            DocumentSnapshot category = categories[index];
            String categoryId = category.id;
            String categoryName = getField<String>(category, 'Name') ??
                'unnamed_category'.tr; // Dịch tên danh mục
            String description = getField<String>(category, 'Description') ??
                'no_description'.tr; // Dịch mô tả

            int productCount = products
                .where((product) =>
                    getField<String>(product, 'categoryId') == categoryId)
                .length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(categoryName),
                subtitle: Text(description,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Chip(
                  label: Text(
                      '${productCount} ${'products'.tr}'), // Dịch từ "products"
                  backgroundColor: Colors.blue[100],
                  shadowColor: Colors.black,
                ),
                onTap: () => _showCategoryDetails(category, products),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryDetails(
      DocumentSnapshot category, List<DocumentSnapshot> allProducts) {
    List<DocumentSnapshot> categoryProducts = allProducts
        .where(
            (product) => getField<String>(product, 'categoryId') == category.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      getField<String>(category, 'Name') ??
                          'unnamed_category'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'description:'.tr, // Dịch tiêu đề mô tả
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(getField<String>(category, 'Description') ??
                  'no_description'.tr), // Dịch mô tả
              const SizedBox(height: 16),
              Text(
                'products_in_this_category:'
                    .tr, // Dịch tiêu đề sản phẩm trong danh mục
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: categoryProducts.isEmpty
                    ? Center(
                        child: Text('no_products_in_this_category'
                            .tr)) // Dịch thông báo không có sản phẩm
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: categoryProducts.length,
                        itemBuilder: (context, index) {
                          var product = categoryProducts[index];
                          double price =
                              (getField<num>(product, 'Price') ?? 0).toDouble();
                          String brand = getField<String>(product, 'Brand') ??
                              'unknown_brand'.tr; // Dịch thương hiệu

                          return ListTile(
                            title: Text(
                                getField<String>(product, 'ProductName') ??
                                    'unnamed_product'.tr), // Dịch tên sản phẩm
                            subtitle: Text(brand),
                            trailing: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            leading: const Icon(Icons.shopping_bag),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countProductsInPeriod(
      List<DocumentSnapshot> products, DateTime startDate) {
    return products.where((product) {
      DateTime? createdAt = getTimestamp(product, 'CreatedAt');
      return createdAt != null && createdAt.isAfter(startDate);
    }).length;
  }

  List<DailyProductCount> _getDailyProductCounts(
      List<DocumentSnapshot> products) {
    Map<DateTime, int> dailyCounts = {};

    for (var product in products) {
      DateTime? createdAt = getTimestamp(product, 'CreatedAt');
      if (createdAt != null) {
        DateTime date = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }
    }

    List<DailyProductCount> result = dailyCounts.entries
        .map((e) => DailyProductCount(e.key, e.value))
        .toList();

    result.sort((a, b) => a.date.compareTo(b.date));

    // Ensure we have data for the last 7 days
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (!result.any((item) => _isSameDay(item.date, date))) {
        result.add(DailyProductCount(date, 0));
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
}

class DailyProductCount {
  final DateTime date;
  final int count;

  DailyProductCount(this.date, this.count);
}
