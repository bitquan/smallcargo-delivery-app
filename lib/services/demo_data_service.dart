import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/order.dart' as order_model;
import '../core/constants/app_constants.dart';

class DemoDataService {
  static final DatabaseService _databaseService = DatabaseService();

  static Future<void> createDemoOrder(String customerId) async {
    try {
      final pickupAddress = order_model.Address(
        street: '123 Main Street',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'USA',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      final deliveryAddress = order_model.Address(
        street: '456 Broadway',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11201',
        country: 'USA',
        latitude: 40.6892,
        longitude: -73.9442,
      );

      await _databaseService.createOrder(
        customerId: customerId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        description: 'Demo electronics package - Small cargo delivery test',
        weight: 2.5,
        dimensions: '12x8x6 inches',
        estimatedCost: 25.99,
        priority: order_model.OrderPriority.medium,
        specialInstructions: 'Handle with care - fragile items',
      );

      print('Demo order created successfully!');
    } catch (e) {
      print('Error creating demo order: $e');
    }
  }

  static Future<void> createMultipleDemoOrders(String customerId) async {
    final orders = [
      {
        'pickup': order_model.Address(
          street: '789 5th Avenue',
          city: 'Manhattan',
          state: 'NY',
          zipCode: '10022',
          country: 'USA',
          latitude: 40.7589,
          longitude: -73.9851,
        ),
        'delivery': order_model.Address(
          street: '321 Queens Blvd',
          city: 'Queens',
          state: 'NY',
          zipCode: '11375',
          country: 'USA',
          latitude: 40.7282,
          longitude: -73.8370,
        ),
        'description': 'Documents and legal papers',
        'weight': 0.5,
        'cost': 15.00,
        'priority': order_model.OrderPriority.high,
      },
      {
        'pickup': order_model.Address(
          street: '555 Wall Street',
          city: 'Manhattan',
          state: 'NY',
          zipCode: '10005',
          country: 'USA',
          latitude: 40.7074,
          longitude: -74.0113,
        ),
        'delivery': order_model.Address(
          street: '777 Atlantic Ave',
          city: 'Brooklyn',
          state: 'NY',
          zipCode: '11238',
          country: 'USA',
          latitude: 40.6838,
          longitude: -73.9712,
        ),
        'description': 'Laptop computer for repair',
        'weight': 3.2,
        'cost': 35.50,
        'priority': order_model.OrderPriority.medium,
      },
      {
        'pickup': order_model.Address(
          street: '999 Park Avenue',
          city: 'Manhattan',
          state: 'NY',
          zipCode: '10028',
          country: 'USA',
          latitude: 40.7831,
          longitude: -73.9712,
        ),
        'delivery': order_model.Address(
          street: '111 Long Island Ave',
          city: 'Hempstead',
          state: 'NY',
          zipCode: '11550',
          country: 'USA',
          latitude: 40.7062,
          longitude: -73.6187,
        ),
        'description': 'Medical supplies delivery',
        'weight': 1.8,
        'cost': 42.75,
        'priority': order_model.OrderPriority.urgent,
      },
    ];

    for (final orderData in orders) {
      try {
        await _databaseService.createOrder(
          customerId: customerId,
          pickupAddress: orderData['pickup'] as order_model.Address,
          deliveryAddress: orderData['delivery'] as order_model.Address,
          description: orderData['description'] as String,
          weight: orderData['weight'] as double,
          dimensions: '10x8x4 inches',
          estimatedCost: orderData['cost'] as double,
          priority: orderData['priority'] as order_model.OrderPriority,
        );
        
        // Small delay between orders
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error creating order: $e');
      }
    }
  }
}

class DemoButton extends StatelessWidget {
  final String userId;

  const DemoButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating demo orders...')),
          );
          
          await DemoDataService.createMultipleDemoOrders(userId);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo orders created successfully!'),
                backgroundColor: AppConstants.successColor,
              ),
            );
          }
        },
        icon: const Icon(Icons.add_box),
        label: const Text('Create Demo Orders'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
