import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_upload_service.dart';

class PhotoPickerService {
  static final PhotoPickerService _instance = PhotoPickerService._internal();
  factory PhotoPickerService() => _instance;
  PhotoPickerService._internal();

  final ImagePicker _picker = ImagePicker();
  final PhotoUploadService _uploadService = PhotoUploadService();

  /// Show photo picker options dialog
  Future<dynamic> showPhotoPickerDialog(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop('camera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop('gallery');
                },
              ),
              if (!kIsWeb) // File picker not available on web in same way
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Choose File'),
                  onTap: () {
                    Navigator.of(context).pop('file');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick single image from camera
  Future<dynamic> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;

      if (kIsWeb) {
        return await image.readAsBytes();
      } else {
        return File(image.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from camera: $e');
      }
      return null;
    }
  }

  /// Pick single image from gallery
  Future<dynamic> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;

      if (kIsWeb) {
        return await image.readAsBytes();
      } else {
        return File(image.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<dynamic>> pickMultipleImages() async {
    try {
      // Since pickMultipleImages may not be available on all platforms,
      // we'll simulate it by allowing single picks
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return [];

      final List<dynamic> imageFiles = [];

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        imageFiles.add(bytes);
      } else {
        imageFiles.add(File(image.path));
      }

      return imageFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking multiple images: $e');
      }
      return [];
    }
  }

  /// Pick image with options dialog
  Future<dynamic> pickImage(BuildContext context) async {
    final result = await showPhotoPickerDialog(context);
    
    if (result == null) return null;

    switch (result) {
      case 'camera':
        return await pickImageFromCamera();
      case 'gallery':
        return await pickImageFromGallery();
      case 'file':
        return await pickImageFromGallery(); // Fallback to gallery
      default:
        return null;
    }
  }

  /// Pick and upload delivery proof
  Future<String?> pickAndUploadDeliveryProof(
    BuildContext context, {
    required String orderId,
    required String driverId,
    String? description,
  }) async {
    try {
      final imageFile = await pickImage(context);
      if (imageFile == null) return null;

      // Show upload progress
      if (context.mounted) {
        return await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _UploadProgressDialog(
            future: _uploadService.uploadDeliveryProof(
              orderId: orderId,
              driverId: driverId,
              imageFile: imageFile,
              description: description,
            ),
          ),
        );
      }

      return await _uploadService.uploadDeliveryProof(
        orderId: orderId,
        driverId: driverId,
        imageFile: imageFile,
        description: description,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error picking and uploading delivery proof: $e');
      }
      return null;
    }
  }

  /// Pick and upload profile photo
  Future<String?> pickAndUploadProfilePhoto(
    BuildContext context, {
    required String userId,
  }) async {
    try {
      final imageFile = await pickImage(context);
      if (imageFile == null) return null;

      if (context.mounted) {
        return await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _UploadProgressDialog(
            future: _uploadService.uploadProfilePhoto(
              userId: userId,
              imageFile: imageFile,
            ),
          ),
        );
      }

      return await _uploadService.uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error picking and uploading profile photo: $e');
      }
      return null;
    }
  }

  /// Pick and upload damage report
  Future<String?> pickAndUploadDamageReport(
    BuildContext context, {
    required String orderId,
    required String reporterId,
    required String damageType,
    String? description,
  }) async {
    try {
      final imageFile = await pickImage(context);
      if (imageFile == null) return null;

      if (context.mounted) {
        return await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _UploadProgressDialog(
            future: _uploadService.uploadDamageReport(
              orderId: orderId,
              reporterId: reporterId,
              imageFile: imageFile,
              damageType: damageType,
              description: description,
            ),
          ),
        );
      }

      return await _uploadService.uploadDamageReport(
        orderId: orderId,
        reporterId: reporterId,
        imageFile: imageFile,
        damageType: damageType,
        description: description,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error picking and uploading damage report: $e');
      }
      return null;
    }
  }

  /// Validate image size
  Future<bool> validateImageSize(dynamic imageFile, {int maxSizeMB = 10}) async {
    try {
      int sizeInBytes;
      
      if (kIsWeb && imageFile is Uint8List) {
        sizeInBytes = imageFile.length;
      } else if (imageFile is File) {
        sizeInBytes = await imageFile.length();
      } else {
        return false;
      }

      final maxSizeInBytes = maxSizeMB * 1024 * 1024;
      return sizeInBytes <= maxSizeInBytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating image size: $e');
      }
      return false;
    }
  }

  /// Get image dimensions (basic implementation)
  Future<Map<String, int>?> getImageDimensions(dynamic imageFile) async {
    try {
      // This would require additional image processing libraries
      // For now, return default dimensions
      return {'width': 1920, 'height': 1080};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image dimensions: $e');
      }
      return null;
    }
  }
}

/// Upload progress dialog
class _UploadProgressDialog extends StatelessWidget {
  final Future<String?> future;

  const _UploadProgressDialog({required this.future});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Uploading photo...'),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop(snapshot.data);
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo preview widget
class PhotoPreviewWidget extends StatelessWidget {
  final dynamic imageFile;
  final VoidCallback? onRemove;
  final double size;

  const PhotoPreviewWidget({
    super.key,
    required this.imageFile,
    this.onRemove,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (kIsWeb && imageFile is Uint8List) {
      return Image.memory(
        imageFile,
        fit: BoxFit.cover,
      );
    } else if (imageFile is File) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.image,
          color: Colors.grey,
        ),
      );
    }
  }
}
