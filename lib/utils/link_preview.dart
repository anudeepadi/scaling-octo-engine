import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:async';

/// A utility class to fetch and handle website link previews
class LinkPreview {
  final String url;
  String? title;
  String? description;
  String? imageUrl;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  LinkPreview({required this.url});

  /// Fetches metadata from a URL to generate a preview
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // Try to extract Open Graph metadata first, then fallback to standard meta tags
        title = _extractMetaContent(document, 'og:title') ?? 
                _extractMetaContent(document, 'title') ??
                document.querySelector('title')?.text;
                
        description = _extractMetaContent(document, 'og:description') ?? 
                      _extractMetaContent(document, 'description');
                      
        imageUrl = _extractMetaContent(document, 'og:image');
        
        // Limit length of title and description
        if (title != null && title!.length > 100) {
          title = '${title!.substring(0, 97)}...';
        }
        
        if (description != null && description!.length > 200) {
          description = '${description!.substring(0, 197)}...';
        }
        
        isLoading = false;
      } else {
        throw Exception('Failed to load URL. Status code: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      hasError = true;
      errorMessage = e.toString();
      print('Error fetching link preview: $e');
    }
  }
  
  /// Helper method to extract content from meta tags
  String? _extractMetaContent(var document, String property) {
    final metaTag = document.querySelector('meta[property="$property"]') ?? 
                   document.querySelector('meta[name="$property"]');
    return metaTag?.attributes['content'];
  }
  
  /// Returns a widget that displays a preview of the link
  Widget buildPreview({
    double maxHeight = 150,
    VoidCallback? onTap,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
  }) {
    if (isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (hasError) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Could not load preview for $url',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
