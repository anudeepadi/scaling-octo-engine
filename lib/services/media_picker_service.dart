import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'platform/ios_media_picker.dart';

enum MediaSource {
  gallery,
  camera
}

class MediaPickerService {
  static Future<FilePickerResult?> pickMedia({
    List<String>? allowedExtensions,
    MediaSource source = MediaSource.gallery,
  }) async {
    // Use platform-specific pickers for iOS
    if (!kIsWeb && Platform.isIOS) {
      if (source == MediaSource.camera) {
        // If media type contains video extensions, use video recording
        if (allowedExtensions?.contains('mp4') ?? false) {
          return await IosMediaPicker.recordVideo();
        } else {
          return await IosMediaPicker.takePhoto();
        }
      } else {
        // Check if user wants to pick images or videos
        if (allowedExtensions?.contains('mp4') ?? false) {
          // Show action sheet to choose between image and video
          // For simplicity, we'll just go with image gallery here
          return await IosMediaPicker.pickImageFromGallery();
        } else {
          return await IosMediaPicker.pickImageFromGallery();
        }
      }
    } else {
      // Default implementation for Android and other platforms
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'gif', 'mp4'],
        allowMultiple: false,
      );
    }
  }

  static bool isVideoFile(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType?.startsWith('video/') ?? false;
  }

  static bool isImageFile(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType?.startsWith('image/') ?? false;
  }

  static bool isGifFile(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType == 'image/gif';
  }

  static bool isAudioFile(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType?.startsWith('audio/') ?? false;
  }

  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
}