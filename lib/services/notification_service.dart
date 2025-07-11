import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as order_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  
  final StreamController<String> _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;

  /// Start listening for new orders for drivers
  void startListeningForDriverNotifications(String driverId) {
    _orderSubscription?.cancel();
    
    // Listen for new available orders
    _orderSubscription = _firestore
        .collection('orders')
        .where('status', isEqualTo: order_model.OrderStatus.pending.name)
        .where('driverId', isNull: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final order = order_model.Order.fromSnapshot(change.doc);
          _notificationController.add('New order available: ${order.description}');
        }
      }
    });
  }

  /// Start listening for order updates for a specific driver
  void startListeningForOrderUpdates(String driverId) {
    _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final order = order_model.Order.fromSnapshot(change.doc);
          _notificationController.add('Order ${order.trackingNumber} updated');
        }
      }
    });
  }

  /// Stop listening for notifications
  void stopListening() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  /// Dispose of the service
  void dispose() {
    _orderSubscription?.cancel();
    _notificationController.close();
  }
}
