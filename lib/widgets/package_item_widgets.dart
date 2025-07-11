import 'package:flutter/material.dart';
import '../models/package_item.dart';
import '../core/constants/app_constants.dart';

class PackageItemWidget extends StatelessWidget {
  final PackageItem item;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  const PackageItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class AddItemForm extends StatefulWidget {
  final VoidCallback onAdd;
  final TextEditingController descriptionController;
  final TextEditingController weightController;
  final TextEditingController dimensionsController;
  final TextEditingController specialInstructionsController;

  const AddItemForm({
    super.key,
    required this.onAdd,
    required this.descriptionController,
    required this.weightController,
    required this.dimensionsController,
    required this.specialInstructionsController,
  });

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Item',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: widget.descriptionController,
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
                  controller: widget.weightController,
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
                  controller: widget.dimensionsController,
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
            controller: widget.specialInstructionsController,
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
          
          // Add Photos Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement photo selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo selection coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
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
    );
  }
}
