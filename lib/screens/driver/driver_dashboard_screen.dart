import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/order.dart' as order_model;
import '../../models/user.dart';
import '../../widgets/order_filter_dialog.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = false;
  
  // Filter and sort state for available orders
  order_model.OrderPriority? _priorityFilter;
  double? _maxDistance = 50.0;
  double? _minPayment = 0.0;
  String _sortBy = 'priority';
  bool _isFilterActive = false;

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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Light gray background
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppConstants.primaryColor, Colors.black],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi ${user?.name ?? 'Driver'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to deliver?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Logout Button
                            GestureDetector(
                              onTap: () => _showLogoutDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Online/Offline Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.yellow, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isOnline = false;
                                });
                                _updateDriverStatus(false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isOnline ? Colors.red : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Offline',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isOnline ? Colors.white : Colors.yellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isOnline = true;
                                });
                                _updateDriverStatus(true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isOnline ? Colors.green : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Online',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isOnline ? Colors.white : Colors.yellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Statistics Cards with Real-time Data
            Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<Map<String, dynamic>>(
                future: user != null ? DatabaseService().getTodayDriverStats(user.id) : null,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {
                    'deliveriesToday': 0,
                    'earningsToday': 0.0,
                  };
                  
                  return Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          'Today\'s Deliveries',
                          '${stats['deliveriesToday']}',
                          Icons.local_shipping,
                          Colors.blue,
                          'Completed today',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          'Earnings Today',
                          '\$${stats['earningsToday'].toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                          'Total earned',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.yellow, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.yellow,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(text: 'Available'),
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableOrdersTab(user),
                  _buildActiveOrdersTab(user),
                  _buildHistoryTab(user),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.yellow,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.yellow.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab(User? user) {
    if (user == null) {
      return const Center(child: Text('Please log in to view orders'));
    }

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isFilterActive ? 'Filtered Orders' : 'All Available Orders',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow,
                  ),
                ),
              ),
              if (_isFilterActive)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _priorityFilter = null;
                      _maxDistance = 50.0;
                      _minPayment = 0.0;
                      _sortBy = 'priority';
                      _isFilterActive = false;
                    });
                  },
                  child: const Text('Clear Filters', style: TextStyle(color: Colors.yellow)),
                ),
              IconButton(
                onPressed: () => _showFilterDialog(),
                icon: Icon(
                  Icons.filter_list,
                  color: _isFilterActive ? Colors.yellow : Colors.yellow.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Orders List
        Expanded(
          child: _isFilterActive
              ? _buildFilteredOrdersList(user)
              : _buildRealTimeOrdersList(user),
        ),
      ],
    );
  }

  Widget _buildRealTimeOrdersList(User user) {
    return StreamBuilder<List<order_model.Order>>(
      stream: DatabaseService().getAvailableOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.yellow),
                const SizedBox(height: 16),
                const Text('Error loading orders', style: TextStyle(color: Colors.yellow)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.yellow),
                SizedBox(height: 16),
                Text('No available orders', 
                     style: TextStyle(color: Colors.yellow, fontSize: 16)),
                SizedBox(height: 8),
                Text('Check back soon for new deliveries!',
                     style: TextStyle(color: Colors.yellow, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, true);
          },
        );
      },
    );
  }

  Widget _buildFilteredOrdersList(User user) {
    return FutureBuilder<List<order_model.Order>>(
      future: DatabaseService().getFilteredAvailableOrders(
        priority: _priorityFilter,
        maxDistance: _maxDistance,
        minPayment: _minPayment,
        sortBy: _sortBy,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Error loading filtered orders'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders match your filters', 
                     style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 8),
                Text('Try adjusting your filter criteria',
                     style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, true);
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => OrderFilterDialog(
        initialPriority: _priorityFilter,
        initialMaxDistance: _maxDistance,
        initialMinPayment: _minPayment,
        initialSortBy: _sortBy,
        onApplyFilters: (priority, maxDistance, minPayment, sortBy) {
          setState(() {
            _priorityFilter = priority;
            _maxDistance = maxDistance;
            _minPayment = minPayment;
            _sortBy = sortBy ?? 'priority';
            _isFilterActive = priority != null || 
                            (maxDistance != null && maxDistance < 50.0) ||
                            (minPayment != null && minPayment > 0.0) ||
                            sortBy != 'priority';
          });
        },
      ),
    );
  }

  Widget _buildActiveOrdersTab(User? user) {
    if (user == null) {
      return const Center(child: Text('Please log in to view orders'));
    }

    return StreamBuilder<List<order_model.Order>>(
      stream: DatabaseService().getDriverActiveOrdersStream(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading orders'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];
        final activeOrders = orders.where((order) => 
          order.status != order_model.OrderStatus.delivered &&
          order.status != order_model.OrderStatus.cancelled
        ).toList();

        if (activeOrders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No active orders', 
                     style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 8),
                Text('Accept orders from the Available tab',
                     style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return _buildOrderCard(order, false);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(order_model.Order order, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(order.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.priority.name.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(order.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${order.estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'From: ${order.pickupAddress}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'To: ${order.deliveryAddress}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.schedule, '${order.estimatedDeliveryTime?.hour}:${order.estimatedDeliveryTime?.minute}'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.location_on, '2.3 km'),
                const Spacer(),
                if (isAvailable)
                  ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_getNextStatusText(order.status)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.yellow),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHistoryTab(User? user) {
    return Container(
      color: Colors.grey[50],
      child: const Center(
        child: Text('Order History - Coming Soon'),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please log in to view analytics', style: TextStyle(color: Colors.yellow)));
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService().getDriverAnalytics(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.yellow),
                const SizedBox(height: 16),
                Text('Error loading analytics: ${snapshot.error}', style: const TextStyle(color: Colors.yellow)),
              ],
            ),
          );
        }
        
        final analytics = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Total Deliveries',
                      '${analytics['totalDeliveries']}',
                      Icons.local_shipping,
                      Colors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Total Earnings',
                      '\$${analytics['totalEarnings'].toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Avg Order Value',
                      '\$${analytics['avgOrderValue'].toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'On-Time Rate',
                      '${analytics['onTimeRate'].toStringAsFixed(1)}%',
                      Icons.schedule,
                      AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // This Month Performance
              const Text(
                'This Month',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Deliveries',
                      '${analytics['thisMonthDeliveries']}',
                      Icons.calendar_month,
                      Colors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Earnings',
                      '\$${analytics['thisMonthEarnings'].toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.yellow,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Weekly Performance
              const Text(
                'Recent Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Orders (7 days)',
                      '${analytics['weeklyOrders']}',
                      Icons.assignment,
                      Colors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Active Orders',
                      '${analytics['activeOrders']}',
                      Icons.local_shipping_outlined,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Priority Breakdown
              const Text(
                'Order Priority Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildPriorityBreakdownChart(analytics['priorityBreakdown']),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.yellow,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriorityBreakdownChart(Map<String, int> priorityBreakdown) {
    final total = priorityBreakdown.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: priorityBreakdown.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          final color = _getPriorityColor(
            order_model.OrderPriority.values.firstWhere(
              (p) => p.name == entry.key,
              orElse: () => order_model.OrderPriority.medium,
            ),
          );
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 80,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.yellow,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPriorityColor(order_model.OrderPriority priority) {
    switch (priority) {
      case order_model.OrderPriority.urgent:
        return Colors.red;
      case order_model.OrderPriority.high:
        return Colors.orange;
      case order_model.OrderPriority.medium:
        return Colors.blue;
      case order_model.OrderPriority.low:
        return Colors.grey;
    }
  }

  String _getNextStatusText(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.confirmed:
        return 'Pick Up';
      case order_model.OrderStatus.pickedUp:
        return 'In Transit';
      case order_model.OrderStatus.inTransit:
        return 'Delivered';
      default:
        return 'Update';
    }
  }

  void _updateDriverStatus(bool isOnline) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        await DatabaseService().updateDriverStatus(user.id, isOnline);
        setState(() {
          _isOnline = isOnline;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _acceptOrder(order_model.Order order) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        await DatabaseService().acceptOrder(order.id, user.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateOrderStatus(order_model.Order order) async {
    try {
      order_model.OrderStatus newStatus;
      switch (order.status) {
        case order_model.OrderStatus.confirmed:
          newStatus = order_model.OrderStatus.pickedUp;
          break;
        case order_model.OrderStatus.pickedUp:
          newStatus = order_model.OrderStatus.inTransit;
          break;
        case order_model.OrderStatus.inTransit:
          newStatus = order_model.OrderStatus.delivered;
          break;
        default:
          return;
      }

      await DatabaseService().updateOrderStatusByDriver(order.id, newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                  
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      AppConstants.loginRoute, 
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
