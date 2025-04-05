import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class IosMediaPicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<FilePickerResult?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      
      return FilePickerResult([
        PlatformFile(
          path: image.path,
          name: path.basename(image.path),
          size: await image.length(),
          bytes: await image.readAsBytes(),
        )
      ]);
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<FilePickerResult?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return null;

      return FilePickerResult([
        PlatformFile(
          path: photo.path,
          name: path.basename(photo.path),
          size: await photo.length(),
          bytes: await photo.readAsBytes(),
        )
      ]);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  static Future<FilePickerResult?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video == null) return null;

      return FilePickerResult([
        PlatformFile(
          path: video.path,
          name: path.basename(video.path),
          size: await video.length(),
          bytes: await video.readAsBytes(),
        )
      ]);
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }
} 