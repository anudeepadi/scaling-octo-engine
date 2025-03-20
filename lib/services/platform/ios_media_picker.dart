
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class IosMediaPicker {
  /// Pick an image from the gallery using iOS file picker
  static Future<FilePickerResult?> pickImageFromGallery() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take a photo using iOS file picker (fallback to gallery since we can't use camera directly)
  static Future<FilePickerResult?> takePhoto() async {
    // Without image_picker we can't access camera directly
    // Fall back to gallery picking
    print('Camera picking not available, falling back to gallery');
    return pickImageFromGallery();
  }

  /// Record a video using iOS file picker (fallback to gallery)
  static Future<FilePickerResult?> recordVideo() async {
    // Without image_picker we can't record video directly
    // Fall back to gallery picking
    print('Video recording not available, falling back to gallery');
    return pickVideoFromGallery();
  }

  /// Pick a video from the gallery using iOS file picker
  static Future<FilePickerResult?> pickVideoFromGallery() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }
}
