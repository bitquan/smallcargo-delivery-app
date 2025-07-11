import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order.dart' as order_model;
import '../../services/database_service.dart';
import '../../widgets/common_widgets.dart';

class EditOrderScreen extends StatefulWidget {
  final order_model.Order order;

  const EditOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _descriptionController;
  late TextEditingController _weightController;
  late TextEditingController _specialInstructionsController;
  
  // Pickup address controllers
  late TextEditingController _pickupStreetController;
  late TextEditingController _pickupCityController;
  late TextEditingController _pickupStateController;
  late TextEditingController _pickupZipController;
  
  // Delivery address controllers
  late TextEditingController _deliveryStreetController;
  late TextEditingController _deliveryCityController;
  late TextEditingController _deliveryStateController;
  late TextEditingController _deliveryZipController;
  
  // Form state
  late order_model.OrderPriority _priority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _descriptionController = TextEditingController(text: widget.order.description);
    _weightController = TextEditingController(
      text: widget.order.weight?.toString() ?? '',
    );
    _specialInstructionsController = TextEditingController(
      text: widget.order.specialInstructions ?? '',
    );
    
    // Pickup address
    _pickupStreetController = TextEditingController(
      text: widget.order.pickupAddress.street,
    );
    _pickupCityController = TextEditingController(
      text: widget.order.pickupAddress.city,
    );
    _pickupStateController = TextEditingController(
      text: widget.order.pickupAddress.state,
    );
    _pickupZipController = TextEditingController(
      text: widget.order.pickupAddress.zipCode,
    );
    
    // Delivery address
    _deliveryStreetController = TextEditingController(
      text: widget.order.deliveryAddress.street,
    );
    _deliveryCityController = TextEditingController(
      text: widget.order.deliveryAddress.city,
    );
    _deliveryStateController = TextEditingController(
      text: widget.order.deliveryAddress.state,
    );
    _deliveryZipController = TextEditingController(
      text: widget.order.deliveryAddress.zipCode,
    );
    
    _priority = widget.order.priority;
  }

  @override
  void dispose() {
    // Dispose all controllers
    _descriptionController.dispose();
    _weightController.dispose();
    _specialInstructionsController.dispose();
    _pickupStreetController.dispose();
    _pickupCityController.dispose();
    _pickupStateController.dispose();
    _pickupZipController.dispose();
    _deliveryStreetController.dispose();
    _deliveryCityController.dispose();
    _deliveryStateController.dispose();
    _deliveryZipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4DB6AC),
      appBar: GradientAppBar(
        title: 'Edit Order #${widget.order.trackingNumber}',
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order cannot be edited warning if not pending
              if (widget.order.status != order_model.OrderStatus.pending)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This order has been ${widget.order.status.name}. Only basic information can be edited.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Package Details Section
              _buildSection(
                'Package Details',
                [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Package Description *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a package description';
                      }
                      return null;
                    },
                    enabled: widget.order.status == order_model.OrderStatus.pending,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (lbs)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      suffixText: 'lbs',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: widget.order.status == order_model.OrderStatus.pending,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Priority Section
              _buildSection(
                'Priority Level',
                [
                  ...order_model.OrderPriority.values.map((priority) {
                    return RadioListTile<order_model.OrderPriority>(
                      title: Text(priority.name.toUpperCase()),
                      subtitle: Text(_getPriorityDescription(priority)),
                      value: priority,
                      groupValue: _priority,
                      onChanged: widget.order.status == order_model.OrderStatus.pending
                          ? (value) {
                              setState(() {
                                _priority = value!;
                              });
                            }
                          : null,
                      activeColor: AppConstants.primaryColor,
                      tileColor: Colors.white,
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pickup Address Section
              _buildSection(
                'Pickup Address',
                [
                  _buildAddressForm(
                    streetController: _pickupStreetController,
                    cityController: _pickupCityController,
                    stateController: _pickupStateController,
                    zipController: _pickupZipController,
                    enabled: widget.order.status == order_model.OrderStatus.pending,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Delivery Address Section
              _buildSection(
                'Delivery Address',
                [
                  _buildAddressForm(
                    streetController: _deliveryStreetController,
                    cityController: _deliveryCityController,
                    stateController: _deliveryStateController,
                    zipController: _deliveryZipController,
                    enabled: widget.order.status == order_model.OrderStatus.pending,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: GradientElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressForm({
    required TextEditingController streetController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController zipController,
    required bool enabled,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a street address';
            }
            return null;
          },
          enabled: enabled,
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a city';
                  }
                  return null;
                },
                enabled: enabled,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a state';
                  }
                  return null;
                },
                enabled: enabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: zipController,
          decoration: const InputDecoration(
            labelText: 'ZIP Code *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a ZIP code';
            }
            return null;
          },
          enabled: enabled,
        ),
      ],
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Create updated addresses
      final updatedPickupAddress = order_model.Address(
        street: _pickupStreetController.text.trim(),
        city: _pickupCityController.text.trim(),
        state: _pickupStateController.text.trim(),
        zipCode: _pickupZipController.text.trim(),
        country: widget.order.pickupAddress.country,
      );
      
      final updatedDeliveryAddress = order_model.Address(
        street: _deliveryStreetController.text.trim(),
        city: _deliveryCityController.text.trim(),
        state: _deliveryStateController.text.trim(),
        zipCode: _deliveryZipController.text.trim(),
        country: widget.order.deliveryAddress.country,
      );
      
      // Prepare updates map
      final updates = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'weight': double.tryParse(_weightController.text),
        'specialInstructions': _specialInstructionsController.text.trim().isEmpty 
            ? null 
            : _specialInstructionsController.text.trim(),
        'priority': _priority.name,
        'pickupAddress': updatedPickupAddress.toMap(),
        'deliveryAddress': updatedDeliveryAddress.toMap(),
        'updatedAt': DateTime.now(),
      };
      
      await databaseService.updateOrder(widget.order.id, updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
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
}
