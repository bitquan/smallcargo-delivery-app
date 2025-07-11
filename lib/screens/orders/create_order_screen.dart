import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_design_system.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order.dart' as order_model;
import '../../models/package_item.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/distance_calculation_service.dart';
import '../../services/pricing_service.dart';
import '../../widgets/photo_picker_widget.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PricingService _pricingService = PricingService();
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Form controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _specialInstructionsController = TextEditingController();
  
  // Pickup address controllers
  final TextEditingController _pickupStreetController = TextEditingController();
  final TextEditingController _pickupCityController = TextEditingController();
  final TextEditingController _pickupStateController = TextEditingController();
  final TextEditingController _pickupZipController = TextEditingController();
  final TextEditingController _pickupCountryController = TextEditingController(text: 'USA');
  
  // Delivery address controllers
  final TextEditingController _deliveryStreetController = TextEditingController();
  final TextEditingController _deliveryCityController = TextEditingController();
  final TextEditingController _deliveryStateController = TextEditingController();
  final TextEditingController _deliveryZipController = TextEditingController();
  final TextEditingController _deliveryCountryController = TextEditingController(text: 'USA');
  
  // Form state
  order_model.OrderPriority _priority = order_model.OrderPriority.medium;
  final List<PackageItem> _packageItems = [];
  bool _isLoading = false;
  double _estimatedCost = 0.0;
  bool _requiresLoading = true;
  bool _requiresUnloading = true;
  
  // Current item photo management
  List<String> _currentItemImages = [];
  bool _isUploadingPhotos = false;
  
  // Distance and pricing data
  DistanceResult? _distanceResult;
  PricingResult? _pricingResult;
  bool _calculatingDistance = false;

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _specialInstructionsController.dispose();
    _pickupStreetController.dispose();
    _pickupCityController.dispose();
    _pickupStateController.dispose();
    _pickupZipController.dispose();
    _pickupCountryController.dispose();
    _deliveryStreetController.dispose();
    _deliveryCityController.dispose();
    _deliveryStateController.dispose();
    _deliveryZipController.dispose();
    _deliveryCountryController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (_currentStep == 0 && _packageItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to your shipment')),
      );
      return;
    }
    
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Calculate distance when moving to review step
      if (_currentStep == 3) {
        _calculateDistanceAndCost();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _calculateDistanceAndCost() async {
    // Check if we have both addresses
    if (_pickupStreetController.text.isEmpty || _pickupCityController.text.isEmpty ||
        _pickupStateController.text.isEmpty || _pickupZipController.text.isEmpty ||
        _deliveryStreetController.text.isEmpty || _deliveryCityController.text.isEmpty ||
        _deliveryStateController.text.isEmpty || _deliveryZipController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _calculatingDistance = true;
    });
    
    try {
      final pickupAddress = order_model.Address(
        street: _pickupStreetController.text.trim(),
        city: _pickupCityController.text.trim(),
        state: _pickupStateController.text.trim(),
        zipCode: _pickupZipController.text.trim(),
        country: _pickupCountryController.text.trim(),
      );
      
      final deliveryAddress = order_model.Address(
        street: _deliveryStreetController.text.trim(),
        city: _deliveryCityController.text.trim(),
        state: _deliveryStateController.text.trim(),
        zipCode: _deliveryZipController.text.trim(),
        country: _deliveryCountryController.text.trim(),
      );
      
      _distanceResult = await DistanceCalculationService.calculateDistance(
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
      );
      
      if (_distanceResult != null && _distanceResult!.success) {
        // Use distance in miles and weight in pounds directly
        final distanceMiles = _distanceResult!.distanceInMiles;
        final weightPounds = _totalWeight; // Already in pounds
        
        // Check if any items require special handling
        bool hasFragileItems = _packageItems.any((item) => 
          item.description.toLowerCase().contains('fragile') ||
          item.description.toLowerCase().contains('delicate') ||
          (item.specialInstructions?.toLowerCase().contains('fragile') ?? false));
        
        // Calculate price using PricingService
        final calculatedPrice = _pricingService.calculatePrice(
          distance: distanceMiles,
          weight: weightPounds,
          priority: _priority.toString().split('.').last, // Convert enum to string
          includeInsurance: true, // Always include for safety
          includeTracking: true, // Always include tracking
          isExpress: _priority == order_model.OrderPriority.urgent,
          isFragile: hasFragileItems,
        );
        
        setState(() {
          _estimatedCost = calculatedPrice;
        });
      }
    } catch (e) {
      print('Error calculating distance and cost: $e');
      // Fall back to simple calculation
      _calculateSimpleEstimatedCost();
    } finally {
      setState(() {
        _calculatingDistance = false;
      });
    }
  }

  void _calculateSimpleEstimatedCost() {
    // Simple cost calculation using PricingService with estimated values
    final totalWeightPounds = _totalWeight; // Already in pounds
    const estimatedDistanceMiles = 15.0; // Fallback distance estimate
    
    // Check if any items require special handling
    bool hasFragileItems = _packageItems.any((item) => 
      item.description.toLowerCase().contains('fragile') ||
      item.description.toLowerCase().contains('delicate') ||
      (item.specialInstructions?.toLowerCase().contains('fragile') ?? false));
    
    // Calculate price using PricingService with estimates
    final calculatedPrice = _pricingService.calculatePrice(
      distance: estimatedDistanceMiles,
      weight: totalWeightPounds,
      priority: _priority.toString().split('.').last,
      includeInsurance: true,
      includeTracking: true,
      isExpress: _priority == order_model.OrderPriority.urgent,
      isFragile: hasFragileItems,
    );
    
    setState(() {
      _estimatedCost = calculatedPrice;
    });
  }

  Future<void> _submitOrder() async {
    if (_packageItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to your shipment')),
      );
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create an order')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pickupAddress = order_model.Address(
        street: _pickupStreetController.text.trim(),
        city: _pickupCityController.text.trim(),
        state: _pickupStateController.text.trim(),
        zipCode: _pickupZipController.text.trim(),
        country: _pickupCountryController.text.trim(),
      );
      
      final deliveryAddress = order_model.Address(
        street: _deliveryStreetController.text.trim(),
        city: _deliveryCityController.text.trim(),
        state: _deliveryStateController.text.trim(),
        zipCode: _deliveryZipController.text.trim(),
        country: _deliveryCountryController.text.trim(),
      );
      
      final order = await databaseService.createOrder(
        customerId: userId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        description: _totalItemsDescription,
        weight: _totalWeight,
        dimensions: _packageItems.map((item) => item.dimensionsDisplay).join(', '),
        estimatedCost: _estimatedCost,
        priority: _priority,
        imageUrls: _packageItems.expand((item) => item.imageUrls).toList(),
        specialInstructions: _packageItems
            .where((item) => item.specialInstructions != null)
            .map((item) => item.specialInstructions!)
            .join('; '),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order created successfully! Tracking: ${order.trackingNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Package items management
  void _addPackageItem() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a package description')),
      );
      return;
    }
    
    if (_isUploadingPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for photos to finish uploading')),
      );
      return;
    }
    
    final newItem = PackageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text.trim(),
      weight: double.tryParse(_weightController.text),
      dimensions: _dimensionsController.text.trim().isEmpty ? null : _dimensionsController.text.trim(),
      imageUrls: List<String>.from(_currentItemImages),
      specialInstructions: _specialInstructionsController.text.trim().isEmpty ? null : _specialInstructionsController.text.trim(),
    );
    
    setState(() {
      _packageItems.add(newItem);
      // Clear form for next item
      _descriptionController.clear();
      _weightController.clear();
      _dimensionsController.clear();
      _specialInstructionsController.clear();
      _currentItemImages.clear();
    });
    
    _calculateSimpleEstimatedCost();
  }
  
  void _removePackageItem(int index) {
    setState(() {
      _packageItems.removeAt(index);
    });
    _calculateSimpleEstimatedCost();
  }
  
  double get _totalWeight {
    return _packageItems.fold(0.0, (sum, item) => sum + item.totalWeight);
  }
  
  String get _totalItemsDescription {
    if (_packageItems.isEmpty) return '';
    return _packageItems.map((item) => item.description).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
          ),
        ),
        title: Text(
          'Create Order',
          style: AppDesignSystem.headlineMedium.copyWith(
            color: AppDesignSystem.backgroundDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppDesignSystem.backgroundDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: AppDesignSystem.backgroundDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Progress indicator with animations
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesignSystem.backgroundCard,
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.primaryGold.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(_totalSteps, (index) {
                    final isActive = index <= _currentStep;
                    
                    return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: isActive 
                                ? AppDesignSystem.primaryGradient
                                : null,
                              color: isActive 
                                ? null 
                                : AppDesignSystem.textMuted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: AppDesignSystem.primaryGold.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStepTitle(index),
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? AppDesignSystem.primaryGold : AppDesignSystem.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: AppDesignSystem.bodyLarge.copyWith(
                    color: AppDesignSystem.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Form content with enhanced design
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: AppDesignSystem.primaryCardDecoration,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPackageDetailsStep(),
                      _buildPickupAddressStep(),
                      _buildDeliveryAddressStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Enhanced Navigation buttons with animations
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesignSystem.backgroundCard,
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.backgroundDark.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppDesignSystem.primaryGold, width: 2),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: _previousStep,
                            child: Center(
                              child: Text(
                                'Back',
                                style: AppDesignSystem.bodyMedium.copyWith(
                                  color: AppDesignSystem.primaryGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppDesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesignSystem.primaryGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _isLoading ? null : (_currentStep < _totalSteps - 1 ? _nextStep : _submitOrder),
                          child: Center(
                            child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.backgroundDark),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep < _totalSteps - 1 ? 'Next' : 'Create Order',
                                  style: AppDesignSystem.bodyMedium.copyWith(
                                    color: AppDesignSystem.backgroundDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Package';
      case 1:
        return 'Pickup';
      case 2:
        return 'Delivery';
      case 3:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildPackageDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Package Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your shipment',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          // Added items list
          if (_packageItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Items Added',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Total Weight: ${_totalWeight.toStringAsFixed(1)} lbs',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_packageItems.length, (index) {
                    final item = _packageItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (item.weight != null)
                                  Text(
                                    'Weight: ${item.weightDisplay}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (item.dimensions != null)
                                  Text(
                                    'Dimensions: ${item.dimensionsDisplay}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (item.imageCount > 0)
                                  Text(
                                    '${item.imageCount} photos',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removePackageItem(index),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Encouragement message for single item
          if (_packageItems.length == 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: You can add multiple items to the same shipment for better value!',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_packageItems.length == 1) const SizedBox(height: 16),
          
                  // Add new item form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _packageItems.isEmpty ? 'Add Your First Item' : 'Add Another Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description *',
                    labelStyle: TextStyle(color: Colors.black87),
                    hintText: 'e.g., Electronics, Documents, Fragile items',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Weight and Dimensions
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (lbs)',
                          labelStyle: TextStyle(color: Colors.black87),
                          hintText: '0.0',
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: 'lbs',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black87),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dimensionsController,
                        decoration: const InputDecoration(
                          labelText: 'Dimensions',
                          labelStyle: TextStyle(color: Colors.black87),
                          hintText: '12"x8"x6"',
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Special Instructions
                TextFormField(
                  controller: _specialInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions (optional)',
                    labelStyle: TextStyle(color: Colors.black87),
                    hintText: 'Handle with care, fragile, etc.',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Photo picker for current item
                PhotoPickerWidget(
                  imageUrls: _currentItemImages,
                  onImagesChanged: (urls) {
                    setState(() {
                      _currentItemImages = urls;
                    });
                  },
                  itemId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  isUploading: _isUploadingPhotos,
                  onUploadingChanged: (uploading) {
                    setState(() {
                      _isUploadingPhotos = uploading;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Add Photos and Add Item buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploadingPhotos ? null : _addPackageItem,
                        icon: const Icon(Icons.add),
                        label: Text(_isUploadingPhotos ? 'Uploading...' : 'Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Priority (moved outside of item form)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...order_model.OrderPriority.values.map((priority) {
                  return RadioListTile<order_model.OrderPriority>(
                    title: Text(
                      priority.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _getPriorityDescription(priority),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    value: priority,
                    groupValue: _priority,
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                      _calculateSimpleEstimatedCost();
                    },
                    activeColor: AppConstants.primaryColor,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Loading and Unloading Services
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text(
                    'Loading Service',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Professional loading at pickup location (+\$${(10.0 + (_totalWeight * 0.25)).toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  value: _requiresLoading,
                  onChanged: (value) {
                    setState(() {
                      _requiresLoading = value!;
                    });
                    _calculateSimpleEstimatedCost();
                  },
                  activeColor: AppConstants.primaryColor,
                ),
                CheckboxListTile(
                  title: const Text(
                    'Unloading Service',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Professional unloading at delivery location (+\$${(10.0 + (_totalWeight * 0.25)).toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  value: _requiresUnloading,
                  onChanged: (value) {
                    setState(() {
                      _requiresUnloading = value!;
                    });
                    _calculateSimpleEstimatedCost();
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Estimated Cost
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Cost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityDescription(order_model.OrderPriority priority) {
    switch (priority) {
      case order_model.OrderPriority.low:
        return 'Standard delivery (3-5 days) - 20% discount';
      case order_model.OrderPriority.medium:
        return 'Regular delivery (1-2 days) - Standard rate';
      case order_model.OrderPriority.high:
        return 'Fast delivery (Same day) - 30% premium';
      case order_model.OrderPriority.urgent:
        return 'Express delivery (Within hours) - 80% premium';
    }
  }

  Widget _buildPickupAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Address',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where should we pick up your package?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildAddressForm(
            streetController: _pickupStreetController,
            cityController: _pickupCityController,
            stateController: _pickupStateController,
            zipController: _pickupZipController,
            countryController: _pickupCountryController,
            onChanged: _calculateDistanceAndCost,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where should we deliver your package?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildAddressForm(
            streetController: _deliveryStreetController,
            cityController: _deliveryCityController,
            stateController: _deliveryStateController,
            zipController: _deliveryZipController,
            countryController: _deliveryCountryController,
            onChanged: _calculateDistanceAndCost,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm({
    required TextEditingController streetController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController zipController,
    required TextEditingController countryController,
    VoidCallback? onChanged,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            labelStyle: TextStyle(color: Colors.black87),
            hintText: '123 Main Street',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
          ),
          style: const TextStyle(color: Colors.black87),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a street address';
            }
            return null;
          },
          onChanged: (value) => onChanged?.call(),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  labelStyle: TextStyle(color: Colors.black87),
                  hintText: 'New York',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a city';
                  }
                  return null;
                },
                onChanged: (value) => onChanged?.call(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  labelStyle: TextStyle(color: Colors.black87),
                  hintText: 'NY',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a state';
                  }
                  return null;
                },
                onChanged: (value) => onChanged?.call(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code *',
                  labelStyle: TextStyle(color: Colors.black87),
                  hintText: '10001',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a ZIP code';
                  }
                  return null;
                },
                onChanged: (value) => onChanged?.call(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: 'Country *',
                  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black87),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a country';
                  }
                  return null;
                },
                onChanged: (value) => onChanged?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Order',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your order details before submitting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildReviewSection(
            'Package Items (${_packageItems.length})',
            _packageItems.isEmpty 
              ? ['No items added yet']
              : _packageItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final itemDetails = <String>[
                    'Item ${index + 1}: ${item.description}',
                    if (item.weight != null) '  Weight: ${item.weightDisplay}',
                    if (item.dimensions != null) '  Dimensions: ${item.dimensionsDisplay}',
                    if (item.specialInstructions != null) '  Special Instructions: ${item.specialInstructions}',
                    if (item.imageCount > 0) '  Photos: ${item.imageCount} attached',
                  ];
                  return itemDetails.join('\n');
                }).toList() + [
                  '',
                  'Total Weight: ${_totalWeight.toStringAsFixed(1)} lbs',
                  'Priority: ${_priority.name.toUpperCase()}',
                  '',
                  'Additional Services:',
                  if (_requiresLoading) 'Loading Service: YES (\$${(10.0 + (_totalWeight * 0.25)).toStringAsFixed(2)})',
                  if (_requiresUnloading) 'Unloading Service: YES (\$${(10.0 + (_totalWeight * 0.25)).toStringAsFixed(2)})',
                  if (!_requiresLoading && !_requiresUnloading) 'No additional services selected',
                ],
          ),
          
          _buildReviewSection(
            'Pickup Address',
            [
              _pickupStreetController.text,
              '${_pickupCityController.text}, ${_pickupStateController.text} ${_pickupZipController.text}',
              _pickupCountryController.text,
            ],
          ),
          
          _buildReviewSection(
            'Delivery Address',
            [
              _deliveryStreetController.text,
              '${_deliveryCityController.text}, ${_deliveryStateController.text} ${_deliveryZipController.text}',
              _deliveryCountryController.text,
            ],
          ),
          
          // Distance and pricing breakdown (if available)
          if (_pricingResult != null) ...[
            _buildReviewSection(
              'Distance & Pricing',
              [
                'Distance: ${_pricingResult!.distanceInMiles.toStringAsFixed(1)} miles',
                'Estimated Time: ${_pricingResult!.durationInMinutes.toStringAsFixed(0)} minutes',
                if (_calculatingDistance) 'Calculating distance...',
              ],
            ),
            
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pricingResult!.formattedBreakdown,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Loading indicator for distance calculation
          if (_calculatingDistance)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Calculating distance and pricing...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          
          // Final cost
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...details.where((detail) => detail.isNotEmpty).map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }

}
