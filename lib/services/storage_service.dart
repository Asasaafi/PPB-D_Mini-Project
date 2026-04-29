import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _picker = ImagePicker();

  Future<Uint8List?> pickBytesFromCamera() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      return xfile != null ? await xfile.readAsBytes() : null;
    } catch (e) {
      debugPrint('Camera not available: $e');
      return null;
    }
  }

  Future<Uint8List?> pickBytesFromGallery() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
      );
      return xfile != null ? await xfile.readAsBytes() : null;
    } catch (e) {
      debugPrint('Gallery not available: $e');
      return null;
    }
  }

  Future<String> uploadFoodImageBytes(Uint8List bytes, {String? foodId}) async {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}