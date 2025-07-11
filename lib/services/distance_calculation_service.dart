import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart' as order_model;
import '../config/app_config.dart';

class DistanceCalculationService {
  static const String _distanceMatrixUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  
  // Pricing configuration
  static const double _baseFee = 5.0; // Base fee for any delivery
  static const double _perMileFee = 1.00; // Cost per mile
  static const double _perMinuteFee = 0.15; // Cost per minute
  static const double _weightMultiplier = 0.50; // Additional cost per pound
  static const double _baseLoadingFee = 10.0; // Base loading fee
  static const double _loadingFeePerPound = 0.25; // Additional loading fee per pound
  static const double _baseUnloadingFee = 10.0; // Base unloading fee
  static const double _unloadingFeePerPound = 0.25; // Additional unloading fee per pound
  
  // Priority multipliers
  static const Map<order_model.OrderPriority, double> _priorityMultipliers = {
    order_model.OrderPriority.low: 0.8,      // 20% discount
    order_model.OrderPriority.medium: 1.0,   // Standard rate
    order_model.OrderPriority.high: 1.3,     // 30% premium
    order_model.OrderPriority.urgent: 1.8,   // 80% premium
  };
  
  // Time of day multipliers
  static const Map<String, double> _timeMultipliers = {
    'peak': 1.2,      // Rush hour (7-9 AM, 5-7 PM)
    'standard': 1.0,  // Regular hours
    'late': 1.15,     // Late hours (10 PM - 6 AM)
  };

  /// Calculate distance and duration between two addresses
  static Future<DistanceResult> calculateDistance({
    required order_model.Address pickupAddress,
    required order_model.Address deliveryAddress,
  }) async {
    try {
      // If we have coordinates, use them for more accurate calculation
      String origin, destination;
      
      if (pickupAddress.latitude != null && pickupAddress.longitude != null) {
        origin = '${pickupAddress.latitude},${pickupAddress.longitude}';
      } else {
        origin = Uri.encodeComponent(pickupAddress.fullAddress);
      }
      
      if (deliveryAddress.latitude != null && deliveryAddress.longitude != null) {
        destination = '${deliveryAddress.latitude},${deliveryAddress.longitude}';
      } else {
        destination = Uri.encodeComponent(deliveryAddress.fullAddress);
      }
      
      // For development/testing, return mock data if no API key
      if (!AppConfig.hasValidGoogleApiKey) {
        return _getMockDistanceData(pickupAddress, deliveryAddress);
      }
      
      final url = Uri.parse('$_distanceMatrixUrl?units=imperial&origins=$origin&destinations=$destination&key=${AppConfig.googleMapsApiKey}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            final distance = element['distance']['value'] / 1609.34; // Convert meters to miles
            final duration = element['duration']['value'] / 60; // Convert seconds to minutes
            
            return DistanceResult(
              distanceInMiles: distance,
              durationInMinutes: duration,
              success: true,
            );
          }
        }
      }
      
      // Fallback to mock data if API fails
      return _getMockDistanceData(pickupAddress, deliveryAddress);
    } catch (e) {
      print('Error calculating distance: $e');
      // Return mock data as fallback
      return _getMockDistanceData(pickupAddress, deliveryAddress);
    }
  }

  /// Generate mock distance data for testing
  static DistanceResult _getMockDistanceData(
    order_model.Address pickupAddress,
    order_model.Address deliveryAddress,
  ) {
    // Simple mock calculation based on city differences
    double mockDistance = 5.0; // Base distance
    double mockDuration = 15.0; // Base duration
    
    // If different cities, increase distance
    if (pickupAddress.city.toLowerCase() != deliveryAddress.city.toLowerCase()) {
      mockDistance += 15.0;
      mockDuration += 25.0;
    }
    
    // If different states, increase significantly
    if (pickupAddress.state.toLowerCase() != deliveryAddress.state.toLowerCase()) {
      mockDistance += 100.0;
      mockDuration += 120.0;
    }
    
    // Add some randomness for realistic mock data
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    mockDistance += random * 0.5;
    mockDuration += random * 2;
    
    return DistanceResult(
      distanceInMiles: mockDistance,
      durationInMinutes: mockDuration,
      success: true,
    );
  }

  /// Calculate price based on distance, time, and other factors
  static PricingResult calculatePrice({
    required double distanceInMiles,
    required double durationInMinutes,
    required order_model.OrderPriority priority,
    double? weightInPounds,
    DateTime? scheduledTime,
    bool requiresLoading = true,
    bool requiresUnloading = true,
  }) {
    // Base calculation
    double basePrice = _baseFee;
    double distancePrice = distanceInMiles * _perMileFee;
    double timePrice = durationInMinutes * _perMinuteFee;
    double weightPrice = (weightInPounds ?? 0) * _weightMultiplier;
    
    // Calculate weight-based loading and unloading fees
    double totalWeight = weightInPounds ?? 0.0;
    double loadingPrice = requiresLoading 
        ? _baseLoadingFee + (totalWeight * _loadingFeePerPound)
        : 0.0;
    double unloadingPrice = requiresUnloading 
        ? _baseUnloadingFee + (totalWeight * _unloadingFeePerPound)
        : 0.0;
    
    double subtotal = basePrice + distancePrice + timePrice + weightPrice + loadingPrice + unloadingPrice;
    
    // Apply priority multiplier
    double priorityMultiplier = _priorityMultipliers[priority] ?? 1.0;
    double priorityAdjustment = subtotal * (priorityMultiplier - 1.0);
    
    // Apply time-of-day multiplier
    double timeMultiplier = _getTimeMultiplier(scheduledTime);
    double timeAdjustment = subtotal * (timeMultiplier - 1.0);
    
    double totalPrice = subtotal + priorityAdjustment + timeAdjustment;
    
    return PricingResult(
      basePrice: basePrice,
      distancePrice: distancePrice,
      timePrice: timePrice,
      weightPrice: weightPrice,
      loadingPrice: loadingPrice,
      unloadingPrice: unloadingPrice,
      priorityAdjustment: priorityAdjustment,
      timeAdjustment: timeAdjustment,
      totalPrice: totalPrice,
      distanceInMiles: distanceInMiles,
      durationInMinutes: durationInMinutes,
      priority: priority,
      weightInPounds: weightInPounds,
    );
  }

  /// Get time multiplier based on scheduled time
  static double _getTimeMultiplier(DateTime? scheduledTime) {
    if (scheduledTime == null) return _timeMultipliers['standard']!;
    
    final hour = scheduledTime.hour;
    
    // Peak hours: 7-9 AM and 5-7 PM
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      return _timeMultipliers['peak']!;
    }
    
    // Late hours: 10 PM - 6 AM
    if (hour >= 22 || hour <= 6) {
      return _timeMultipliers['late']!;
    }
    
    return _timeMultipliers['standard']!;
  }

  /// Get estimated delivery time based on distance and priority
  static DateTime getEstimatedDeliveryTime({
    required double durationInMinutes,
    required order_model.OrderPriority priority,
    DateTime? scheduledTime,
  }) {
    final baseTime = scheduledTime ?? DateTime.now();
    
    // Add processing time based on priority
    int processingMinutes = switch (priority) {
      order_model.OrderPriority.urgent => 5,   // 5 minutes
      order_model.OrderPriority.high => 15,    // 15 minutes
      order_model.OrderPriority.medium => 30,  // 30 minutes
      order_model.OrderPriority.low => 60,     // 1 hour
    };
    
    // Add travel time
    int totalMinutes = processingMinutes + durationInMinutes.ceil();
    
    return baseTime.add(Duration(minutes: totalMinutes));
  }
}

class DistanceResult {
  final double distanceInMiles;
  final double durationInMinutes;
  final bool success;
  final String? error;

  DistanceResult({
    required this.distanceInMiles,
    required this.durationInMinutes,
    required this.success,
    this.error,
  });
}

class PricingResult {
  final double basePrice;
  final double distancePrice;
  final double timePrice;
  final double weightPrice;
  final double loadingPrice;
  final double unloadingPrice;
  final double priorityAdjustment;
  final double timeAdjustment;
  final double totalPrice;
  final double distanceInMiles;
  final double durationInMinutes;
  final order_model.OrderPriority priority;
  final double? weightInPounds;

  PricingResult({
    required this.basePrice,
    required this.distancePrice,
    required this.timePrice,
    required this.weightPrice,
    required this.loadingPrice,
    required this.unloadingPrice,
    required this.priorityAdjustment,
    required this.timeAdjustment,
    required this.totalPrice,
    required this.distanceInMiles,
    required this.durationInMinutes,
    required this.priority,
    this.weightInPounds,
  });

  String get formattedBreakdown {
    final buffer = StringBuffer();
    buffer.writeln('Base Fee: \$${basePrice.toStringAsFixed(2)}');
    buffer.writeln('Distance (${distanceInMiles.toStringAsFixed(1)} miles): \$${distancePrice.toStringAsFixed(2)}');
    buffer.writeln('Time (${durationInMinutes.toStringAsFixed(0)} minutes): \$${timePrice.toStringAsFixed(2)}');
    
    if (loadingPrice > 0) {
      if (weightInPounds != null && weightInPounds! > 0) {
        buffer.writeln('Loading Service (${weightInPounds!.toStringAsFixed(1)} lbs): \$${loadingPrice.toStringAsFixed(2)}');
      } else {
        buffer.writeln('Loading Service: \$${loadingPrice.toStringAsFixed(2)}');
      }
    }
    
    if (unloadingPrice > 0) {
      if (weightInPounds != null && weightInPounds! > 0) {
        buffer.writeln('Unloading Service (${weightInPounds!.toStringAsFixed(1)} lbs): \$${unloadingPrice.toStringAsFixed(2)}');
      } else {
        buffer.writeln('Unloading Service: \$${unloadingPrice.toStringAsFixed(2)}');
      }
    }
    
    if (weightInPounds != null && weightInPounds! > 0) {
      buffer.writeln('Weight (${weightInPounds!.toStringAsFixed(1)} lbs): \$${weightPrice.toStringAsFixed(2)}');
    }
    
    if (priorityAdjustment != 0) {
      buffer.writeln('Priority (${priority.name}): \$${priorityAdjustment.toStringAsFixed(2)}');
    }
    
    if (timeAdjustment != 0) {
      buffer.writeln('Time adjustment: \$${timeAdjustment.toStringAsFixed(2)}');
    }
    
    buffer.writeln('Total: \$${totalPrice.toStringAsFixed(2)}');
    
    return buffer.toString();
  }
}
