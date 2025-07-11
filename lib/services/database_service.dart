import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import '../models/order.dart' as order_model;
import '../models/user.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Orders Collection
  CollectionReference get ordersCollection => _firestore.collection('orders');
  
  // Users Collection
  CollectionReference get usersCollection => _firestore.collection('users');

  // Create a new order
  Future<order_model.Order> createOrder({
    required String customerId,
    required order_model.Address pickupAddress,
    required order_model.Address deliveryAddress,
    required String description,
    double? weight,
    String? dimensions,
    required double estimatedCost,
    order_model.OrderPriority priority = order_model.OrderPriority.medium,
    List<String>? imageUrls,
    String? specialInstructions,
  }) async {
    try {
      final orderId = _uuid.v4();
      final trackingNumber = _generateTrackingNumber();
      
      final order = order_model.Order(
        id: orderId,
        customerId: customerId,
        trackingNumber: trackingNumber,
        status: order_model.OrderStatus.pending,
        priority: priority,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        description: description,
        weight: weight,
        dimensions: dimensions,
        estimatedCost: estimatedCost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: imageUrls ?? [],
        specialInstructions: specialInstructions,
      );

      await ordersCollection.doc(orderId).set(order.toMap());
      return order;
    } catch (e) {
      throw DatabaseException('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return order_model.Order.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get order: $e');
    }
  }

  // Get order by tracking number
  Future<order_model.Order?> getOrderByTrackingNumber(String trackingNumber) async {
    try {
      final querySnapshot = await ordersCollection
          .where('trackingNumber', isEqualTo: trackingNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return order_model.Order.fromSnapshot(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get order by tracking number: $e');
    }
  }

  // Get orders by customer ID
  Stream<List<order_model.Order>> getOrdersByCustomerId(String customerId) {
    return ordersCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          try {
            final orders = <order_model.Order>[];
            for (var doc in snapshot.docs) {
              try {
                final order = order_model.Order.fromSnapshot(doc);
                orders.add(order);
              } catch (e) {
                print('Error parsing order document ${doc.id}: $e');
                // Skip this document and continue with others
                continue;
              }
            }
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          } catch (e) {
            print('Error processing orders snapshot: $e');
            return <order_model.Order>[];
          }
        });
  }

  // Get user orders (alias for getOrdersByCustomerId)
  Stream<List<order_model.Order>> getUserOrders(String userId) {
    return getOrdersByCustomerId(userId);
  }

  // Get orders by driver ID
  Stream<List<order_model.Order>> getOrdersByDriverId(String driverId) {
    return ordersCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => order_model.Order.fromSnapshot(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Get all orders (admin only)
  Stream<List<order_model.Order>> getAllOrders() {
    return ordersCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => order_model.Order.fromSnapshot(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Get available orders for drivers
  Stream<List<order_model.Order>> getAvailableOrders() {
    return ordersCollection
        .where('status', isEqualTo: order_model.OrderStatus.confirmed.name)
        .where('driverId', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => order_model.Order.fromSnapshot(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, order_model.OrderStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      // Add timestamps for specific statuses
      switch (status) {
        case order_model.OrderStatus.pickedUp:
          updates['pickupTime'] = Timestamp.now();
          break;
        case order_model.OrderStatus.delivered:
          updates['deliveryTime'] = Timestamp.now();
          break;
        default:
          break;
      }

      await ordersCollection.doc(orderId).update(updates);
    } catch (e) {
      throw DatabaseException('Failed to update order status: $e');
    }
  }

  // Get available drivers
  Future<List<User>> getAvailableDrivers() async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: UserRole.driver.name)
          .get();
      
      return snapshot.docs
          .map((doc) => User.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get available drivers: $e');
    }
  }

  // Assign driver to order
  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    try {
      await ordersCollection.doc(orderId).update({
        'driverId': driverId,
        'status': order_model.OrderStatus.confirmed.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('Failed to assign driver to order: $e');
    }
  }

  // Get driver's assigned orders
  Future<List<order_model.Order>> getDriverOrders(String driverId) async {
    try {
      final snapshot = await ordersCollection
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            order_model.OrderStatus.confirmed.name,
            order_model.OrderStatus.pickedUp.name,
            order_model.OrderStatus.inTransit.name,
          ])
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get driver orders: $e');
    }
  }

  // Update order location (for tracking)
  Future<void> updateOrderLocation(String orderId, double latitude, double longitude) async {
    try {
      await ordersCollection.doc(orderId).update({
        'currentLatitude': latitude,
        'currentLongitude': longitude,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('Failed to update order location: $e');
    }
  }

  // Update order
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await ordersCollection.doc(orderId).update(updates);
    } catch (e) {
      throw DatabaseException('Failed to update order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await ordersCollection.doc(orderId).update({
        'status': order_model.OrderStatus.cancelled.name,
        'cancellationReason': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('Failed to cancel order: $e');
    }
  }

  // Get order statistics
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final snapshot = await ordersCollection.get();
      final stats = <String, int>{};
      
      for (final status in order_model.OrderStatus.values) {
        stats[status.name] = 0;
      }

      for (final doc in snapshot.docs) {
        final order = order_model.Order.fromSnapshot(doc);
        stats[order.status.name] = (stats[order.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw DatabaseException('Failed to get order statistics: $e');
    }
  }

  // Search orders
  Future<List<order_model.Order>> searchOrders(String query) async {
    try {
      // Search by tracking number
      final trackingQuery = await ordersCollection
          .where('trackingNumber', isGreaterThanOrEqualTo: query)
          .where('trackingNumber', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by description
      final descriptionQuery = await ordersCollection
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final results = <order_model.Order>[];
      final seenIds = <String>{};

      // Combine results and remove duplicates
      for (final doc in [...trackingQuery.docs, ...descriptionQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          results.add(order_model.Order.fromSnapshot(doc));
          seenIds.add(doc.id);
        }
      }

      return results;
    } catch (e) {
      throw DatabaseException('Failed to search orders: $e');
    }
  }

  // Get users (admin only)
  Stream<List<User>> getAllUsers() {
    return usersCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromSnapshot(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Get drivers
  Stream<List<User>> getDrivers() {
    return usersCollection
        .where('role', isEqualTo: UserRole.driver.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromSnapshot(doc))
            .toList());
  }

  // Update user role (admin function)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await usersCollection.doc(userId).update({
        'role': newRole.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('Failed to update user role: $e');
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get user: $e');
    }
  }

  // Update order with specific fields (for driver dashboard)
  Future<void> updateOrderFields(String orderId, {
    String? driverId,
    order_model.OrderStatus? status,
    double? actualCost,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (driverId != null) updates['driverId'] = driverId;
      if (status != null) {
        updates['status'] = status.name;
        
        // Add timestamps for specific statuses
        switch (status) {
          case order_model.OrderStatus.pickedUp:
            updates['pickupTime'] = Timestamp.now();
            break;
          case order_model.OrderStatus.delivered:
            updates['deliveryTime'] = Timestamp.now();
            break;
          default:
            break;
        }
      }
      if (actualCost != null) updates['actualCost'] = actualCost;
      if (notes != null) updates['notes'] = notes;
      
      updates['updatedAt'] = Timestamp.now();
      
      await ordersCollection.doc(orderId).update(updates);
    } catch (e) {
      throw DatabaseException('Failed to update order fields: $e');
    }
  }

  // Enhanced Analytics Methods
  Future<Map<String, dynamic>> getAdvancedAnalytics() async {
    try {
      final ordersSnapshot = await ordersCollection.get();
      final usersSnapshot = await usersCollection.get();
      
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
      
      final users = usersSnapshot.docs
          .map((doc) => User.fromSnapshot(doc))
          .toList();
      
      // Calculate analytics
      final totalRevenue = orders
          .where((order) => order.status == order_model.OrderStatus.delivered)
          .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
      
      final avgOrderValue = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;
      
      final ordersThisMonth = orders.where((order) {
        final now = DateTime.now();
        return order.createdAt.year == now.year && order.createdAt.month == now.month;
      }).length;
      
      final revenueThisMonth = orders
          .where((order) {
            final now = DateTime.now();
            return order.createdAt.year == now.year && 
                   order.createdAt.month == now.month &&
                   order.status == order_model.OrderStatus.delivered;
          })
          .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
      
      final customerCount = users.where((user) => user.role == UserRole.customer).length;
      final driverCount = users.where((user) => user.role == UserRole.driver).length;
      
      // Status breakdown
      final statusBreakdown = <String, int>{};
      for (final status in order_model.OrderStatus.values) {
        statusBreakdown[status.name] = orders.where((order) => order.status == status).length;
      }
      
      // Priority breakdown
      final priorityBreakdown = <String, int>{};
      for (final priority in order_model.OrderPriority.values) {
        priorityBreakdown[priority.name] = orders.where((order) => order.priority == priority).length;
      }
      
      // Daily orders for the last 30 days
      final dailyOrders = <String, int>{};
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = '${date.month}/${date.day}';
        dailyOrders[dateKey] = orders.where((order) {
          return order.createdAt.year == date.year &&
                 order.createdAt.month == date.month &&
                 order.createdAt.day == date.day;
        }).length;
      }
      
      return {
        'totalOrders': orders.length,
        'totalRevenue': totalRevenue,
        'avgOrderValue': avgOrderValue,
        'ordersThisMonth': ordersThisMonth,
        'revenueThisMonth': revenueThisMonth,
        'customerCount': customerCount,
        'driverCount': driverCount,
        'statusBreakdown': statusBreakdown,
        'priorityBreakdown': priorityBreakdown,
        'dailyOrders': dailyOrders,
        'deliveryRate': orders.isNotEmpty ? 
            (orders.where((order) => order.status == order_model.OrderStatus.delivered).length / orders.length * 100) : 0,
      };
    } catch (e) {
      throw DatabaseException('Failed to get advanced analytics: $e');
    }
  }

  // Driver-specific analytics
  Future<Map<String, dynamic>> getDriverAnalytics(String driverId) async {
    try {
      final ordersSnapshot = await ordersCollection
          .where('driverId', isEqualTo: driverId)
          .get();
      
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
      
      // Calculate analytics
      final totalDeliveries = orders.where((order) => order.status == order_model.OrderStatus.delivered).length;
      final totalEarnings = orders
          .where((order) => order.status == order_model.OrderStatus.delivered)
          .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
      
      final avgOrderValue = totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0.0;
      
      // This month stats
      final now = DateTime.now();
      final thisMonthOrders = orders.where((order) {
        return order.createdAt.year == now.year && order.createdAt.month == now.month;
      }).toList();
      
      final thisMonthDeliveries = thisMonthOrders.where((order) => order.status == order_model.OrderStatus.delivered).length;
      final thisMonthEarnings = thisMonthOrders
          .where((order) => order.status == order_model.OrderStatus.delivered)
          .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
      
      // Performance metrics
      final onTimeDeliveries = orders.where((order) {
        return order.status == order_model.OrderStatus.delivered &&
               order.deliveryTime != null &&
               order.estimatedDeliveryTime != null &&
               order.deliveryTime!.isBefore(order.estimatedDeliveryTime!);
      }).length;
      
      final onTimeRate = totalDeliveries > 0 ? (onTimeDeliveries / totalDeliveries * 100) : 0.0;
      
      // Weekly performance (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weeklyOrders = orders.where((order) => order.createdAt.isAfter(weekAgo)).length;
      final weeklyDeliveries = orders.where((order) => 
        order.createdAt.isAfter(weekAgo) && order.status == order_model.OrderStatus.delivered).length;
      
      // Priority breakdown
      final priorityBreakdown = <String, int>{};
      for (final priority in order_model.OrderPriority.values) {
        priorityBreakdown[priority.name] = orders.where((order) => order.priority == priority).length;
      }
      
      return {
        'totalDeliveries': totalDeliveries,
        'totalEarnings': totalEarnings,
        'avgOrderValue': avgOrderValue,
        'thisMonthDeliveries': thisMonthDeliveries,
        'thisMonthEarnings': thisMonthEarnings,
        'onTimeRate': onTimeRate,
        'weeklyOrders': weeklyOrders,
        'weeklyDeliveries': weeklyDeliveries,
        'priorityBreakdown': priorityBreakdown,
        'totalOrders': orders.length,
        'activeOrders': orders.where((order) => 
          order.status == order_model.OrderStatus.confirmed ||
          order.status == order_model.OrderStatus.pickedUp ||
          order.status == order_model.OrderStatus.inTransit).length,
      };
    } catch (e) {
      throw DatabaseException('Failed to get driver analytics: $e');
    }
  }

  // Core Driver Functions
  
  /// Update driver online/offline status
  Future<void> updateDriverStatus(String driverId, bool isOnline, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      await usersCollection.doc(driverId).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
        if (latitude != null) 'currentLocation.latitude': latitude,
        if (longitude != null) 'currentLocation.longitude': longitude,
      });
    } catch (e) {
      throw DatabaseException('Failed to update driver status: $e');
    }
  }

  /// Get available orders for drivers (simple query to avoid index issues)
  Stream<List<order_model.Order>> getAvailableOrdersStream() {
    try {
      return ordersCollection
          .where('status', isEqualTo: order_model.OrderStatus.pending.name)
          .where('driverId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => order_model.Order.fromSnapshot(doc)).toList());
    } catch (e) {
      throw DatabaseException('Failed to get available orders: $e');
    }
  }

  /// Get driver's active orders (simplified to avoid complex queries)
  Stream<List<order_model.Order>> getDriverActiveOrdersStream(String driverId) {
    try {
      return ordersCollection
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => order_model.Order.fromSnapshot(doc)).toList());
    } catch (e) {
      throw DatabaseException('Failed to get driver active orders: $e');
    }
  }

  /// Accept an order (core driver function)
  Future<void> acceptOrder(String orderId, String driverId) async {
    try {
      await ordersCollection.doc(orderId).update({
        'driverId': driverId,
        'status': order_model.OrderStatus.confirmed.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to accept order: $e');
    }
  }

  /// Update order status (core driver function)
  Future<void> updateOrderStatusByDriver(String orderId, order_model.OrderStatus newStatus) async {
    try {
      final updateData = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamp for specific status changes
      switch (newStatus) {
        case order_model.OrderStatus.pickedUp:
          updateData['pickupTime'] = FieldValue.serverTimestamp();
          break;
        case order_model.OrderStatus.inTransit:
          updateData['inTransitTime'] = FieldValue.serverTimestamp();
          break;
        case order_model.OrderStatus.delivered:
          updateData['deliveryTime'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await ordersCollection.doc(orderId).update(updateData);
    } catch (e) {
      throw DatabaseException('Failed to update order status: $e');
    }
  }

  /// Get filtered available orders (core filtering function)
  Future<List<order_model.Order>> getFilteredAvailableOrders({
    order_model.OrderPriority? priority,
    double? maxDistance,
    double? minPayment,
    String? sortBy,
  }) async {
    try {
      Query query = ordersCollection
          .where('status', isEqualTo: order_model.OrderStatus.pending.name)
          .where('driverId', isNull: true);

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }

      if (minPayment != null) {
        query = query.where('estimatedCost', isGreaterThanOrEqualTo: minPayment);
      }

      // Add ordering
      if (sortBy == 'payment') {
        query = query.orderBy('estimatedCost', descending: true);
      } else if (sortBy == 'priority') {
        query = query.orderBy('priority');
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.limit(50).get();
      
      return snapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get filtered orders: $e');
    }
  }

  /// Calculate distance between two points (core route function)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);
    
    double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Get driver location and update
  Future<void> updateDriverLocation(String driverId, double latitude, double longitude) async {
    try {
      await usersCollection.doc(driverId).update({
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to update driver location: $e');
    }
  }

  /// Real-time driver performance tracking
  Future<Map<String, dynamic>> getTodayDriverStats(String driverId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await ordersCollection
          .where('driverId', isEqualTo: driverId)
          .where('deliveryTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('deliveryTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final completedOrders = snapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .where((order) => order.status == order_model.OrderStatus.delivered)
          .toList();

      final totalEarnings = completedOrders.fold<double>(
          0, (sum, order) => sum + order.estimatedCost);

      return {
        'deliveriesToday': completedOrders.length,
        'earningsToday': totalEarnings,
        'avgDeliveryTime': _calculateAverageDeliveryTime(completedOrders),
        'onTimeDeliveries': _countOnTimeDeliveries(completedOrders),
      };
    } catch (e) {
      throw DatabaseException('Failed to get today stats: $e');
    }
  }

  double _calculateAverageDeliveryTime(List<order_model.Order> orders) {
    if (orders.isEmpty) return 0.0;
    
    double totalMinutes = 0.0;
    int validOrders = 0;
    
    for (final order in orders) {
      if (order.pickupTime != null && order.deliveryTime != null) {
        final duration = order.deliveryTime!.difference(order.pickupTime!);
        totalMinutes += duration.inMinutes;
        validOrders++;
      }
    }
    
    return validOrders > 0 ? totalMinutes / validOrders : 0.0;
  }

  int _countOnTimeDeliveries(List<order_model.Order> orders) {
    int onTimeCount = 0;
    
    for (final order in orders) {
      if (order.deliveryTime != null && order.estimatedDeliveryTime != null) {
        if (order.deliveryTime!.isBefore(order.estimatedDeliveryTime!) ||
            order.deliveryTime!.isAtSameMomentAs(order.estimatedDeliveryTime!)) {
          onTimeCount++;
        }
      }
    }
    
    return onTimeCount;
  }

  /// Customer order creation and management
  Future<String> createCustomerOrder({
    required String customerId,
    required String pickupAddress,
    required String deliveryAddress,
    required String description,
    required double estimatedCost,
    required order_model.OrderPriority priority,
    double? weight,
    String? dimensions,
    String? specialInstructions,
    DateTime? estimatedDeliveryTime,
  }) async {
    try {
      final orderId = _uuid.v4();
      final trackingNumber = 'SC${DateTime.now().millisecondsSinceEpoch}';
      
      final order = order_model.Order(
        id: orderId,
        customerId: customerId,
        trackingNumber: trackingNumber,
        status: order_model.OrderStatus.pending,
        priority: priority,
        pickupAddress: order_model.Address(
          street: pickupAddress,
          city: 'Default City',
          state: 'Default State',
          zipCode: '00000',
          country: 'USA',
        ),
        deliveryAddress: order_model.Address(
          street: deliveryAddress,
          city: 'Default City',
          state: 'Default State',
          zipCode: '00000',
          country: 'USA',
        ),
        description: description,
        weight: weight,
        dimensions: dimensions,
        estimatedCost: estimatedCost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        estimatedDeliveryTime: estimatedDeliveryTime,
        specialInstructions: specialInstructions,
      );

      await ordersCollection.doc(orderId).set(order.toMap());
      return orderId;
    } catch (e) {
      throw DatabaseException('Failed to create order: $e');
    }
  }

  /// Real-time order tracking for customers
  Stream<order_model.Order?> trackOrder(String orderId) {
    try {
      return ordersCollection
          .doc(orderId)
          .snapshots()
          .map((doc) => doc.exists ? order_model.Order.fromSnapshot(doc) : null);
    } catch (e) {
      throw DatabaseException('Failed to track order: $e');
    }
  }

  /// Get customer's order history
  Stream<List<order_model.Order>> getCustomerOrders(String customerId) {
    try {
      return ordersCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => order_model.Order.fromSnapshot(doc)).toList());
    } catch (e) {
      throw DatabaseException('Failed to get customer orders: $e');
    }
  }

  /// Driver rating and feedback system
  Future<void> rateDelivery({
    required String orderId,
    required String customerId,
    required String driverId,
    required int rating, // 1-5 stars
    String? feedback,
  }) async {
    try {
      final ratingId = _uuid.v4();
      await _firestore.collection('ratings').doc(ratingId).set({
        'id': ratingId,
        'orderId': orderId,
        'customerId': customerId,
        'driverId': driverId,
        'rating': rating,
        'feedback': feedback,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update driver's average rating
      await _updateDriverRating(driverId);
    } catch (e) {
      throw DatabaseException('Failed to rate delivery: $e');
    }
  }

  Future<void> _updateDriverRating(String driverId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('driverId', isEqualTo: driverId)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        final ratings = ratingsSnapshot.docs
            .map((doc) => doc.data()['rating'] as int)
            .toList();
        
        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
        
        await usersCollection.doc(driverId).update({
          'averageRating': averageRating,
          'totalRatings': ratings.length,
        });
      }
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }

  /// Real-time notifications system
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? orderId,
    String? type,
  }) async {
    try {
      final notificationId = _uuid.v4();
      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'userId': userId,
        'title': title,
        'message': message,
        'orderId': orderId,
        'type': type ?? 'general',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to send notification: $e');
    }
  }

  /// Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      throw DatabaseException('Failed to get notifications: $e');
    }
  }

  /// Order cancellation with reason
  Future<void> cancelOrderWithReason(String orderId, String reason) async {
    try {
      await ordersCollection.doc(orderId).update({
        'status': order_model.OrderStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DatabaseException('Failed to cancel order: $e');
    }
  }

  /// Emergency features
  Future<void> reportEmergency({
    required String userId,
    required String orderId,
    required String emergencyType,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final emergencyId = _uuid.v4();
      await _firestore.collection('emergencies').doc(emergencyId).set({
        'id': emergencyId,
        'userId': userId,
        'orderId': orderId,
        'emergencyType': emergencyType,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notification to admin
      await sendNotification(
        userId: 'admin',
        title: 'Emergency Reported',
        message: 'Emergency reported for order $orderId',
        orderId: orderId,
        type: 'emergency',
      );
    } catch (e) {
      throw DatabaseException('Failed to report emergency: $e');
    }
  }

  /// Admin dashboard functions
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonth = DateTime(now.year, now.month, 1);

      // Get today's orders
      final todayOrdersSnapshot = await ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      // Get this month's orders
      final monthOrdersSnapshot = await ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
          .get();

      // Get all drivers
      final driversSnapshot = await usersCollection
          .where('role', isEqualTo: 'driver')
          .get();

      // Get active drivers (online in last hour)
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final activeDriversSnapshot = await usersCollection
          .where('role', isEqualTo: 'driver')
          .where('lastActive', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      final todayOrders = todayOrdersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();

      final monthOrders = monthOrdersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();

      return {
        'todayOrders': todayOrders.length,
        'todayRevenue': todayOrders.fold<double>(0, (sum, order) => sum + order.estimatedCost),
        'monthOrders': monthOrders.length,
        'monthRevenue': monthOrders.fold<double>(0, (sum, order) => sum + order.estimatedCost),
        'totalDrivers': driversSnapshot.docs.length,
        'activeDrivers': activeDriversSnapshot.docs.length,
        'pendingOrders': todayOrders.where((o) => o.status == order_model.OrderStatus.pending).length,
        'completedToday': todayOrders.where((o) => o.status == order_model.OrderStatus.delivered).length,
      };
    } catch (e) {
      throw DatabaseException('Failed to get system analytics: $e');
    }
  }

  // Enhanced Analytics for Dashboard
  Future<Map<String, dynamic>> getChartAnalytics() async {
    try {
      final ordersSnapshot = await ordersCollection.get();
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();

      // Daily revenue for last 30 days
      final dailyRevenue = <String, double>{};
      final dailyOrderCounts = <String, int>{};
      
      for (int i = 29; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = '${date.month}/${date.day}';
        
        final dayOrders = orders.where((order) {
          return order.createdAt.year == date.year &&
                 order.createdAt.month == date.month &&
                 order.createdAt.day == date.day;
        }).toList();
        
        dailyOrderCounts[dateKey] = dayOrders.length;
        dailyRevenue[dateKey] = dayOrders
            .where((order) => order.status == order_model.OrderStatus.delivered)
            .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
      }

      // Weekly analytics for last 12 weeks
      final weeklyData = <String, Map<String, dynamic>>{};
      for (int i = 11; i >= 0; i--) {
        final weekStart = DateTime.now().subtract(Duration(days: (i * 7) + DateTime.now().weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekKey = 'Week ${12 - i}';
        
        final weekOrders = orders.where((order) {
          return order.createdAt.isAfter(weekStart) && order.createdAt.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        
        weeklyData[weekKey] = {
          'orders': weekOrders.length,
          'revenue': weekOrders
              .where((order) => order.status == order_model.OrderStatus.delivered)
              .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost)),
          'avgDeliveryTime': _calculateAvgDeliveryTime(weekOrders),
        };
      }

      // Monthly analytics for last 12 months
      final monthlyData = <String, Map<String, dynamic>>{};
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
        final monthKey = '${_getMonthName(date.month)} ${date.year}';
        
        final monthOrders = orders.where((order) {
          return order.createdAt.year == date.year && order.createdAt.month == date.month;
        }).toList();
        
        monthlyData[monthKey] = {
          'orders': monthOrders.length,
          'revenue': monthOrders
              .where((order) => order.status == order_model.OrderStatus.delivered)
              .fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost)),
          'newCustomers': await _getNewCustomersForMonth(date),
        };
      }

      // Top performing drivers
      final driverPerformance = await _getDriverPerformanceData();

      // Customer satisfaction metrics
      final satisfactionMetrics = await _getCustomerSatisfactionMetrics();

      return {
        'dailyRevenue': dailyRevenue,
        'dailyOrderCounts': dailyOrderCounts,
        'weeklyData': weeklyData,
        'monthlyData': monthlyData,
        'driverPerformance': driverPerformance,
        'satisfactionMetrics': satisfactionMetrics,
        'deliveryTimeAnalysis': await _getDeliveryTimeAnalysis(),
        'geographicAnalysis': await _getGeographicAnalysis(),
      };
    } catch (e) {
      throw DatabaseException('Failed to get chart analytics: $e');
    }
  }

  Future<double> _calculateAvgDeliveryTime(List<order_model.Order> orders) async {
    final deliveredOrders = orders.where((order) => 
        order.status == order_model.OrderStatus.delivered && 
        order.deliveryTime != null).toList();
    
    if (deliveredOrders.isEmpty) return 0.0;
    
    final totalMinutes = deliveredOrders.fold(0.0, (sum, order) {
      final deliveryTime = order.deliveryTime!.difference(order.createdAt).inMinutes;
      return sum + deliveryTime.toDouble();
    });
    
    return totalMinutes / deliveredOrders.length;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<int> _getNewCustomersForMonth(DateTime date) async {
    try {
      final usersSnapshot = await usersCollection
          .where('role', isEqualTo: 'customer')
          .get();
      
      final users = usersSnapshot.docs.map((doc) => User.fromSnapshot(doc)).toList();
      
      return users.where((user) {
        return user.createdAt.year == date.year && user.createdAt.month == date.month;
      }).length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _getDriverPerformanceData() async {
    try {
      final driversSnapshot = await usersCollection
          .where('role', isEqualTo: 'driver')
          .get();
      
      final drivers = driversSnapshot.docs.map((doc) => User.fromSnapshot(doc)).toList();
      final performance = <Map<String, dynamic>>[];
      
      for (final driver in drivers) {
        final driverOrders = await ordersCollection
            .where('driverId', isEqualTo: driver.id)
            .get();
        
        final orders = driverOrders.docs
            .map((doc) => order_model.Order.fromSnapshot(doc))
            .toList();
        
        final deliveredOrders = orders.where((order) => order.status == order_model.OrderStatus.delivered).toList();
        final totalRevenue = deliveredOrders.fold(0.0, (sum, order) => sum + (order.actualCost ?? order.estimatedCost));
        
        performance.add({
          'driverId': driver.id,
          'name': driver.name,
          'totalDeliveries': deliveredOrders.length,
          'totalRevenue': totalRevenue,
          'completionRate': orders.isNotEmpty ? (deliveredOrders.length / orders.length * 100) : 0.0,
        });
      }
      
      // Sort by total deliveries
      performance.sort((a, b) => b['totalDeliveries'].compareTo(a['totalDeliveries']));
      return performance.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getCustomerSatisfactionMetrics() async {
    try {
      // Since rating is not available in the current Order model,
      // we'll use completion rate and delivery time as satisfaction indicators
      final ordersSnapshot = await ordersCollection.get();
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
      
      final deliveredOrders = orders.where((order) => order.status == order_model.OrderStatus.delivered).toList();
      
      if (orders.isEmpty) {
        return {
          'completionRate': 0.0,
          'onTimeDeliveryRate': 0.0,
          'totalOrders': 0,
        };
      }
      
      final completionRate = deliveredOrders.length / orders.length * 100;
      
      final onTimeDeliveries = deliveredOrders.where((order) {
        if (order.deliveryTime == null) return false;
        final deliveryTime = order.deliveryTime!.difference(order.createdAt).inHours;
        return deliveryTime <= 24; // Consider on-time if delivered within 24 hours
      }).length;
      
      final onTimeRate = deliveredOrders.isNotEmpty ? (onTimeDeliveries / deliveredOrders.length * 100) : 0.0;
      
      return {
        'completionRate': completionRate,
        'onTimeDeliveryRate': onTimeRate,
        'totalOrders': orders.length,
      };
    } catch (e) {
      return {
        'completionRate': 0.0,
        'onTimeDeliveryRate': 0.0,
        'totalOrders': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getDeliveryTimeAnalysis() async {
    try {
      final ordersSnapshot = await ordersCollection.get();
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
      
      final deliveredOrders = orders.where((order) => 
          order.status == order_model.OrderStatus.delivered && 
          order.deliveryTime != null).toList();
      
      if (deliveredOrders.isEmpty) {
        return {
          'averageDeliveryTime': 0.0,
          'fastestDelivery': 0.0,
          'slowestDelivery': 0.0,
          'onTimeDeliveryRate': 0.0,
        };
      }
      
      final deliveryTimes = deliveredOrders.map((order) {
        return order.deliveryTime!.difference(order.createdAt).inMinutes.toDouble();
      }).toList();
      
      deliveryTimes.sort();
      
      final avgDeliveryTime = deliveryTimes.fold(0.0, (sum, time) => sum + time) / deliveryTimes.length;
      final onTimeDeliveries = deliveredOrders.where((order) {
        final deliveryTime = order.deliveryTime!.difference(order.createdAt).inHours;
        return deliveryTime <= 24; // Consider on-time if delivered within 24 hours
      }).length;
      
      return {
        'averageDeliveryTime': avgDeliveryTime,
        'fastestDelivery': deliveryTimes.first,
        'slowestDelivery': deliveryTimes.last,
        'onTimeDeliveryRate': (onTimeDeliveries / deliveredOrders.length * 100),
      };
    } catch (e) {
      return {
        'averageDeliveryTime': 0.0,
        'fastestDelivery': 0.0,
        'slowestDelivery': 0.0,
        'onTimeDeliveryRate': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getGeographicAnalysis() async {
    try {
      final ordersSnapshot = await ordersCollection.get();
      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromSnapshot(doc))
          .toList();
      
      final cityDistribution = <String, int>{};
      final regionRevenue = <String, double>{};
      
      for (final order in orders) {
        final city = order.deliveryAddress.city;
        cityDistribution[city] = (cityDistribution[city] ?? 0) + 1;
        
        if (order.status == order_model.OrderStatus.delivered) {
          regionRevenue[city] = (regionRevenue[city] ?? 0.0) + (order.actualCost ?? order.estimatedCost);
        }
      }
      
      // Sort cities by order count
      final sortedCities = cityDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'cityDistribution': Map.fromEntries(sortedCities.take(10)),
        'regionRevenue': regionRevenue,
        'topCities': sortedCities.take(5).map((e) => {
          'city': e.key,
          'orders': e.value,
          'revenue': regionRevenue[e.key] ?? 0.0,
        }).toList(),
      };
    } catch (e) {
      return {
        'cityDistribution': <String, int>{},
        'regionRevenue': <String, double>{},
        'topCities': <Map<String, dynamic>>[],
      };
    }
  }

  // Generate tracking number
  String _generateTrackingNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'SC${timestamp.substring(timestamp.length - 8)}';
  }
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => message;
}
