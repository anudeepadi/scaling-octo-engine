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

  // Get GIFs from assets/images folder
  static Future<List<String>> getLocalGifs() async {
    try {
      // Try to load the list of assets from the manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      
      if (manifestContent.isEmpty) {
        print('Asset manifest is empty, using default GIFs');
        return _defaultGifs;
      }
      
      try {
        // Parse the JSON manifest correctly
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        
        // Filter for GIFs in the images directory
        final gifPaths = manifestMap.keys
            .where((String key) => key.startsWith('assets/images/') && key.endsWith('.gif'))
            .toList();
        
        // If no GIFs found, return default list
        if (gifPaths.isEmpty) {
          print('No GIFs found in manifest, using default GIFs');
          return _defaultGifs;
        }
        
        print('Found ${gifPaths.length} GIFs: $gifPaths');
        return gifPaths;
      } catch (e) {
        print('Error parsing manifest: $e');
        return _defaultGifs;
      }
    } catch (e) {
      print('Error loading GIFs from manifest: $e');
      return _defaultGifs;
    }
  }
}
