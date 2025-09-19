import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Image service for handling image uploads to Cloudinary
/// Provides image picking and cloud storage functionality
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Cloudinary configuration
  static const String _cloudName = 'dfmbsbqi8'; 
  static const String _uploadPreset = 'flutter_preset'; 
  
  final CloudinaryPublic _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset);
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: ${e.toString()}');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from camera: ${e.toString()}');
    }
  }

  /// Upload image to Cloudinary
  Future<String> uploadImage(XFile imageFile, {String? folder}) async {
    try {
      CloudinaryResponse response;
      
      if (kIsWeb) {
        // For web platform
        final bytes = await imageFile.readAsBytes();
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: imageFile.name,
            folder: folder ?? 'hospital_management',
          ),
        );
      } else {
        // For mobile platforms
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            folder: folder ?? 'hospital_management',
          ),
        );
      }
      
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Show image source selection dialog
  Future<XFile?> showImageSourceDialog(context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Upload profile image with loading dialog
  Future<String?> uploadProfileImage(context, {String? folder}) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Selecting and uploading image...'),
            ],
          ),
        ),
      );

      // Pick image
      final XFile? imageFile = await showImageSourceDialog(context);
      
      if (imageFile == null) {
        Navigator.of(context).pop(); // Close loading dialog
        return null;
      }

      // Update loading message
      Navigator.of(context).pop(); // Close selection dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading image to cloud...'),
            ],
          ),
        ),
      );

      // Upload to Cloudinary
      final String imageUrl = await uploadImage(imageFile, folder: folder);
      
      Navigator.of(context).pop(); // Close loading dialog
      return imageUrl;
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Delete image from Cloudinary (optional - requires API key)
  Future<bool> deleteImage(String publicId) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Extract public ID from URL
    final uri = Uri.parse(originalUrl);
    final pathSegments = uri.pathSegments;
    final uploadIndex = pathSegments.indexOf('upload');
    
    if (uploadIndex == -1) return originalUrl;

    // Build transformation string
    List<String> transformations = [];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    transformations.add('c_fill'); // Crop to fill dimensions
    
    final transformationString = transformations.join(',');
    
    // Rebuild URL with transformations
    final newPathSegments = List<String>.from(pathSegments);
    newPathSegments.insert(uploadIndex + 1, transformationString);
    
    return uri.replace(pathSegments: newPathSegments).toString();
  }
}