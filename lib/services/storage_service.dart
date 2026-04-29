import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Opens the camera and returns a [File], or null if cancelled.
  /// Di emulator: set AVD Camera → Webcam0 di AVD Manager agar bisa pakai webcam laptop.
  Future<File?> pickFromCamera() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      return xfile != null ? File(xfile.path) : null;
    } catch (e) {
      debugPrint('Camera not available: $e');
      return null;
    }
  }

  /// Opens the gallery and returns a [File], or null if cancelled.
  /// Di emulator: drag & drop foto ke jendela emulator dulu supaya masuk galeri.
  Future<File?> pickFromGallery() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
      );
      return xfile != null ? File(xfile.path) : null;
    } catch (e) {
      debugPrint('Gallery not available: $e');
      return null;
    }
  }

  /// Uploads [file] to Firebase Storage under the current user's folder.
  /// Returns the public download URL.
  Future<String> uploadFoodImage(File file, {String? foodId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final name = foodId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref('food_images/$uid/$name.jpg');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return task.ref.getDownloadURL();
  }

  /// Deletes the image at [imageUrl] from Firebase Storage.
  /// Silently ignores errors (e.g. file not found).
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {}
  }
}