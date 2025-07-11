import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message in order chat
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String message,
    String? messageType, // 'text', 'location', 'image'
  }) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'messageType': messageType ?? 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for an order
  Stream<List<Map<String, dynamic>>> getOrderMessages(String orderId) {
    try {
      return _firestore
          .collection('orders')
          .doc(orderId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => {
                'id': doc.id,
                ...doc.data(),
              }).toList());
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String orderId, String userId) async {
    try {
      final batch = _firestore.batch();
      final messagesSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Send location message
  Future<void> sendLocationMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await sendMessage(
        orderId: orderId,
        senderId: senderId,
        senderName: senderName,
        message: 'Location: $latitude, $longitude',
        messageType: 'location',
      );
    } catch (e) {
      throw Exception('Failed to send location: $e');
    }
  }

  /// Get unread message count
  Stream<int> getUnreadMessageCount(String orderId, String userId) {
    try {
      return _firestore
          .collection('orders')
          .doc(orderId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }
}
