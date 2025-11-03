import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class GifService {
  static final List<String> _defaultGifs = [
    'assets/images/AirbendingPrank.gif',
    'assets/images/butt.gif',
    'assets/images/dont_touch.gif',
    'assets/images/dork.gif',
    'assets/images/dorky-selfies.gif',
    'assets/images/fanny-of-darkness.gif',
    'assets/images/ill-fart.gif',
    'assets/images/mean-trick.gif',
  ];

  static Future<List<String>> getLocalGifs() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');

      if (manifestContent.isEmpty) {
        return _defaultGifs;
      }

      try {
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);

        final gifPaths = manifestMap.keys
            .where((String key) =>
                key.startsWith('assets/images/') && key.endsWith('.gif'))
            .toList();

        if (gifPaths.isEmpty) {
          return _defaultGifs;
        }

        return gifPaths;
      } catch (e) {
        return _defaultGifs;
      }
    } catch (e) {
      return _defaultGifs;
    }
  }
}
