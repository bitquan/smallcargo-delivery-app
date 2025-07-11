import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload delivery proof photo
  Future<String?> uploadDeliveryProof({
    required String orderId,
    required String driverId,
    required dynamic imageFile, // File for mobile, Uint8List for web
    String? description,
  }) async {
    try {
      final fileName = 'delivery_proof_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('delivery_proofs').child(fileName);

      // Upload to Firebase Storage
      UploadTask uploadTask;
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile);
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Log upload for tracking
      if (kDebugMode) {
        print('Delivery proof uploaded: $downloadUrl');
        print('Order ID: $orderId, Driver ID: $driverId');
        if (description != null) print('Description: $description');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading delivery proof: $e');
      }
      return null;
    }
  }

  /// Upload customer profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required dynamic imageFile,
  }) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_photos').child(fileName);

      // Upload to Firebase Storage
      UploadTask uploadTask;
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile);
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Profile photo uploaded: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile photo: $e');
      }
      return null;
    }
  }

  /// Upload damage report photo
  Future<String?> uploadDamageReport({
    required String orderId,
    required String reporterId,
    required dynamic imageFile,
    required String damageType,
    String? description,
  }) async {
    try {
      final fileName = 'damage_report_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('damage_reports').child(fileName);

      UploadTask uploadTask;
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile);
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Damage report uploaded: $downloadUrl');
        print('Order ID: $orderId, Reporter ID: $reporterId');
        print('Damage Type: $damageType');
        if (description != null) print('Description: $description');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading damage report: $e');
      }
      return null;
    }
  }

  /// Upload vehicle documentation
  Future<String?> uploadVehicleDocument({
    required String driverId,
    required String documentType, // 'license', 'insurance', 'registration'
    required dynamic imageFile,
  }) async {
    try {
      final fileName = '${documentType}_${driverId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('vehicle_documents').child(fileName);

      UploadTask uploadTask;
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile);
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile);
      } else {
        throw Exception('Invalid image file type');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Vehicle document uploaded: $downloadUrl');
        print('Driver ID: $driverId, Document Type: $documentType');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading vehicle document: $e');
      }
      return null;
    }
  }

  /// Upload multiple photos for an order
  Future<List<String>> uploadMultiplePhotos({
    required String orderId,
    required String uploaderId,
    required List<dynamic> imageFiles,
    required String category, // 'pickup', 'delivery', 'damage', etc.
  }) async {
    final uploadedUrls = <String>[];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final fileName = '${category}_${orderId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(category).child(fileName);

        UploadTask uploadTask;
        if (kIsWeb && imageFiles[i] is Uint8List) {
          uploadTask = ref.putData(imageFiles[i]);
        } else if (imageFiles[i] is File) {
          uploadTask = ref.putFile(imageFiles[i]);
        } else {
          continue; // Skip invalid file types
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);

        if (kDebugMode) {
          print('Photo ${i + 1} uploaded: $downloadUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading photo ${i + 1}: $e');
        }
      }
    }

    return uploadedUrls;
  }

  /// Delete photo from storage
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      
      if (kDebugMode) {
        print('Photo deleted: $photoUrl');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting photo: $e');
      }
      return false;
    }
  }

  /// Get photo metadata
  Future<Map<String, dynamic>?> getPhotoMetadata(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'bucket': metadata.bucket,
        'fullPath': metadata.fullPath,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo metadata: $e');
      }
      return null;
    }
  }

  /// Validate image file
  bool validateImage(dynamic imageFile) {
    try {
      if (kIsWeb) {
        return imageFile is Uint8List && imageFile.isNotEmpty;
      } else {
        return imageFile is File && imageFile.existsSync();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating image: $e');
      }
      return false;
    }
  }

  /// Get upload progress stream
  Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
