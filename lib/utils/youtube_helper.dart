import 'package:flutter/material.dart';

class YouTubeHelper {
  static String? getVideoId(String url) {
    if (url.contains('youtube.com')) {
      final uri = Uri.parse(url);
      return uri.queryParameters['v'];
    } else if (url.contains('youtu.be')) {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    }
    return null;
  }

  static bool isValidYouTubeUrl(String url) {
    return url.contains('youtube.com/watch?v=') || url.contains('youtu.be/');
  }

  static String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }
  
  static String getWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}