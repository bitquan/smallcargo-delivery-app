import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'database_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  bool _isTracking = false;
  Position? _lastKnownPosition;

  /// Start tracking driver location
  Future<void> startLocationTracking(String driverId) async {
    if (_isTracking) return;

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _isTracking = true;
    
    // Update location every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        _lastKnownPosition = position;
        
        // Update driver location in database
        await DatabaseService().updateDriverLocation(
          driverId,
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        print('Error updating location: $e');
      }
    });

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition();
      _lastKnownPosition = position;
      await DatabaseService().updateDriverLocation(
        driverId,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  /// Stop tracking driver location
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return _lastKnownPosition;
    }
  }

  /// Calculate distance to pickup/delivery location
  double calculateDistanceToLocation(double targetLat, double targetLon) {
    if (_lastKnownPosition == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      targetLat,
      targetLon,
    ) / 1000; // Convert to kilometers
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  bool get isTracking => _isTracking;
  Position? get lastKnownPosition => _lastKnownPosition;

  void dispose() {
    stopLocationTracking();
  }
}
