import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

enum OrderPriority {
  low,
  medium,
  high,
  urgent,
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? additionalInfo;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'additionalInfo': additionalInfo,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      additionalInfo: map['additionalInfo'],
    );
  }

  String get fullAddress {
    return '$street, $city, $state $zipCode, $country';
  }

  @override
  String toString() => fullAddress;
}

class Order {
  final String id;
  final String customerId;
  final String? driverId;
  final String trackingNumber;
  final OrderStatus status;
  final OrderPriority priority;
  final Address pickupAddress;
  final Address deliveryAddress;
  final String description;
  final double? weight;
  final String? dimensions;
  final double estimatedCost;
  final double? actualCost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DateTime? estimatedDeliveryTime;
  final List<String> imageUrls;
  final Map<String, dynamic>? additionalData;
  final String? specialInstructions;

  const Order({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.trackingNumber,
    required this.status,
    required this.priority,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.description,
    this.weight,
    this.dimensions,
    required this.estimatedCost,
    this.actualCost,
    required this.createdAt,
    required this.updatedAt,
    this.pickupTime,
    this.deliveryTime,
    this.estimatedDeliveryTime,
    this.imageUrls = const [],
    this.additionalData,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'driverId': driverId,
      'trackingNumber': trackingNumber,
      'status': status.name,
      'priority': priority.name,
      'pickupAddress': pickupAddress.toMap(),
      'deliveryAddress': deliveryAddress.toMap(),
      'description': description,
      'weight': weight,
      'dimensions': dimensions,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
      'deliveryTime': deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
      'estimatedDeliveryTime': estimatedDeliveryTime != null ? Timestamp.fromDate(estimatedDeliveryTime!) : null,
      'imageUrls': imageUrls,
      'additionalData': additionalData,
      'specialInstructions': specialInstructions,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    try {
      // Handle address conversion more carefully
      Map<String, dynamic> pickupAddressData = {};
      Map<String, dynamic> deliveryAddressData = {};
      
      if (map['pickupAddress'] is Map<String, dynamic>) {
        pickupAddressData = map['pickupAddress'];
      } else if (map['pickupAddress'] is String) {
        // If it's a string, create a minimal address
        pickupAddressData = {
          'street': map['pickupAddress'],
          'city': '',
          'state': '',
          'zipCode': '',
          'country': '',
        };
      }
      
      if (map['deliveryAddress'] is Map<String, dynamic>) {
        deliveryAddressData = map['deliveryAddress'];
      } else if (map['deliveryAddress'] is String) {
        // If it's a string, create a minimal address
        deliveryAddressData = {
          'street': map['deliveryAddress'],
          'city': '',
          'state': '',
          'zipCode': '',
          'country': '',
        };
      }
      
      return Order(
        id: map['id'] ?? '',
        customerId: map['customerId'] ?? '',
        driverId: map['driverId'],
        trackingNumber: map['trackingNumber'] ?? '',
        status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        priority: OrderPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => OrderPriority.medium,
        ),
        pickupAddress: Address.fromMap(pickupAddressData),
        deliveryAddress: Address.fromMap(deliveryAddressData),
        description: map['description'] ?? '',
        weight: map['weight']?.toDouble(),
        dimensions: map['dimensions'],
        estimatedCost: map['estimatedCost']?.toDouble() ?? 0.0,
        actualCost: map['actualCost']?.toDouble(),
        createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
        pickupTime: _parseTimestamp(map['pickupTime']),
        deliveryTime: _parseTimestamp(map['deliveryTime']),
        estimatedDeliveryTime: _parseTimestamp(map['estimatedDeliveryTime']),
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        additionalData: map['additionalData'] != null 
            ? Map<String, dynamic>.from(map['additionalData'])
            : null,
        specialInstructions: map['specialInstructions'],
      );
    } catch (e) {
      print('Error parsing order from map: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  factory Order.fromSnapshot(DocumentSnapshot snapshot) {
    try {
      final data = snapshot.data();
      if (data == null) {
        throw Exception('Document data is null for order ${snapshot.id}');
      }
      
      if (data is! Map<String, dynamic>) {
        throw Exception('Document data is not a Map<String, dynamic> for order ${snapshot.id}. Type: ${data.runtimeType}');
      }
      
      return Order.fromMap({...data, 'id': snapshot.id});
    } catch (e) {
      print('Error creating order from snapshot ${snapshot.id}: $e');
      print('Snapshot data: ${snapshot.data()}');
      rethrow;
    }
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? driverId,
    String? trackingNumber,
    OrderStatus? status,
    OrderPriority? priority,
    Address? pickupAddress,
    Address? deliveryAddress,
    String? description,
    double? weight,
    String? dimensions,
    double? estimatedCost,
    double? actualCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    DateTime? estimatedDeliveryTime,
    List<String>? imageUrls,
    Map<String, dynamic>? additionalData,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      imageUrls: imageUrls ?? this.imageUrls,
      additionalData: additionalData ?? this.additionalData,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case OrderPriority.low:
        return 'Low';
      case OrderPriority.medium:
        return 'Medium';
      case OrderPriority.high:
        return 'High';
      case OrderPriority.urgent:
        return 'Urgent';
    }
  }

  bool get isCompleted => status == OrderStatus.delivered || status == OrderStatus.cancelled;
  bool get isActive => !isCompleted;
  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.confirmed;

  @override
  String toString() {
    return 'Order(id: $id, trackingNumber: $trackingNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to parse timestamps from various data types
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        // Try to parse ISO string or other common formats
        return DateTime.parse(value);
      } else if (value is int) {
        // Assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    
    return null;
  }
}
