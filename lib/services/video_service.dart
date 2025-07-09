import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/debug_config.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  Future<Map<String, dynamic>?> getVideoInfo(String url) async {
    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final videoId = _extractVideoId(url);
        if (videoId != null) {
          final response = await http.get(
            Uri.parse('http://localhost:8000/video-info/$videoId'),
          );

          if (response.statusCode == 200) {
            return json.decode(response.body);
          }
        }
      }
      return null;
    } catch (e) {
      DebugConfig.debugPrint('Error getting video info: $e');
      return null;
    }
  }

  String? _extractVideoId(String url) {
    try {
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/')[1].split('?')[0];
      } else if (url.contains('youtube.com/watch')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      }
      return null;
    } catch (e) {
      DebugConfig.debugPrint('Error extracting video ID: $e');
      return null;
    }
  }

  String? getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}