// Tests for Small Cargo Delivery App

import 'package:flutter_test/flutter_test.dart';
import 'package:small_cargo/services/route_optimization_service.dart';

void main() {
  group('Service Tests', () {
    test('RouteOptimizationService can be instantiated', () {
      final service = RouteOptimizationService();
      expect(service, isNotNull);
    });

    test('Route optimization calculates distance', () {
      final service = RouteOptimizationService();
      
      // Test empty orders
      final emptyResult = service.optimizeRoute([], 0.0, 0.0);
      expect(emptyResult, isEmpty);
      
      // Test route time calculation
      final routeTime = service.calculateRouteTime([], 0.0, 0.0);
      expect(routeTime, equals(0.0));
    });

    test('Fuel cost calculation works', () {
      final service = RouteOptimizationService();
      
      // Test empty orders
      final fuelCost = service.calculateFuelCost([], 0.0, 0.0);
      expect(fuelCost, equals(0.0));
    });

    test('Route waypoints generation works', () {
      final service = RouteOptimizationService();
      
      // Test empty orders
      final waypoints = service.getRouteWaypoints([]);
      expect(waypoints, isEmpty);
    });
  });

  group('Utility Tests', () {
    test('Services can be imported without errors', () {
      // Test that core services can be referenced
      expect(RouteOptimizationService, isNotNull);
    });
  });
}
