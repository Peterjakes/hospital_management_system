import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Image service for handling image uploads to Cloudinary
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  static const String _cloudName = 'your-cloud-name';
  static const String _uploadPreset = 'your-upload-preset';
  final CloudinaryPublic _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset);
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Upload image to Cloudinary
  Future<String> uploadImage(XFile file, {String? folder}) async {
    try {
      final response = kIsWeb
          ? await _cloudinary.uploadFile(
              CloudinaryFile.fromBytesData(
                await file.readAsBytes(),
                identifier: file.name,
                folder: folder ?? 'hospital_management',
              ),
            )
          : await _cloudinary.uploadFile(
              CloudinaryFile.fromFile(file.path, folder: folder ?? 'hospital_management'),
            );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }
}
