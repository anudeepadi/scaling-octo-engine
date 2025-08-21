import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/link_preview.dart';
import '../utils/debug_config.dart';

class LinkPreviewService {
  static const Duration _timeout = Duration(seconds: 5);
  
  static final Map<String, LinkPreview> _cache = {};
  
  static Future<LinkPreview?> fetchLinkPreview(String url) async {
    try {
      // Check cache first
      if (_cache.containsKey(url)) {
        DebugConfig.debugPrint('LinkPreviewService: Using cached preview for $url');
        return _cache[url];
      }
      
      DebugConfig.debugPrint('LinkPreviewService: Fetching preview for $url');
      
      final uri = Uri.parse(url);
      
      // Add headers to avoid being blocked
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      };
      
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      
      DebugConfig.debugPrint('LinkPreviewService: Response status ${response.statusCode} for $url');
      DebugConfig.debugPrint('LinkPreviewService: Content-Type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        DebugConfig.debugPrint('LinkPreviewService: HTTP ${response.statusCode} for $url');
        // Create a basic preview even if we can't fetch the page
        return _createBasicPreview(url);
      }
      
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.contains('text/html')) {
        DebugConfig.debugPrint('LinkPreviewService: Not HTML content for $url - $contentType');
        // Create a basic preview for non-HTML content
        return _createBasicPreview(url);
      }
      
      final document = html_parser.parse(response.body);
      
      // Extract Open Graph tags or fallback to standard HTML tags
      String title = _extractTitle(document, url);
      String description = _extractDescription(document);
      String? imageUrl = _extractImage(document, url);
      String? siteName = _extractSiteName(document, url);
      
      final linkPreview = LinkPreview(
        url: url,
        title: title,
        description: description,
        imageUrl: imageUrl,
        siteName: siteName,
      );
      
      // Cache the result
      _cache[url] = linkPreview;
      
      DebugConfig.debugPrint('LinkPreviewService: Successfully fetched preview for $url');
      return linkPreview;
      
    } catch (e) {
      DebugConfig.debugPrint('LinkPreviewService: Error fetching preview for $url: $e');
      // Return a basic preview even on error
      return _createBasicPreview(url);
    }
  }
  
  static LinkPreview _createBasicPreview(String url) {
    try {
      final uri = Uri.parse(url);
      return LinkPreview(
        url: url,
        title: uri.host,
        description: 'Tap to open link',
        imageUrl: null,
        siteName: uri.host,
      );
    } catch (e) {
      return LinkPreview(
        url: url,
        title: 'Link Preview',
        description: 'Tap to open link',
        imageUrl: null,
        siteName: null,
      );
    }
  }
  
  static String _extractTitle(dynamic document, String url) {
    // Try Open Graph title first
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null && ogTitle.attributes['content']?.isNotEmpty == true) {
      return ogTitle.attributes['content']!;
    }
    
    // Try Twitter title
    final twitterTitle = document.querySelector('meta[name="twitter:title"]');
    if (twitterTitle != null && twitterTitle.attributes['content']?.isNotEmpty == true) {
      return twitterTitle.attributes['content']!;
    }
    
    // Try standard title tag
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.trim().isNotEmpty) {
      return titleElement.text.trim();
    }
    
    // Fallback to URL host
    try {
      return Uri.parse(url).host;
    } catch (e) {
      return 'Link Preview';
    }
  }
  
  static String _extractDescription(dynamic document) {
    // Try Open Graph description first
    final ogDescription = document.querySelector('meta[property="og:description"]');
    if (ogDescription != null && ogDescription.attributes['content']?.isNotEmpty == true) {
      return ogDescription.attributes['content']!;
    }
    
    // Try Twitter description
    final twitterDescription = document.querySelector('meta[name="twitter:description"]');
    if (twitterDescription != null && twitterDescription.attributes['content']?.isNotEmpty == true) {
      return twitterDescription.attributes['content']!;
    }
    
    // Try standard meta description
    final metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription != null && metaDescription.attributes['content']?.isNotEmpty == true) {
      return metaDescription.attributes['content']!;
    }
    
    // Try to get first paragraph text
    final firstParagraph = document.querySelector('p');
    if (firstParagraph != null && firstParagraph.text.trim().isNotEmpty) {
      final text = firstParagraph.text.trim();
      return text.length > 150 ? '${text.substring(0, 150)}...' : text;
    }
    
    return '';
  }
  
  static String? _extractImage(dynamic document, String url) {
    // Try Open Graph image first
    final ogImage = document.querySelector('meta[property="og:image"]');
    if (ogImage != null && ogImage.attributes['content']?.isNotEmpty == true) {
      return _resolveImageUrl(ogImage.attributes['content']!, url);
    }
    
    // Try Twitter image
    final twitterImage = document.querySelector('meta[name="twitter:image"]');
    if (twitterImage != null && twitterImage.attributes['content']?.isNotEmpty == true) {
      return _resolveImageUrl(twitterImage.attributes['content']!, url);
    }
    
    // Try to find first reasonable image in the page
    final images = document.querySelectorAll('img');
    for (final img in images) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final resolvedUrl = _resolveImageUrl(src, url);
        if (resolvedUrl != null && _isReasonableImage(resolvedUrl)) {
          return resolvedUrl;
        }
      }
    }
    
    return null;
  }
  
  static String? _extractSiteName(dynamic document, String url) {
    // Try Open Graph site name first
    final ogSiteName = document.querySelector('meta[property="og:site_name"]');
    if (ogSiteName != null && ogSiteName.attributes['content']?.isNotEmpty == true) {
      return ogSiteName.attributes['content']!;
    }
    
    // Try Twitter site
    final twitterSite = document.querySelector('meta[name="twitter:site"]');
    if (twitterSite != null && twitterSite.attributes['content']?.isNotEmpty == true) {
      String site = twitterSite.attributes['content']!;
      // Remove @ symbol if present
      if (site.startsWith('@')) site = site.substring(1);
      return site;
    }
    
    // Fallback to domain name
    try {
      return Uri.parse(url).host;
    } catch (e) {
      return null;
    }
  }
  
  static String? _resolveImageUrl(String imageUrl, String pageUrl) {
    try {
      final pageUri = Uri.parse(pageUrl);
      final imageUri = Uri.parse(imageUrl);
      
      if (imageUri.hasAbsolutePath && imageUri.hasScheme) {
        // Already absolute URL
        return imageUrl;
      } else if (imageUrl.startsWith('//')) {
        // Protocol-relative URL
        return '${pageUri.scheme}:$imageUrl';
      } else if (imageUrl.startsWith('/')) {
        // Root-relative URL
        return '${pageUri.scheme}://${pageUri.host}$imageUrl';
      } else {
        // Relative URL
        final basePath = pageUri.path.endsWith('/') ? pageUri.path : '${pageUri.path}/';
        return '${pageUri.scheme}://${pageUri.host}$basePath$imageUrl';
      }
    } catch (e) {
      DebugConfig.debugPrint('LinkPreviewService: Error resolving image URL $imageUrl: $e');
      return null;
    }
  }
  
  static bool _isReasonableImage(String imageUrl) {
    final url = imageUrl.toLowerCase();
    
    // Check for common image extensions
    if (!url.contains('.jpg') && !url.contains('.jpeg') && 
        !url.contains('.png') && !url.contains('.webp') && 
        !url.contains('.gif')) {
      return false;
    }
    
    // Exclude common icons and small images
    if (url.contains('icon') || url.contains('logo') || 
        url.contains('favicon') || url.contains('avatar')) {
      return false;
    }
    
    return true;
  }
  
  static void clearCache() {
    _cache.clear();
    DebugConfig.debugPrint('LinkPreviewService: Cache cleared');
  }
  
  static int getCacheSize() {
    return _cache.length;
  }
}