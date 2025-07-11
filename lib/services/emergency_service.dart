import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  /// Quick emergency alert
  Future<void> triggerEmergencyAlert(BuildContext context, String orderId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;

      // Get current location if available
      final location = await LocationService().getCurrentPosition();
      
      await DatabaseService().reportEmergency(
        userId: user.id,
        orderId: orderId,
        emergencyType: 'general',
        description: 'Emergency alert triggered from app',
        latitude: location?.latitude,
        longitude: location?.longitude,
      );

      _showEmergencyConfirmation(context);
    } catch (e) {
      _showEmergencyError(context, e.toString());
    }
  }

  void _showEmergencyConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Emergency Alert Sent'),
        content: const Text(
          'Your emergency alert has been sent to our support team. '
          'They will contact you shortly. If this is a life-threatening emergency, '
          'please call 911 immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send emergency alert: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

/// Emergency Button Widget
class EmergencyButton extends StatelessWidget {
  final String orderId;
  final bool isCompact;

  const EmergencyButton({
    super.key,
    required this.orderId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: () => _showEmergencyDialog(context),
        icon: const Icon(Icons.emergency, color: Colors.red),
        tooltip: 'Emergency',
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _showEmergencyDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.emergency),
        label: const Text(
          'EMERGENCY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Emergency Alert'),
        content: const Text(
          'Are you sure you want to send an emergency alert? '
          'This will notify our support team immediately.\n\n'
          'For life-threatening emergencies, call 911 directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              EmergencyService().triggerEmergencyAlert(context, orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }
}
