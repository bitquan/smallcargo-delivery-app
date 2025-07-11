import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/order.dart' as order_model;
import '../../models/user.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
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
                              'Hello ${user?.name ?? 'Customer'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What would you like to ship today?',
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
                                Icons.person,
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
                    
                    // Quick Action Button
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.yellow, width: 1),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showCreateOrderDialog(context, user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_box),
                            SizedBox(width: 8),
                            Text(
                              'Create New Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Statistics Cards with Real-time Data
            Padding(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<List<order_model.Order>>(
                stream: user != null ? DatabaseService().getCustomerOrders(user.id) : null,
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  final activeOrders = orders.where((order) => 
                    order.status != order_model.OrderStatus.delivered &&
                    order.status != order_model.OrderStatus.cancelled
                  ).length;
                  final totalSpent = orders.fold<double>(0.0, (sum, order) => sum + order.estimatedCost);
                  
                  return Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          'Active Orders',
                          '$activeOrders',
                          Icons.assignment,
                          Colors.blue,
                          'Currently processing',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernStatCard(
                          'Total Spent',
                          '\$${totalSpent.toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                          'All time',
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
                  Tab(text: 'Active Orders'),
                  Tab(text: 'Order History'),
                  Tab(text: 'Track Order'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveOrdersTab(user),
                  _buildOrderHistoryTab(user),
                  _buildTrackOrderTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersTab(User? user) {
    if (user == null) {
      return const Center(child: Text('Please log in to view orders'));
    }

    return StreamBuilder<List<order_model.Order>>(
      stream: DatabaseService().getCustomerOrders(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading orders', style: TextStyle(color: Colors.yellow)),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];
        final activeOrders = orders.where((order) => 
          order.status != order_model.OrderStatus.delivered &&
          order.status != order_model.OrderStatus.cancelled
        ).toList();

        if (activeOrders.isEmpty) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.yellow),
                  SizedBox(height: 16),
                  Text('No active orders', 
                       style: TextStyle(color: Colors.yellow, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Create a new order to get started!',
                       style: TextStyle(color: Colors.yellow, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderHistoryTab(User? user) {
    if (user == null) {
      return const Center(child: Text('Please log in to view order history'));
    }

    return StreamBuilder<List<order_model.Order>>(
      stream: DatabaseService().getCustomerOrders(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: Colors.black,
            child: const Center(child: Text('Error loading order history', style: TextStyle(color: Colors.yellow))),
          );
        }

        final orders = snapshot.data ?? [];
        final completedOrders = orders.where((order) => 
          order.status == order_model.OrderStatus.delivered ||
          order.status == order_model.OrderStatus.cancelled
        ).toList();

        if (completedOrders.isEmpty) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.yellow),
                  SizedBox(height: 16),
                  Text('No order history', 
                       style: TextStyle(color: Colors.yellow, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedOrders.length,
            itemBuilder: (context, index) {
              final order = completedOrders[index];
              return _buildOrderCard(order, showRating: order.status == order_model.OrderStatus.delivered);
            },
          ),
        );
      },
    );
  }

  Widget _buildTrackOrderTab() {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter Tracking Number',
                hintText: 'e.g., SC1234567890',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (trackingNumber) => _trackOrder(trackingNumber),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Text(
                  'Enter a tracking number to track your order',
                  style: TextStyle(color: Colors.yellow),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(order_model.Order order, {bool showRating = false}) {
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
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
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
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tracking: ${order.trackingNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${order.pickupAddress.street}',
              style: const TextStyle(fontSize: 14, color: Colors.yellow),
            ),
            const SizedBox(height: 4),
            Text(
              'To: ${order.deliveryAddress.street}',
              style: const TextStyle(fontSize: 14, color: Colors.yellow),
            ),
            const SizedBox(height: 12),
            Text(
              order.description,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.yellow),
            ),
            if (showRating) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showRatingDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Rate Delivery', style: TextStyle(color: Colors.black)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.blue;
      case order_model.OrderStatus.pickedUp:
        return Colors.purple;
      case order_model.OrderStatus.inTransit:
        return Colors.indigo;
      case order_model.OrderStatus.delivered:
        return Colors.green;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _showCreateOrderDialog(BuildContext context, User? user) {
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (context) => CreateOrderDialog(customerId: user.id),
    );
  }

  void _showRatingDialog(order_model.Order order) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(order: order),
    );
  }

  void _trackOrder(String trackingNumber) {
    // Implementation for tracking specific order
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(trackingNumber: trackingNumber),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.yellow, width: 1),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.yellow),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.yellow),
              ),
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

// Simple Create Order Dialog
class CreateOrderDialog extends StatefulWidget {
  final String customerId;

  const CreateOrderDialog({super.key, required this.customerId});

  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  order_model.OrderPriority _priority = order_model.OrderPriority.medium;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.yellow, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create New Order',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Cost (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<order_model.OrderPriority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: order_model.OrderPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.yellow)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      child: const Text('Create Order', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        await DatabaseService().createCustomerOrder(
          customerId: widget.customerId,
          pickupAddress: _pickupController.text,
          deliveryAddress: _deliveryController.text,
          description: _descriptionController.text,
          estimatedCost: double.parse(_costController.text),
          priority: _priority,
        );
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Simple Rating Dialog
class RatingDialog extends StatefulWidget {
  final order_model.Order order;

  const RatingDialog({super.key, required this.order});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 5;
  final _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.yellow, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rate Your Delivery',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.yellow)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitRating() async {
    try {
      await DatabaseService().rateDelivery(
        orderId: widget.order.id,
        customerId: widget.order.customerId,
        driverId: widget.order.driverId!,
        rating: _rating,
        feedback: _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
      );
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Simple Order Tracking Screen
class OrderTrackingScreen extends StatelessWidget {
  final String trackingNumber;

  const OrderTrackingScreen({super.key, required this.trackingNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order: $trackingNumber'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Order tracking functionality will be implemented here'),
      ),
    );
  }
}
