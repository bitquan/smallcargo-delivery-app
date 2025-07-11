import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../models/order.dart' as order_model;
import '../../services/tracking_service.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Sample active order for demo
  order_model.Order? _activeOrder;
  StreamSubscription<DriverLocation>? _locationSubscription;
  
  // Driver location
  LatLng _currentDriverLocation = const LatLng(40.7128, -74.0060); // NYC
  double _driverHeading = 0.0;
  double _driverSpeed = 0.0;
  
  // Map settings
  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadActiveOrder();
    _startRealTimeTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    TrackingService.stopTracking();
    super.dispose();
  }

  void _loadActiveOrder() {
    // Demo order - in real app, load from database
    setState(() {
      _activeOrder = order_model.Order(
        id: 'demo_order_123',
        trackingNumber: 'SC123456',
        customerId: 'demo_customer',
        driverId: 'demo_driver',
        pickupAddress: order_model.Address(
          street: '123 Main St',
          city: 'New York',
          state: 'NY',
          zipCode: '10001',
          country: 'USA',
        ),
        deliveryAddress: order_model.Address(
          street: '456 Broadway',
          city: 'New York',
          state: 'NY',
          zipCode: '10013',
          country: 'USA',
        ),
        description: 'Electronics Package',
        weight: 5.0,
        estimatedCost: 45.50,
        status: order_model.OrderStatus.inTransit,
        priority: order_model.OrderPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 35)),
      );
    });
    _updateMapMarkers();
  }

  void _startRealTimeTracking() {
    if (_activeOrder != null) {
      TrackingService.startTracking(_activeOrder!);
      _locationSubscription = TrackingService.locationStream.listen((location) {
        setState(() {
          _currentDriverLocation = location.position;
          _driverHeading = location.heading;
          _driverSpeed = location.speed;
          _activeOrder = _activeOrder!.copyWith(
            estimatedDeliveryTime: location.estimatedArrival,
          );
        });
        _updateMapMarkers();
      });
    }
  }

  void _updateMapMarkers() {
    if (_activeOrder == null) return;
    
    setState(() {
      _markers = {
        // Pickup marker
        Marker(
          markerId: const MarkerId('pickup'),
          position: const LatLng(40.7128, -74.0060), // Pickup location
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _activeOrder!.pickupAddress.street,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        
        // Delivery marker
        Marker(
          markerId: const MarkerId('delivery'),
          position: const LatLng(40.7295, -74.0103), // Delivery location
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: _activeOrder!.deliveryAddress.street,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        
        // Driver marker
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentDriverLocation,
          infoWindow: InfoWindow(
            title: 'Driver: ${_activeOrder!.driverId ?? "Unknown"}',
            snippet: 'En route to delivery',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: _driverHeading,
        ),
      };
      
      // Add polyline for route
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            const LatLng(40.7128, -74.0060), // Pickup
            _currentDriverLocation, // Current driver location
            const LatLng(40.7295, -74.0103), // Delivery
          ],
          color: AppConstants.primaryColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapMarkers();
  }

  void _centerMapOnDriver() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentDriverLocation),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DB6AC),
      appBar: const GradientAppBar(
        title: 'Order Tracking',
      ),
      body: _activeOrder == null
          ? _buildNoActiveOrderView()
          : _buildTrackingView(),
    );
  }

  Widget _buildNoActiveOrderView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 16),
          Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create an order to start tracking',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingView() {
    return Column(
      children: [
        // Order status header
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildOrderStatusCard(),
        ),
        
        // Map
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: _defaultCenter,
                  zoom: _defaultZoom,
                ),
                markers: _markers,
                polylines: _polylines,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapType: MapType.normal,
              ),
            ),
          ),
        ),
        
        // Driver info and actions
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDriverInfoCard(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${_activeOrder!.trackingNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeOrder!.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_activeOrder!.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(_activeOrder!.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderTimeline(),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Row(
      children: [
        _buildTimelineStep(
          icon: Icons.store,
          title: 'Picked Up',
          time: '2 hours ago',
          isCompleted: true,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: AppConstants.primaryColor,
          ),
        ),
        _buildTimelineStep(
          icon: Icons.local_shipping,
          title: 'In Transit',
          time: 'Now',
          isCompleted: true,
          isActive: true,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[300],
          ),
        ),
        _buildTimelineStep(
          icon: Icons.home,
          title: 'Delivered',
          time: '35 mins',
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String time,
    required bool isCompleted,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppConstants.primaryColor 
                : isActive 
                    ? AppConstants.accentColor 
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted || isActive ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCompleted || isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: isCompleted || isActive ? AppConstants.primaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppConstants.primaryColor,
            child: Text(
              _activeOrder!.driverId?.isNotEmpty == true 
                  ? _activeOrder!.driverId![0].toUpperCase() 
                  : 'D',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeOrder!.driverId ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ETA: ${DateFormat('h:mm a').format(_activeOrder!.estimatedDeliveryTime!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_driverSpeed > 0)
                  Text(
                    'Speed: ${_driverSpeed.toStringAsFixed(0)} mph',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GradientOutlinedButton(
            onPressed: () {
              // TODO: Implement call driver
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${_activeOrder!.driverId}...'),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 18),
                SizedBox(width: 8),
                Text('Call Driver'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GradientElevatedButton(
            onPressed: _centerMapOnDriver,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.my_location, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Center Map', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.blue;
      case order_model.OrderStatus.pickedUp:
        return Colors.purple;
      case order_model.OrderStatus.inTransit:
        return AppConstants.primaryColor;
      case order_model.OrderStatus.delivered:
        return Colors.green;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'PENDING';
      case order_model.OrderStatus.confirmed:
        return 'CONFIRMED';
      case order_model.OrderStatus.pickedUp:
        return 'PICKED UP';
      case order_model.OrderStatus.inTransit:
        return 'IN TRANSIT';
      case order_model.OrderStatus.delivered:
        return 'DELIVERED';
      case order_model.OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
