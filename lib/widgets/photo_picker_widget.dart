import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';
import '../services/photo_upload_service.dart';
import '../services/photo_picker_service.dart';

class PhotoPickerWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(List<String>) onImagesChanged;
  final String itemId;
  final bool isUploading;
  final Function(bool) onUploadingChanged;

  const PhotoPickerWidget({
    super.key,
    required this.imageUrls,
    required this.onImagesChanged,
    required this.itemId,
    this.isUploading = false,
    required this.onUploadingChanged,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (widget.imageUrls.isNotEmpty)
              Text(
                '${widget.imageUrls.length} photo${widget.imageUrls.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Photo grid
        if (widget.imageUrls.isNotEmpty) ...[
          _buildPhotoGrid(),
          const SizedBox(height: 12),
        ],
        
        // Add photo buttons
        _buildAddPhotoButtons(),
        
        // Upload progress
        if (widget.isUploading) ...[
          const SizedBox(height: 12),
          _buildUploadProgress(),
        ],
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return _buildPhotoThumbnail(widget.imageUrls[index], index);
        },
      ),
    );
  }

  Widget _buildPhotoThumbnail(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isUploading ? null : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: const BorderSide(color: AppConstants.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isUploading ? null : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: const BorderSide(color: AppConstants.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Uploading photos...',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      widget.onUploadingChanged(true);
      
      final photoPickerService = PhotoPickerService();
      dynamic imageFile;
      
      if (source == ImageSource.camera) {
        imageFile = await photoPickerService.pickImageFromCamera();
      } else {
        imageFile = await photoPickerService.pickImageFromGallery();
      }
      
      if (imageFile != null) {
        // Upload to Firebase Storage using PhotoUploadService
        final photoUploadService = PhotoUploadService();
        final String? downloadUrl = await photoUploadService.uploadDeliveryProof(
          orderId: widget.itemId,
          driverId: 'current_user', // In real app, get from auth
          imageFile: imageFile,
          description: 'Item photo',
        );
        
        if (downloadUrl != null) {
          final updatedUrls = List<String>.from(widget.imageUrls)..add(downloadUrl);
          widget.onImagesChanged(updatedUrls);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload photo. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      widget.onUploadingChanged(false);
    }
  }

  Future<void> _removePhoto(int index) async {
    final String imageUrl = widget.imageUrls[index];
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // Delete from Firebase Storage
      final photoUploadService = PhotoUploadService();
      await photoUploadService.deletePhoto(imageUrl);
      
      // Update local list
      final updatedUrls = List<String>.from(widget.imageUrls)..removeAt(index);
      widget.onImagesChanged(updatedUrls);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
