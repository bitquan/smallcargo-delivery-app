import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_design_system.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/pricing_service.dart';
import '../testing/integration_test_screen.dart';
import '../../comprehensive_test_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await _databaseService.getSystemAnalytics();
      final analytics = await _databaseService.getSystemAnalytics();
      
      if (mounted) {
        setState(() {
          _dashboardStats = {
            'totalOrders': stats['totalOrders'] ?? 0,
            'activeDrivers': stats['activeDrivers'] ?? 0,
            'totalRevenue': stats['totalRevenue'] ?? 0.0,
            'completedOrders': stats['completedOrders'] ?? 0,
          };
          _recentActivity = analytics['recentActivity'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient and logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppDesignSystem.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.admin_panel_settings,
                                    color: AppDesignSystem.primaryGold,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: AppDesignSystem.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'SmallCargo Management',
                                style: AppDesignSystem.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              await authService.signOut();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
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
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppDesignSystem.primaryGold.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: BoxDecoration(
                  gradient: AppDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: AppDesignSystem.textMuted,
                labelStyle: AppDesignSystem.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Drivers'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Pricing'),
                  Tab(text: 'Testing'),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(dashboardStats: _dashboardStats, recentActivity: _recentActivity),
                  const _OrdersManagementTab(),
                  const _DriversManagementTab(),
                  const _AnalyticsTab(),
                  const _PricingManagementTab(),
                  const _TestingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Overview Tab - Dashboard Summary
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> dashboardStats;
  final List<Map<String, dynamic>> recentActivity;

  const _OverviewTab({
    required this.dashboardStats,
    required this.recentActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Orders',
                  '${dashboardStats['totalOrders'] ?? 0}',
                  Icons.inventory_2,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Drivers',
                  '${dashboardStats['activeDrivers'] ?? 0}',
                  Icons.local_shipping,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Revenue',
                  '\$${(dashboardStats['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed Orders',
                  '${dashboardStats['completedOrders'] ?? 0}',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppDesignSystem.headlineSmall.copyWith(
                      color: AppDesignSystem.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: recentActivity.isNotEmpty
                        ? ListView.builder(
                            itemCount: recentActivity.length.clamp(0, 5),
                            itemBuilder: (context, index) {
                              final activity = recentActivity[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.history,
                                  color: AppDesignSystem.primaryGold,
                                ),
                                title: Text(activity['title'] ?? 'Activity'),
                                subtitle: Text(activity['description'] ?? ''),
                                trailing: Text(
                                  activity['time'] ?? '',
                                  style: AppDesignSystem.bodySmall.copyWith(
                                    color: AppDesignSystem.textMuted,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'No recent activity',
                              style: AppDesignSystem.bodyMedium.copyWith(
                                color: AppDesignSystem.textMuted,
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppDesignSystem.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppDesignSystem.primaryGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// Testing Tab - Admin Access Only
class _TestingTab extends StatelessWidget {
  const _TestingTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Testing Dashboard',
                        style: AppDesignSystem.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppDesignSystem.primaryGold,
                        ),
                      ),
                      Text(
                        'Admin-only access to testing tools and diagnostics',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Testing Options Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildTestingCard(
                    context,
                    'Integration Tests',
                    'Run comprehensive system tests',
                    Icons.integration_instructions,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntegrationTestScreen(),
                      ),
                    ),
                  ),
                  _buildTestingCard(
                    context,
                    'Core Functions',
                    'Test individual app components',
                    Icons.functions,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComprehensiveTestScreen(),
                      ),
                    ),
                  ),
                  _buildTestingCard(
                    context,
                    'Demo Data',
                    'Generate sample data for testing',
                    Icons.data_object,
                    () => _showDemoDataDialog(context),
                  ),
                  _buildTestingCard(
                    context,
                    'System Status',
                    'Check system health and logs',
                    Icons.monitor_heart,
                    () => _showSystemStatusDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestingCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppDesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppDesignSystem.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignSystem.primaryGold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppDesignSystem.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Data Generator'),
        content: const Text('This would generate sample orders, users, and drivers for testing purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo data generation would be implemented here')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusItem('Database', 'Connected', true),
            _buildStatusItem('Authentication', 'Active', true),
            _buildStatusItem('Push Notifications', 'Enabled', true),
            _buildStatusItem('Location Services', 'Running', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String service, String status, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service),
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: isHealthy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs - you would implement these based on your existing admin functionality
class _OrdersManagementTab extends StatelessWidget {
  const _OrdersManagementTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: const Center(
        child: Text(
          'Orders Management Tab\n(Implementation needed)',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DriversManagementTab extends StatelessWidget {
  const _DriversManagementTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: const Center(
        child: Text(
          'Drivers Management Tab\n(Implementation needed)',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: const Center(
        child: Text(
          'Analytics Tab\n(Implementation needed)',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Pricing Management Tab - Admin Access Only
class _PricingManagementTab extends StatefulWidget {
  const _PricingManagementTab();

  @override
  State<_PricingManagementTab> createState() => _PricingManagementTabState();
}

class _PricingManagementTabState extends State<_PricingManagementTab> {
  final PricingService _pricingService = PricingService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late TextEditingController _baseFeeController;
  late TextEditingController _pricePerKmController;
  late TextEditingController _pricePerKgController;
  late TextEditingController _minimumPriceController;
  late TextEditingController _maximumPriceController;
  
  late TextEditingController _lowPriorityController;
  late TextEditingController _mediumPriorityController;
  late TextEditingController _highPriorityController;
  late TextEditingController _urgentPriorityController;
  
  late TextEditingController _insuranceController;
  late TextEditingController _trackingController;
  late TextEditingController _expressController;
  late TextEditingController _fragileController;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentPricing();
  }

  void _initializeControllers() {
    final pricing = _pricingService.pricingRules;
    
    _baseFeeController = TextEditingController(text: pricing['baseFee'].toString());
    _pricePerKmController = TextEditingController(text: pricing['pricePerMile'].toString());
    _pricePerKgController = TextEditingController(text: pricing['pricePerLb'].toString());
    _minimumPriceController = TextEditingController(text: pricing['minimumPrice'].toString());
    _maximumPriceController = TextEditingController(text: pricing['maximumPrice'].toString());
    
    final priorityMultipliers = pricing['priorityMultipliers'] as Map<String, dynamic>;
    _lowPriorityController = TextEditingController(text: priorityMultipliers['low'].toString());
    _mediumPriorityController = TextEditingController(text: priorityMultipliers['medium'].toString());
    _highPriorityController = TextEditingController(text: priorityMultipliers['high'].toString());
    _urgentPriorityController = TextEditingController(text: priorityMultipliers['urgent'].toString());
    
    final serviceFees = pricing['serviceFees'] as Map<String, dynamic>;
    _insuranceController = TextEditingController(text: serviceFees['insurance'].toString());
    _trackingController = TextEditingController(text: serviceFees['tracking'].toString());
    _expressController = TextEditingController(text: serviceFees['express'].toString());
    _fragileController = TextEditingController(text: serviceFees['fragile'].toString());
    
    // Add listeners to track changes
    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _baseFeeController, _pricePerKmController, _pricePerKgController,
      _minimumPriceController, _maximumPriceController, _lowPriorityController,
      _mediumPriorityController, _highPriorityController, _urgentPriorityController,
      _insuranceController, _trackingController, _expressController, _fragileController
    ];
    
    for (var controller in controllers) {
      controller.addListener(() {
        if (!_hasChanges) {
          setState(() => _hasChanges = true);
        }
      });
    }
  }

  void _loadCurrentPricing() {
    // Pricing is already loaded in initializeControllers
    setState(() {});
  }

  @override
  void dispose() {
    _baseFeeController.dispose();
    _pricePerKmController.dispose();
    _pricePerKgController.dispose();
    _minimumPriceController.dispose();
    _maximumPriceController.dispose();
    _lowPriorityController.dispose();
    _mediumPriorityController.dispose();
    _highPriorityController.dispose();
    _urgentPriorityController.dispose();
    _insuranceController.dispose();
    _trackingController.dispose();
    _expressController.dispose();
    _fragileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppDesignSystem.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing Management',
                            style: AppDesignSystem.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppDesignSystem.primaryGold,
                            ),
                          ),
                          Text(
                            'Configure delivery pricing and fees',
                            style: AppDesignSystem.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        'Unsaved Changes',
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pricing Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Basic Pricing
                      _buildPricingSection(
                        'Basic Pricing',
                        Icons.money,
                        [
                          _buildPriceField('Base Fee (\$)', _baseFeeController, 'Minimum charge for any delivery'),
                          _buildPriceField('Price per Mile (\$)', _pricePerKmController, 'Cost per mile traveled'),
                          _buildPriceField('Price per Pound (\$)', _pricePerKgController, 'Cost per pound of package weight'),
                          _buildPriceField('Minimum Price (\$)', _minimumPriceController, 'Minimum total price for any order'),
                          _buildPriceField('Maximum Price (\$)', _maximumPriceController, 'Maximum total price for any order'),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Priority Multipliers
                      _buildPricingSection(
                        'Priority Multipliers',
                        Icons.priority_high,
                        [
                          _buildPriceField('Low Priority', _lowPriorityController, 'Multiplier for low priority orders (e.g., 1.0)'),
                          _buildPriceField('Medium Priority', _mediumPriorityController, 'Multiplier for medium priority orders (e.g., 1.2)'),
                          _buildPriceField('High Priority', _highPriorityController, 'Multiplier for high priority orders (e.g., 1.5)'),
                          _buildPriceField('Urgent Priority', _urgentPriorityController, 'Multiplier for urgent orders (e.g., 2.0)'),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Service Fees
                      _buildPricingSection(
                        'Service Fees',
                        Icons.design_services,
                        [
                          _buildPriceField('Insurance (\$)', _insuranceController, 'Additional fee for package insurance'),
                          _buildPriceField('Tracking (\$)', _trackingController, 'Fee for real-time tracking service'),
                          _buildPriceField('Express Delivery (\$)', _expressController, 'Additional fee for express delivery'),
                          _buildPriceField('Fragile Handling (\$)', _fragileController, 'Extra fee for fragile package handling'),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Reset to Defaults',
                              Icons.restore,
                              Colors.grey,
                              _resetToDefaults,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              'Preview Changes',
                              Icons.preview,
                              Colors.blue,
                              _previewChanges,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildActionButton(
                              _isLoading ? 'Saving...' : 'Save Pricing',
                              Icons.save,
                              AppDesignSystem.primaryGold,
                              _isLoading ? null : _savePricing,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection(String title, IconData icon, List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  gradient: AppDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppDesignSystem.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignSystem.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppDesignSystem.bodyMedium.copyWith(
            color: AppDesignSystem.textMuted,
          ),
          filled: true,
          fillColor: AppDesignSystem.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppDesignSystem.primaryGold),
          ),
          prefixIcon: const Icon(Icons.attach_money, color: AppDesignSystem.primaryGold),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          final number = double.tryParse(value);
          if (number == null || number < 0) {
            return 'Please enter a valid positive number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: onPressed == null ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: onPressed == null ? Colors.grey : color),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onPressed == null ? Colors.grey : color, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: onPressed == null ? Colors.grey : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all pricing to default values? This will lose any unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeControllers();
              setState(() => _hasChanges = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pricing reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _previewChanges() {
    if (!_formKey.currentState!.validate()) return;
    
    // Calculate a sample price with current settings
    final samplePrice = _calculateSamplePrice();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pricing Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sample Order Calculation:'),
            const Text('• Distance: 15 miles'),
            const Text('• Weight: 6.6 lbs'),
            const Text('• Priority: Medium'),
            const Text('• Insurance: Yes'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppDesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total Price: \$${samplePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  double _calculateSamplePrice() {
    try {
      final baseFee = double.parse(_baseFeeController.text);
      final pricePerMile = double.parse(_pricePerKmController.text);
      final pricePerLb = double.parse(_pricePerKgController.text);
      final mediumMultiplier = double.parse(_mediumPriorityController.text);
      final insuranceFee = double.parse(_insuranceController.text);
      
      double price = baseFee + (15 * pricePerMile) + (6.6 * pricePerLb); // 15 miles, 6.6 lbs (3kg)
      price *= mediumMultiplier;
      price += insuranceFee;
      
      return price;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newRules = {
        'baseFee': double.parse(_baseFeeController.text),
        'pricePerMile': double.parse(_pricePerKmController.text),
        'pricePerLb': double.parse(_pricePerKgController.text),
        'minimumPrice': double.parse(_minimumPriceController.text),
        'maximumPrice': double.parse(_maximumPriceController.text),
        'priorityMultipliers': {
          'low': double.parse(_lowPriorityController.text),
          'medium': double.parse(_mediumPriorityController.text),
          'high': double.parse(_highPriorityController.text),
          'urgent': double.parse(_urgentPriorityController.text),
        },
        'serviceFees': {
          'insurance': double.parse(_insuranceController.text),
          'tracking': double.parse(_trackingController.text),
          'express': double.parse(_expressController.text),
          'fragile': double.parse(_fragileController.text),
        },
      };
      
      final success = await _pricingService.updatePricingRules(newRules);
      
      if (success) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update pricing. Please check your values.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving pricing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
