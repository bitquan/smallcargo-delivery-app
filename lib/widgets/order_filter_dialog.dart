import 'package:flutter/material.dart';
import '../../models/order.dart' as order_model;
import '../../core/constants/app_constants.dart';

class OrderFilterDialog extends StatefulWidget {
  final order_model.OrderPriority? initialPriority;
  final double? initialMaxDistance;
  final double? initialMinPayment;
  final String? initialSortBy;
  final Function(
    order_model.OrderPriority? priority,
    double? maxDistance,
    double? minPayment,
    String? sortBy,
  ) onApplyFilters;

  const OrderFilterDialog({
    super.key,
    this.initialPriority,
    this.initialMaxDistance,
    this.initialMinPayment,
    this.initialSortBy,
    required this.onApplyFilters,
  });

  @override
  State<OrderFilterDialog> createState() => _OrderFilterDialogState();
}

class _OrderFilterDialogState extends State<OrderFilterDialog> {
  order_model.OrderPriority? _selectedPriority;
  double _maxDistance = 50.0;
  double _minPayment = 0.0;
  String _sortBy = 'priority';

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriority;
    _maxDistance = widget.initialMaxDistance ?? 50.0;
    _minPayment = widget.initialMinPayment ?? 0.0;
    _sortBy = widget.initialSortBy ?? 'priority';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Priority Filter
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPriorityChip('All', null),
                ...order_model.OrderPriority.values.map((priority) =>
                    _buildPriorityChip(priority.name.toUpperCase(), priority)),
              ],
            ),
            const SizedBox(height: 24),

            // Max Distance Filter
            const Text(
              'Maximum Distance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxDistance,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    activeColor: AppConstants.primaryColor,
                    label: '${_maxDistance.round()} km',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                ),
                Text('${_maxDistance.round()} km'),
              ],
            ),
            const SizedBox(height: 24),

            // Min Payment Filter
            const Text(
              'Minimum Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _minPayment,
                    min: 0.0,
                    max: 200.0,
                    divisions: 40,
                    activeColor: AppConstants.primaryColor,
                    label: '\$${_minPayment.round()}',
                    onChanged: (value) {
                      setState(() {
                        _minPayment = value;
                      });
                    },
                  ),
                ),
                Text('\$${_minPayment.round()}'),
              ],
            ),
            const SizedBox(height: 24),

            // Sort By
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip('Priority', 'priority'),
                _buildSortChip('Payment', 'payment'),
                _buildSortChip('Distance', 'distance'),
                _buildSortChip('Time', 'time'),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Reset filters
                      setState(() {
                        _selectedPriority = null;
                        _maxDistance = 50.0;
                        _minPayment = 0.0;
                        _sortBy = 'priority';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(
                        _selectedPriority,
                        _maxDistance,
                        _minPayment,
                        _sortBy,
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, order_model.OrderPriority? priority) {
    final isSelected = _selectedPriority == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPriority = selected ? priority : null;
        });
      },
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryColor,
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryColor,
    );
  }
}
