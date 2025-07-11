import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission');
        }

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $_fcmToken');
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle notification when app is terminated
        FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          if (kDebugMode) {
            print('FCM Token refreshed: $token');
          }
        });

      } else {
        if (kDebugMode) {
          print('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notifications: $e');
      }
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Handle different notification types
    final notificationType = message.data['type'];
    switch (notificationType) {
      case 'order_update':
        _handleOrderUpdate(message);
        break;
      case 'driver_assignment':
        _handleDriverAssignment(message);
        break;
      case 'delivery_complete':
        _handleDeliveryComplete(message);
        break;
      case 'emergency_alert':
        _handleEmergencyAlert(message);
        break;
      case 'chat_message':
        _handleChatMessage(message);
        break;
      default:
        _handleGenericNotification(message);
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('App opened from notification: ${message.messageId}');
    }
    
    // Navigate to specific screen based on notification type
    final notificationType = message.data['type'];
    final orderId = message.data['orderId'];
    
    switch (notificationType) {
      case 'order_update':
      case 'delivery_complete':
        if (orderId != null) {
          // Navigate to order details screen
          _navigateToOrderDetails(orderId);
        }
        break;
      case 'chat_message':
        if (orderId != null) {
          // Navigate to chat screen
          _navigateToChat(orderId);
        }
        break;
      case 'emergency_alert':
        // Navigate to emergency screen
        _navigateToEmergency();
        break;
    }
  }

  /// Handle initial message when app is opened from terminated state
  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      if (kDebugMode) {
        print('App opened from terminated state with message: ${message.messageId}');
      }
      _handleMessageOpenedApp(message);
    }
  }

  /// Handle order update notifications
  void _handleOrderUpdate(RemoteMessage message) {
    final orderId = message.data['orderId'];
    final status = message.data['status'];
    
    if (kDebugMode) {
      print('Order $orderId status updated to: $status');
    }
    
    // Show local notification if needed
    _showLocalNotification(
      title: message.notification?.title ?? 'Order Update',
      body: message.notification?.body ?? 'Your order status has been updated',
      payload: orderId,
    );
  }

  /// Handle driver assignment notifications
  void _handleDriverAssignment(RemoteMessage message) {
    final orderId = message.data['orderId'];
    final driverName = message.data['driverName'];
    
    if (kDebugMode) {
      print('Driver $driverName assigned to order $orderId');
    }
    
    _showLocalNotification(
      title: 'Driver Assigned',
      body: '$driverName will deliver your order',
      payload: orderId,
    );
  }

  /// Handle delivery complete notifications
  void _handleDeliveryComplete(RemoteMessage message) {
    final orderId = message.data['orderId'];
    
    if (kDebugMode) {
      print('Order $orderId delivered');
    }
    
    _showLocalNotification(
      title: 'Delivery Complete',
      body: 'Your order has been delivered successfully',
      payload: orderId,
    );
  }

  /// Handle emergency alert notifications
  void _handleEmergencyAlert(RemoteMessage message) {
    final alertType = message.data['alertType'];
    final location = message.data['location'];
    
    if (kDebugMode) {
      print('Emergency alert: $alertType at $location');
    }
    
    _showLocalNotification(
      title: 'Emergency Alert',
      body: message.notification?.body ?? 'Emergency situation reported',
      payload: 'emergency',
      isUrgent: true,
    );
  }

  /// Handle chat message notifications
  void _handleChatMessage(RemoteMessage message) {
    final orderId = message.data['orderId'];
    final senderName = message.data['senderName'];
    final messageText = message.data['message'];
    
    if (kDebugMode) {
      print('Chat message from $senderName: $messageText');
    }
    
    _showLocalNotification(
      title: 'New Message from $senderName',
      body: messageText,
      payload: orderId,
    );
  }

  /// Handle generic notifications
  void _handleGenericNotification(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data['payload'],
    );
  }

  /// Show local notification
  void _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isUrgent = false,
  }) {
    // This would integrate with a local notification plugin
    // For now, we'll just log it
    if (kDebugMode) {
      print('Local Notification:');
      print('Title: $title');
      print('Body: $body');
      print('Payload: $payload');
      print('Urgent: $isUrgent');
    }
  }

  /// Navigation helpers (would be implemented with actual navigation)
  void _navigateToOrderDetails(String orderId) {
    if (kDebugMode) {
      print('Navigate to order details: $orderId');
    }
    // Implement navigation logic
  }

  void _navigateToChat(String orderId) {
    if (kDebugMode) {
      print('Navigate to chat for order: $orderId');
    }
    // Implement navigation logic
  }

  void _navigateToEmergency() {
    if (kDebugMode) {
      print('Navigate to emergency screen');
    }
    // Implement navigation logic
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done from a backend service
    // For demo purposes, we'll just log it
    if (kDebugMode) {
      print('Sending notification to user $userId:');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
    }
  }

  /// Send notification to topic
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done from a backend service
    if (kDebugMode) {
      print('Sending notification to topic $topic:');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      // This would clear local notifications
      if (kDebugMode) {
        print('Clearing all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
    }
  }
}
