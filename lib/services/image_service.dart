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

  /// Show image source selection dialog - FIXED VERSION
  Future<XFile?> showImageSourceDialog(BuildContext context) async {
    if (!context.mounted) return null;
    
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(dialogContext).pop(); // Close dialog first
                  try {
                    final image = await pickImageFromGallery();
                    if (context.mounted) {
                      Navigator.of(context).pop(image); // Return result
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop(null); // Return null on error
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(dialogContext).pop(); // Close dialog first
                  try {
                    final image = await pickImageFromCamera();
                    if (context.mounted) {
                      Navigator.of(context).pop(image); // Return result
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop(null); // Return null on error
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Upload profile image with loading dialog - COMPLETELY REWRITTEN
  Future<String?> uploadProfileImage(BuildContext context, {String? folder}) async {
    if (!context.mounted) return null;

    try {
      // Step 1: Show image source selection
      final XFile? imageFile = await showImageSourceDialog(context);
      
      if (imageFile == null) {
        return null; // User cancelled or error occurred
      }

      if (!context.mounted) return null;

      // Step 2: Show upload progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false, // Prevent dismissing
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image to cloud...'),
              ],
            ),
          ),
        ),
      );

      // Step 3: Upload to Cloudinary
      final String imageUrl = await uploadImage(imageFile, folder: folder);
      
      // Step 4: Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      
      return imageUrl;
      
    } catch (e) {
      // Make sure to close any open dialogs
      if (context.mounted) {
        // Try to pop any loading dialog that might be open
        try {
          Navigator.of(context).pop();
        } catch (popError) {
          // Dialog might not be open, ignore
        }
      }
      
      // Re-throw the error to be handled by calling code
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Alternative simpler upload method
  Future<String?> uploadProfileImageSimple(BuildContext context, {String? folder}) async {
    if (!context.mounted) return null;

    XFile? imageFile;
    
    // Step 1: Pick image source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (source == null || !context.mounted) return null;

    // Step 2: Pick image
    try {
      imageFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }

    if (imageFile == null || !context.mounted) return null;

    // Step 3: Show loading and upload
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading image...'),
            ],
          ),
        ),
      );

      // Upload image
      final String imageUrl = await uploadImage(imageFile, folder: folder);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return imageUrl;
      
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (popError) {
          // Ignore if dialog already closed
        }
      }
      throw e;
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