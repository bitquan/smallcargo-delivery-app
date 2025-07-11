import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../models/order.dart' as order_model;
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class OrderDetailsModal extends StatefulWidget {
  final order_model.Order order;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onTrack;

  const OrderDetailsModal({
    super.key,
    required this.order,
    this.onEdit,
    this.onCancel,
    this.onTrack,
  });

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(
          maxHeight: 700,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.accentColor],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${widget.order.trackingNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${DateFormat('MMM dd, yyyy').format(widget.order.createdAt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(widget.order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Timeline
                    _buildStatusTimeline(),
                    
                    const SizedBox(height: 24),
                    
                    // Addresses
                    _buildAddressSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Package Details
                    _buildPackageDetails(),
                    
                    const SizedBox(height: 24),
                    
                    // Cost Information
                    _buildCostInformation(),
                    
                    const SizedBox(height: 24),
                    
                    // Photos
                    if (widget.order.imageUrls.isNotEmpty) _buildPhotosSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Special Instructions
                    if (widget.order.specialInstructions != null && widget.order.specialInstructions!.isNotEmpty)
                      _buildSpecialInstructions(),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            if (!_isLoading) _buildActionButtons(),
            
            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                'Order Placed',
                DateFormat('MMM dd, yyyy - h:mm a').format(widget.order.createdAt),
                Icons.receipt_long,
                true,
              ),
              if (widget.order.status.index >= order_model.OrderStatus.confirmed.index)
                _buildTimelineItem(
                  'Order Confirmed',
                  'Order has been confirmed',
                  Icons.check_circle,
                  true,
                ),
              if (widget.order.pickupTime != null)
                _buildTimelineItem(
                  'Package Picked Up',
                  DateFormat('MMM dd, yyyy - h:mm a').format(widget.order.pickupTime!),
                  Icons.local_shipping,
                  true,
                ),
              if (widget.order.status == order_model.OrderStatus.inTransit)
                _buildTimelineItem(
                  'In Transit',
                  'Package is on the way',
                  Icons.my_location,
                  true,
                ),
              if (widget.order.deliveryTime != null)
                _buildTimelineItem(
                  'Delivered',
                  DateFormat('MMM dd, yyyy - h:mm a').format(widget.order.deliveryTime!),
                  Icons.done_all,
                  true,
                ),
              if (widget.order.status == order_model.OrderStatus.cancelled)
                _buildTimelineItem(
                  'Cancelled',
                  'Order has been cancelled',
                  Icons.cancel,
                  true,
                  isError: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    bool isActive, {
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red
                  : isActive
                      ? AppConstants.primaryColor
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup & Delivery',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildAddressItem(
                'Pickup Address',
                widget.order.pickupAddress.fullAddress,
                Icons.location_on,
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildAddressItem(
                'Delivery Address',
                widget.order.deliveryAddress.fullAddress,
                Icons.location_on,
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressItem(String title, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Package Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Description', widget.order.description),
              if (widget.order.weight != null)
                _buildDetailRow('Weight', '${widget.order.weight!.toStringAsFixed(1)} lbs'),
              if (widget.order.dimensions != null)
                _buildDetailRow('Dimensions', widget.order.dimensions!),
              _buildDetailRow('Priority', widget.order.priority.name.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildCostRow('Estimated Cost', widget.order.estimatedCost),
              if (widget.order.actualCost != null)
                _buildCostRow('Actual Cost', widget.order.actualCost!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Package Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.order.imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.order.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.order.specialInstructions!,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canCancel = widget.order.status == order_model.OrderStatus.pending ||
                     widget.order.status == order_model.OrderStatus.confirmed;
    
    final canEdit = widget.order.status == order_model.OrderStatus.pending;
    
    final canTrack = widget.order.status == order_model.OrderStatus.pickedUp ||
                    widget.order.status == order_model.OrderStatus.inTransit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Track Order Button
          if (canTrack)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onTrack != null) widget.onTrack!();
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          if (canTrack && (canEdit || canCancel)) const SizedBox(width: 12),
          
          // Edit Order Button
          if (canEdit)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleEditOrder(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          if (canEdit && canCancel) const SizedBox(width: 12),
          
          // Cancel Order Button
          if (canCancel)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleCancelOrder(),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleEditOrder() {
    Navigator.of(context).pop();
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      // Navigate to edit order screen
      _navigateToEditOrder();
    }
  }

  void _navigateToEditOrder() {
    // This will be implemented when we create the edit order screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit order feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _handleCancelOrder() async {
    final reason = await _showCancelOrderDialog();
    if (reason != null && reason.isNotEmpty) {
      await _cancelOrder(reason);
    }
  }

  Future<String?> _showCancelOrderDialog() async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            const Text(
              'Reason for cancellation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Please provide a reason for cancellation...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for cancellation'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(reason);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String reason) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      await databaseService.cancelOrder(widget.order.id, reason);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onCancel != null) widget.onCancel!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
