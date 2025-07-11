import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../core/design_system/app_design_system.dart';
import '../../models/order.dart' as order_model;
import '../../services/tracking_service.dart';
import 'package:intl/intl.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Sample active order for demo
  order_model.Order? _activeOrder;
  StreamSubscription<DriverLocation>? _locationSubscription;
  
  // Driver location
  LatLng _currentDriverLocation = const LatLng(40.7128, -74.0060); // NYC
  double _driverHeading = 0.0;
  
  // Map settings
  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060);
  static const double _defaultZoom = 12.0;
  
  bool _showOrderDetails = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadActiveOrder();
    _startRealTimeTracking();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
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
          color: AppDesignSystem.primaryGold,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Header
              _buildHeader(),
              
              // Map
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                bottom: _showOrderDetails ? 280 : 0,
                child: _buildMap(),
              ),
              
              // Order Details Panel
              if (_showOrderDetails)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 280,
                  child: _buildOrderDetailsPanel(),
                ),
              
              // Floating Action Buttons
              Positioned(
                right: 16,
                bottom: _showOrderDetails ? 300 : 20,
                child: _buildFloatingButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.track_changes,
                        color: AppDesignSystem.primaryGold,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Live Tracking',
                    style: AppDesignSystem.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_activeOrder != null)
                    Text(
                      'Order ${_activeOrder!.trackingNumber}',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Status Badge
          if (_activeOrder != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          initialCameraPosition: const CameraPosition(
            target: _defaultCenter,
            zoom: _defaultZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          mapType: MapType.normal,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: true,
        ),
      ),
    );
  }

  Widget _buildOrderDetailsPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: AppDesignSystem.headlineSmall.copyWith(
                      color: AppDesignSystem.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showOrderDetails = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppDesignSystem.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Order Info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildProgressSteps(),
                    const SizedBox(height: 16),
                    _buildOrderInfo(),
                    const SizedBox(height: 16),
                    _buildDeliveryEstimate(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'title': 'Order Placed', 'completed': true},
      {'title': 'Picked Up', 'completed': true},
      {'title': 'In Transit', 'completed': true},
      {'title': 'Delivered', 'completed': false},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step['completed'] as bool
                            ? AppDesignSystem.primaryGold
                            : AppDesignSystem.textMuted.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: step['completed'] as bool
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['title'] as String,
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: step['completed'] as bool
                            ? AppDesignSystem.primaryGold
                            : AppDesignSystem.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: step['completed'] as bool
                          ? AppDesignSystem.primaryGold
                          : AppDesignSystem.textMuted.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Package',
            _activeOrder?.description ?? 'N/A',
            Icons.inventory_2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Weight',
            '${_activeOrder?.weight ?? 0} kg',
            Icons.scale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Priority',
            _activeOrder?.priority.name.toUpperCase() ?? 'N/A',
            Icons.priority_high,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppDesignSystem.primaryGold.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppDesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.primaryGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryEstimate() {
    final eta = _activeOrder?.estimatedDeliveryTime;
    if (eta == null) return const SizedBox();
    
    final timeRemaining = eta.difference(DateTime.now());
    final etaText = timeRemaining.isNegative
        ? 'Overdue'
        : '${timeRemaining.inMinutes} min';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppDesignSystem.primaryGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(eta),
                  style: AppDesignSystem.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              etaText,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_showOrderDetails)
          FloatingActionButton(
            onPressed: () => setState(() => _showOrderDetails = true),
            backgroundColor: AppDesignSystem.primaryGold,
            child: const Icon(Icons.info_outline, color: Colors.white),
          ),
        const SizedBox(height: 12),
        FloatingActionButton(
          onPressed: _centerMapOnDriver,
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: AppDesignSystem.primaryGold),
        ),
      ],
    );
  }

  void _centerMapOnDriver() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentDriverLocation,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Color _getStatusColor() {
    if (_activeOrder == null) return Colors.grey;
    
    switch (_activeOrder!.status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.blue;
      case order_model.OrderStatus.pickedUp:
        return Colors.purple;
      case order_model.OrderStatus.inTransit:
        return Colors.green;
      case order_model.OrderStatus.delivered:
        return AppDesignSystem.primaryGold;
      case order_model.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    if (_activeOrder == null) return 'No Order';
    
    switch (_activeOrder!.status) {
      case order_model.OrderStatus.pending:
        return 'Pending';
      case order_model.OrderStatus.confirmed:
        return 'Confirmed';
      case order_model.OrderStatus.pickedUp:
        return 'Picked Up';
      case order_model.OrderStatus.inTransit:
        return 'In Transit';
      case order_model.OrderStatus.delivered:
        return 'Delivered';
      case order_model.OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
