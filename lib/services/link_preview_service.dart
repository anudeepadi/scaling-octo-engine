import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/link_preview.dart';

class LinkPreviewService {
  static const Duration _timeout = Duration(seconds: 5);
  static final Map<String, LinkPreview> _cache = {};

  static Future<LinkPreview?> fetchLinkPreview(String url) async {
    try {
      if (_cache.containsKey(url)) {
        return _cache[url];
      }

      final uri = Uri.parse(url);

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9',
        'Accept-Language': 'en-US,en;q=0.5',
      };

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode != 200) {
        return _createBasicPreview(url);
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.contains('text/html')) {
        return _createBasicPreview(url);
      }

      final document = html_parser.parse(response.body);

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

      _cache[url] = linkPreview;

      return linkPreview;
    } catch (e) {
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
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null && ogTitle.attributes['content']?.isNotEmpty == true) {
      return ogTitle.attributes['content']!;
    }

    final twitterTitle = document.querySelector('meta[name="twitter:title"]');
    if (twitterTitle != null &&
        twitterTitle.attributes['content']?.isNotEmpty == true) {
      return twitterTitle.attributes['content']!;
    }

    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.trim().isNotEmpty) {
      return titleElement.text.trim();
    }

    try {
      return Uri.parse(url).host;
    } catch (e) {
      return 'Link Preview';
    }
  }

  static String _extractDescription(dynamic document) {
    final ogDescription =
        document.querySelector('meta[property="og:description"]');
    if (ogDescription != null &&
        ogDescription.attributes['content']?.isNotEmpty == true) {
      return ogDescription.attributes['content']!;
    }

    final twitterDescription =
        document.querySelector('meta[name="twitter:description"]');
    if (twitterDescription != null &&
        twitterDescription.attributes['content']?.isNotEmpty == true) {
      return twitterDescription.attributes['content']!;
    }

    final metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription != null &&
        metaDescription.attributes['content']?.isNotEmpty == true) {
      return metaDescription.attributes['content']!;
    }

    final firstParagraph = document.querySelector('p');
    if (firstParagraph != null && firstParagraph.text.trim().isNotEmpty) {
      final text = firstParagraph.text.trim();
      return text.length > 150 ? '${text.substring(0, 150)}...' : text;
    }

    return '';
  }

  static String? _extractImage(dynamic document, String url) {
    final ogImage = document.querySelector('meta[property="og:image"]');
    if (ogImage != null && ogImage.attributes['content']?.isNotEmpty == true) {
      return _resolveImageUrl(ogImage.attributes['content']!, url);
    }

    final twitterImage = document.querySelector('meta[name="twitter:image"]');
    if (twitterImage != null &&
        twitterImage.attributes['content']?.isNotEmpty == true) {
      return _resolveImageUrl(twitterImage.attributes['content']!, url);
    }

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
    final ogSiteName = document.querySelector('meta[property="og:site_name"]');
    if (ogSiteName != null &&
        ogSiteName.attributes['content']?.isNotEmpty == true) {
      return ogSiteName.attributes['content']!;
    }

    final twitterSite = document.querySelector('meta[name="twitter:site"]');
    if (twitterSite != null &&
        twitterSite.attributes['content']?.isNotEmpty == true) {
      String site = twitterSite.attributes['content']!;
      if (site.startsWith('@')) site = site.substring(1);
      return site;
    }

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
        return imageUrl;
      } else if (imageUrl.startsWith('//')) {
        return '${pageUri.scheme}:$imageUrl';
      } else if (imageUrl.startsWith('/')) {
        return '${pageUri.scheme}://${pageUri.host}$imageUrl';
      } else {
        final basePath =
            pageUri.path.endsWith('/') ? pageUri.path : '${pageUri.path}/';
        return '${pageUri.scheme}://${pageUri.host}$basePath$imageUrl';
      }
    } catch (e) {
      return null;
    }
  }

  static bool _isReasonableImage(String imageUrl) {
    final url = imageUrl.toLowerCase();

    if (!url.contains('.jpg') &&
        !url.contains('.jpeg') &&
        !url.contains('.png') &&
        !url.contains('.webp') &&
        !url.contains('.gif')) {
      return false;
    }

    if (url.contains('icon') ||
        url.contains('logo') ||
        url.contains('favicon') ||
        url.contains('avatar')) {
      return false;
    }

    return true;
  }

  static void clearCache() {
    _cache.clear();
  }

  static int getCacheSize() {
    return _cache.length;
  }
}
