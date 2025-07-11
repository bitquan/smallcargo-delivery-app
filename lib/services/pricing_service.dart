import 'package:flutter/foundation.dart';

class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  // Base pricing configuration
  final Map<String, dynamic> _pricingRules = {
    'baseFee': 5.0,
    'pricePerMile': 4.00, // Changed from pricePerKm to pricePerMile
    'pricePerLb': 0.50,   // Changed from pricePerKg to pricePerLb
    'priorityMultipliers': {
      'low': 1.0,
      'medium': 1.2,
      'high': 1.5,
      'urgent': 2.0,
    },
    'distanceThresholds': {
      'local': {'max': 6, 'multiplier': 1.0},        // 6 miles for local
      'regional': {'max': 30, 'multiplier': 1.1},    // 30 miles for regional
      'longDistance': {'max': 125, 'multiplier': 1.25}, // 125 miles for long distance
      'interstate': {'max': double.infinity, 'multiplier': 1.5},
    },
    'serviceFees': {
      'insurance': 3.0,
      'tracking': 2.0,
      'express': 10.0,
      'fragile': 5.0,
    },
    'minimumPrice': 8.0,
    'maximumPrice': 500.0,
  };

  // Get current pricing rules
  Map<String, dynamic> get pricingRules => Map<String, dynamic>.from(_pricingRules);

  // Calculate price for an order
  double calculatePrice({
    required double distance, // distance in miles
    required double weight,   // weight in pounds
    required String priority,
    bool includeInsurance = false,
    bool includeTracking = true,
    bool isExpress = false,
    bool isFragile = false,
  }) {
    try {
      double price = _pricingRules['baseFee'] as double;
      
      // Distance-based pricing (miles)
      price += distance * (_pricingRules['pricePerMile'] as double);
      
      // Weight-based pricing (pounds)
      price += weight * (_pricingRules['pricePerLb'] as double);
      
      // Priority multiplier
      final priorityMultipliers = _pricingRules['priorityMultipliers'] as Map<String, dynamic>;
      final multiplier = priorityMultipliers[priority.toLowerCase()] ?? 1.0;
      price *= multiplier;
      
      // Distance threshold multiplier
      final distanceMultiplier = _getDistanceMultiplier(distance);
      price *= distanceMultiplier;
      
      // Service fees
      final serviceFees = _pricingRules['serviceFees'] as Map<String, dynamic>;
      if (includeInsurance) price += serviceFees['insurance'] as double;
      if (includeTracking) price += serviceFees['tracking'] as double;
      if (isExpress) price += serviceFees['express'] as double;
      if (isFragile) price += serviceFees['fragile'] as double;
      
      // Apply min/max limits
      final minPrice = _pricingRules['minimumPrice'] as double;
      final maxPrice = _pricingRules['maximumPrice'] as double;
      price = price.clamp(minPrice, maxPrice);
      
      return double.parse(price.toStringAsFixed(2));
    } catch (e) {
      debugPrint('Error calculating price: $e');
      return _pricingRules['minimumPrice'] as double;
    }
  }

  double _getDistanceMultiplier(double distance) {
    final thresholds = _pricingRules['distanceThresholds'] as Map<String, dynamic>;
    
    if (distance <= thresholds['local']['max']) {
      return thresholds['local']['multiplier'] as double;
    } else if (distance <= thresholds['regional']['max']) {
      return thresholds['regional']['multiplier'] as double;
    } else if (distance <= thresholds['longDistance']['max']) {
      return thresholds['longDistance']['multiplier'] as double;
    } else {
      return thresholds['interstate']['multiplier'] as double;
    }
  }

  // Update pricing rules (admin only)
  Future<bool> updatePricingRules(Map<String, dynamic> newRules) async {
    try {
      // Validate the new rules
      if (!_validatePricingRules(newRules)) {
        return false;
      }
      
      // Update rules
      _pricingRules.addAll(newRules);
      
      // In a real app, you'd save to database/storage here
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      debugPrint('Pricing rules updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating pricing rules: $e');
      return false;
    }
  }

  bool _validatePricingRules(Map<String, dynamic> rules) {
    // Basic validation
    if (rules.containsKey('baseFee') && rules['baseFee'] < 0) return false;
    if (rules.containsKey('pricePerMile') && rules['pricePerMile'] < 0) return false;
    if (rules.containsKey('pricePerLb') && rules['pricePerLb'] < 0) return false;
    if (rules.containsKey('minimumPrice') && rules['minimumPrice'] < 0) return false;
    if (rules.containsKey('maximumPrice') && rules['maximumPrice'] <= 0) return false;
    
    return true;
  }

  // Get pricing breakdown for display
  Map<String, dynamic> getPriceBreakdown({
    required double distance, // distance in miles
    required double weight,   // weight in pounds
    required String priority,
    bool includeInsurance = false,
    bool includeTracking = true,
    bool isExpress = false,
    bool isFragile = false,
  }) {
    final baseFee = _pricingRules['baseFee'] as double;
    final distanceFee = distance * (_pricingRules['pricePerMile'] as double);
    final weightFee = weight * (_pricingRules['pricePerLb'] as double);
    
    final priorityMultipliers = _pricingRules['priorityMultipliers'] as Map<String, dynamic>;
    final priorityMultiplier = priorityMultipliers[priority.toLowerCase()] ?? 1.0;
    
    final distanceMultiplier = _getDistanceMultiplier(distance);
    
    double subtotal = (baseFee + distanceFee + weightFee) * priorityMultiplier * distanceMultiplier;
    
    final serviceFees = _pricingRules['serviceFees'] as Map<String, dynamic>;
    double additionalFees = 0;
    if (includeInsurance) additionalFees += serviceFees['insurance'] as double;
    if (includeTracking) additionalFees += serviceFees['tracking'] as double;
    if (isExpress) additionalFees += serviceFees['express'] as double;
    if (isFragile) additionalFees += serviceFees['fragile'] as double;
    
    final total = subtotal + additionalFees;
    final minPrice = _pricingRules['minimumPrice'] as double;
    final maxPrice = _pricingRules['maximumPrice'] as double;
    final finalPrice = total.clamp(minPrice, maxPrice);
    
    return {
      'baseFee': baseFee,
      'distanceFee': distanceFee,
      'weightFee': weightFee,
      'priorityMultiplier': priorityMultiplier,
      'distanceMultiplier': distanceMultiplier,
      'subtotal': subtotal,
      'additionalFees': additionalFees,
      'total': total,
      'finalPrice': double.parse(finalPrice.toStringAsFixed(2)),
      'breakdown': {
        'Base Fee': '\$${baseFee.toStringAsFixed(2)}',
        'Distance (${distance.toStringAsFixed(1)} mi)': '\$${distanceFee.toStringAsFixed(2)}',
        'Weight (${weight.toStringAsFixed(1)} lbs)': '\$${weightFee.toStringAsFixed(2)}',
        'Priority Multiplier (${priority.toUpperCase()})': '${(priorityMultiplier * 100).toStringAsFixed(0)}%',
        'Distance Multiplier': '${(distanceMultiplier * 100).toStringAsFixed(0)}%',
        if (includeInsurance) 'Insurance': '\$${serviceFees['insurance']}',
        if (includeTracking) 'Tracking': '\$${serviceFees['tracking']}',
        if (isExpress) 'Express Delivery': '\$${serviceFees['express']}',
        if (isFragile) 'Fragile Handling': '\$${serviceFees['fragile']}',
      }
    };
  }

  // Get distance category for display
  String getDistanceCategory(double distance) {
    final thresholds = _pricingRules['distanceThresholds'] as Map<String, dynamic>;
    
    if (distance <= thresholds['local']['max']) {
      return 'Local Delivery';
    } else if (distance <= thresholds['regional']['max']) {
      return 'Regional Delivery';
    } else if (distance <= thresholds['longDistance']['max']) {
      return 'Long Distance';
    } else {
      return 'Interstate Delivery';
    }
  }
}
