import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  
  Map<String, dynamic>? _systemAnalytics;
  bool _isLoading = true;
  String _selectedTimeframe = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await _databaseService.getSystemAnalytics();
      setState(() {
        _systemAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedTimeframe = value);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedTimeframe.toUpperCase()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Orders', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Revenue', icon: Icon(Icons.monetization_on)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrdersTab(),
                _buildUsersTab(),
                _buildRevenueTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_systemAnalytics == null) {
      return const Center(child: Text('No data available'));
    }

    final analytics = _systemAnalytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key Metrics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                'Total Orders',
                analytics['totalOrders']?.toString() ?? '0',
                Icons.shopping_cart,
                Colors.blue,
              ),
              _buildMetricCard(
                'Active Drivers',
                analytics['activeDrivers']?.toString() ?? '0',
                Icons.local_shipping,
                Colors.green,
              ),
              _buildMetricCard(
                'Total Revenue',
                '\$${analytics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money,
                Colors.purple,
              ),
              _buildMetricCard(
                'Completion Rate',
                '${(analytics['completionRate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.check_circle,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Order Status Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Status Distribution',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildOrderStatusChart(analytics['ordersByStatus'] ?? {}),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_systemAnalytics == null) {
      return const Center(child: Text('No data available'));
    }

    final analytics = _systemAnalytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order Statistics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                'Pending Orders',
                analytics['ordersByStatus']?['pending']?.toString() ?? '0',
                Icons.pending,
                Colors.orange,
              ),
              _buildMetricCard(
                'In Transit',
                analytics['ordersByStatus']?['in_transit']?.toString() ?? '0',
                Icons.local_shipping,
                Colors.blue,
              ),
              _buildMetricCard(
                'Delivered',
                analytics['ordersByStatus']?['delivered']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              _buildMetricCard(
                'Cancelled',
                analytics['ordersByStatus']?['cancelled']?.toString() ?? '0',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Average Delivery Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Metrics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.blue),
                    title: const Text('Average Delivery Time'),
                    trailing: Text(
                      '${analytics['avgDeliveryTime']?.toStringAsFixed(1) ?? '0'} min',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Average Rating'),
                    trailing: Text(
                      '${analytics['avgRating']?.toStringAsFixed(1) ?? '0'}/5',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.route, color: Colors.green),
                    title: const Text('Average Distance'),
                    trailing: Text(
                      '${analytics['avgDistance']?.toStringAsFixed(1) ?? '0'} km',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_systemAnalytics == null) {
      return const Center(child: Text('No data available'));
    }

    final analytics = _systemAnalytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Statistics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                'Total Customers',
                analytics['totalCustomers']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildMetricCard(
                'Total Drivers',
                analytics['totalDrivers']?.toString() ?? '0',
                Icons.local_shipping,
                Colors.green,
              ),
              _buildMetricCard(
                'New Users',
                analytics['newUsers']?.toString() ?? '0',
                Icons.person_add,
                Colors.purple,
              ),
              _buildMetricCard(
                'Active Users',
                analytics['activeUsers']?.toString() ?? '0',
                Icons.online_prediction,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top Performers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Performing Drivers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTopDriversList(analytics['topDrivers'] ?? []),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Customer Insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.repeat, color: Colors.green),
                    title: const Text('Repeat Customers'),
                    trailing: Text(
                      '${analytics['repeatCustomers']?.toString() ?? '0'}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.blue),
                    title: const Text('Avg. Orders per Customer'),
                    trailing: Text(
                      analytics['avgOrdersPerCustomer']?.toStringAsFixed(1) ?? '0',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    if (_systemAnalytics == null) {
      return const Center(child: Text('No data available'));
    }

    final analytics = _systemAnalytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Revenue Metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                'Total Revenue',
                '\$${analytics['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildMetricCard(
                'Driver Earnings',
                '\$${analytics['driverEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
              _buildMetricCard(
                'Platform Fees',
                '\$${analytics['platformFees']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.business,
                Colors.purple,
              ),
              _buildMetricCard(
                'Avg. Order Value',
                '\$${analytics['avgOrderValue']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.shopping_bag,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Revenue Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildRevenueBreakdown(analytics),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Financial Insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.green),
                    title: const Text('Revenue Growth'),
                    trailing: Text(
                      '+${analytics['revenueGrowth']?.toStringAsFixed(1) ?? '0'}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment, color: Colors.blue),
                    title: const Text('Payment Success Rate'),
                    trailing: Text(
                      '${analytics['paymentSuccessRate']?.toStringAsFixed(1) ?? '0'}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart(Map<String, dynamic> ordersByStatus) {
    final total = ordersByStatus.values.fold<num>(0, (sum, count) => sum + (count as num));
    
    return Column(
      children: ordersByStatus.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(entry.key.toUpperCase()),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                ),
              ),
              Expanded(
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    // Mock recent activity data
    final activities = [
      'Order #1234 completed',
      'New driver John D. registered',
      'Customer rating: 5 stars',
      'Payment processed: \$45.50',
      'Order #1235 in transit',
    ];

    return Column(
      children: activities.map((activity) => ListTile(
        leading: const Icon(Icons.circle, size: 8, color: Colors.green),
        title: Text(activity),
        dense: true,
      )).toList(),
    );
  }

  Widget _buildTopDriversList(List<dynamic> topDrivers) {
    if (topDrivers.isEmpty) {
      return const Text('No driver data available');
    }

    return Column(
      children: topDrivers.take(5).map<Widget>((driver) {
        return ListTile(
          leading: CircleAvatar(
            child: Text(driver['name']?.substring(0, 1) ?? 'D'),
          ),
          title: Text(driver['name'] ?? 'Unknown Driver'),
          subtitle: Text('${driver['deliveries'] ?? 0} deliveries'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text('${driver['rating']?.toStringAsFixed(1) ?? '0'}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueBreakdown(Map<String, dynamic> analytics) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.delivery_dining, color: Colors.blue),
          title: const Text('Delivery Fees'),
          trailing: Text('\$${analytics['deliveryFees']?.toStringAsFixed(2) ?? '0.00'}'),
        ),
        ListTile(
          leading: const Icon(Icons.local_offer, color: Colors.green),
          title: const Text('Service Charges'),
          trailing: Text('\$${analytics['serviceCharges']?.toStringAsFixed(2) ?? '0.00'}'),
        ),
        ListTile(
          leading: const Icon(Icons.discount, color: Colors.orange),
          title: const Text('Tips'),
          trailing: Text('\$${analytics['tips']?.toStringAsFixed(2) ?? '0.00'}'),
        ),
      ],
    );
  }
}
