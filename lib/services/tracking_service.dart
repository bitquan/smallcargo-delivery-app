import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/order.dart' as order_model;

class TrackingService {
  static const List<LatLng> _routePoints = [
    LatLng(40.7128, -74.0060), // Pickup location
    LatLng(40.7150, -74.0070), // Waypoint 1
    LatLng(40.7180, -74.0080), // Waypoint 2
    LatLng(40.7220, -74.0085), // Waypoint 3
    LatLng(40.7250, -74.0090), // Waypoint 4
    LatLng(40.7280, -74.0095), // Waypoint 5
    LatLng(40.7295, -74.0103), // Delivery location
  ];

  static int _currentPointIndex = 0;
  static Timer? _trackingTimer;
  static final StreamController<DriverLocation> _locationController = 
      StreamController<DriverLocation>.broadcast();

  static Stream<DriverLocation> get locationStream => _locationController.stream;

  static void startTracking(order_model.Order order) {
    _trackingTimer?.cancel();
    _currentPointIndex = 0;
    
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPointIndex < _routePoints.length - 1) {
        final currentPoint = _routePoints[_currentPointIndex];
        final nextPoint = _routePoints[_currentPointIndex + 1];
        
        // Interpolate between current and next point
        final progress = Random().nextDouble() * 0.3 + 0.1; // 10-40% progress
        final lat = currentPoint.latitude + 
            (nextPoint.latitude - currentPoint.latitude) * progress;
        final lng = currentPoint.longitude + 
            (nextPoint.longitude - currentPoint.longitude) * progress;
        
        final location = DriverLocation(
          orderId: order.id,
          position: LatLng(lat, lng),
          heading: _calculateHeading(currentPoint, nextPoint),
          speed: 25 + Random().nextDouble() * 10, // 25-35 mph
          timestamp: DateTime.now(),
          estimatedArrival: DateTime.now().add(Duration(
            minutes: 30 - (_currentPointIndex * 5),
          )),
        );
        
        _locationController.add(location);
        
        // Move to next point occasionally
        if (Random().nextDouble() < 0.3) {
          _currentPointIndex++;
        }
      } else {
        // Reached destination
        final location = DriverLocation(
          orderId: order.id,
          position: _routePoints.last,
          heading: 0,
          speed: 0,
          timestamp: DateTime.now(),
          estimatedArrival: DateTime.now(),
        );
        _locationController.add(location);
        stopTracking();
      }
    });
  }

  static void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  static double _calculateHeading(LatLng from, LatLng to) {
    final dLng = to.longitude - from.longitude;
    final dLat = to.latitude - from.latitude;
    final heading = atan2(dLng, dLat) * 180 / pi;
    return heading < 0 ? heading + 360 : heading;
  }

  static void dispose() {
    _trackingTimer?.cancel();
    _locationController.close();
  }
}

class DriverLocation {
  final String orderId;
  final LatLng position;
  final double heading;
  final double speed; // mph
  final DateTime timestamp;
  final DateTime estimatedArrival;

  DriverLocation({
    required this.orderId,
    required this.position,
    required this.heading,
    required this.speed,
    required this.timestamp,
    required this.estimatedArrival,
  });
}
