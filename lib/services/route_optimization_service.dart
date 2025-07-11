import 'dart:math' as math;
import '../models/order.dart' as order_model;

class RouteOptimizationService {
  static final RouteOptimizationService _instance = RouteOptimizationService._internal();
  factory RouteOptimizationService() => _instance;
  RouteOptimizationService._internal();

  /// Calculate optimized route for multiple orders
  List<order_model.Order> optimizeRoute(
    List<order_model.Order> orders,
    double driverLat,
    double driverLon,
  ) {
    if (orders.length <= 1) return orders;

    // Simple nearest neighbor algorithm for route optimization
    final optimizedRoute = <order_model.Order>[];
    final remainingOrders = List<order_model.Order>.from(orders);
    
    double currentLat = driverLat;
    double currentLon = driverLon;

    while (remainingOrders.isNotEmpty) {
      order_model.Order? nearestOrder;
      double minDistance = double.infinity;
      
      for (final order in remainingOrders) {
        final distance = _calculateDistance(
          currentLat,
          currentLon,
          order.pickupAddress.latitude ?? 0,
          order.pickupAddress.longitude ?? 0,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          nearestOrder = order;
        }
      }

      if (nearestOrder != null) {
        optimizedRoute.add(nearestOrder);
        remainingOrders.remove(nearestOrder);
        currentLat = nearestOrder.deliveryAddress.latitude ?? 0;
        currentLon = nearestOrder.deliveryAddress.longitude ?? 0;
      } else {
        break;
      }
    }

    return optimizedRoute;
  }

  /// Calculate estimated time for route
  double calculateRouteTime(List<order_model.Order> orders, double driverLat, double driverLon) {
    if (orders.isEmpty) return 0.0;

    double totalDistance = 0.0;
    double currentLat = driverLat;
    double currentLon = driverLon;

    for (final order in orders) {
      // Distance to pickup
      totalDistance += _calculateDistance(
        currentLat,
        currentLon,
        order.pickupAddress.latitude ?? 0,
        order.pickupAddress.longitude ?? 0,
      );

      // Distance from pickup to delivery
      totalDistance += _calculateDistance(
        order.pickupAddress.latitude ?? 0,
        order.pickupAddress.longitude ?? 0,
        order.deliveryAddress.latitude ?? 0,
        order.deliveryAddress.longitude ?? 0,
      );

      currentLat = order.deliveryAddress.latitude ?? 0;
      currentLon = order.deliveryAddress.longitude ?? 0;
    }

    // Estimate 30 km/h average speed + 10 minutes per stop
    final drivingTime = (totalDistance / 30) * 60; // minutes
    final stopTime = orders.length * 10; // 10 minutes per stop
    
    return drivingTime + stopTime;
  }

  /// Get route waypoints for navigation
  List<Map<String, double>> getRouteWaypoints(List<order_model.Order> orders) {
    final waypoints = <Map<String, double>>[];

    for (final order in orders) {
      // Add pickup point
      if (order.pickupAddress.latitude != null && order.pickupAddress.longitude != null) {
        waypoints.add({
          'latitude': order.pickupAddress.latitude!,
          'longitude': order.pickupAddress.longitude!,
        });
      }

      // Add delivery point
      if (order.deliveryAddress.latitude != null && order.deliveryAddress.longitude != null) {
        waypoints.add({
          'latitude': order.deliveryAddress.latitude!,
          'longitude': order.deliveryAddress.longitude!,
        });
      }
    }

    return waypoints;
  }

  /// Calculate fuel cost estimate
  double calculateFuelCost(List<order_model.Order> orders, double driverLat, double driverLon) {
    final totalDistance = _calculateTotalDistance(orders, driverLat, driverLon);
    const fuelEfficiency = 10.0; // km per liter
    const fuelPrice = 1.5; // $ per liter
    
    return (totalDistance / fuelEfficiency) * fuelPrice;
  }

  /// Find orders within radius
  List<order_model.Order> getOrdersWithinRadius(
    List<order_model.Order> orders,
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    return orders.where((order) {
      final distance = _calculateDistance(
        centerLat,
        centerLon,
        order.pickupAddress.latitude ?? 0,
        order.pickupAddress.longitude ?? 0,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Group orders by area for batch delivery
  Map<String, List<order_model.Order>> groupOrdersByArea(
    List<order_model.Order> orders,
    double radiusKm,
  ) {
    final groups = <String, List<order_model.Order>>{};
    final processedOrders = <order_model.Order>{};

    for (final order in orders) {
      if (processedOrders.contains(order)) continue;

      final groupKey = '${order.deliveryAddress.latitude?.toStringAsFixed(2)}_${order.deliveryAddress.longitude?.toStringAsFixed(2)}';
      final nearbyOrders = getOrdersWithinRadius(
        orders,
        order.deliveryAddress.latitude ?? 0,
        order.deliveryAddress.longitude ?? 0,
        radiusKm,
      );

      groups[groupKey] = nearbyOrders;
      processedOrders.addAll(nearbyOrders);
    }

    return groups;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  double _calculateTotalDistance(List<order_model.Order> orders, double driverLat, double driverLon) {
    if (orders.isEmpty) return 0.0;

    double totalDistance = 0.0;
    double currentLat = driverLat;
    double currentLon = driverLon;

    for (final order in orders) {
      totalDistance += _calculateDistance(
        currentLat,
        currentLon,
        order.pickupAddress.latitude ?? 0,
        order.pickupAddress.longitude ?? 0,
      );

      totalDistance += _calculateDistance(
        order.pickupAddress.latitude ?? 0,
        order.pickupAddress.longitude ?? 0,
        order.deliveryAddress.latitude ?? 0,
        order.deliveryAddress.longitude ?? 0,
      );

      currentLat = order.deliveryAddress.latitude ?? 0;
      currentLon = order.deliveryAddress.longitude ?? 0;
    }

    return totalDistance;
  }
}
