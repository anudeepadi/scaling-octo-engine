import '../models/chat_message.dart';
import '../models/link_preview.dart';

class MessageUtils {
  // Extract a URL from a message
  static String? extractUrl(String message) {
    final RegExp urlRegExp = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    
    final match = urlRegExp.firstMatch(message);
    if (match != null) {
      return match.group(0);
    }
    
    return null;
  }
  
  // Extract a YouTube video ID from a URL
  static String? extractYoutubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    
    final match = regExp.firstMatch(url);
    return match?.group(7);
  }
  
  // Determine the type of message based on its content
  static MessageType determineMessageType(String content) {
    // Extract URL from content if present
    final url = extractUrl(content);
    if (url == null) {
      return MessageType.text;
    }
    
    // Check if it's a YouTube link
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return MessageType.youtube;
    }
    
    // Check if it's a GIF
    if (url.toLowerCase().endsWith('.gif')) {
      return MessageType.gif;
    }
    
    // Check if it's an image
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'];
    for (final ext in imageExtensions) {
      if (url.toLowerCase().endsWith(ext)) {
        return MessageType.image;
      }
    }
    
    // Check if it's a video
    final videoExtensions = ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.mkv'];
    for (final ext in videoExtensions) {
      if (url.toLowerCase().endsWith(ext)) {
        return MessageType.video;
      }
    }
    
    // If none of the above, it's a link preview
    return MessageType.linkPreview;
  }
  
  // Separate text and media URL from message
  static Map<String, String> separateTextAndMedia(String content) {
    final url = extractUrl(content);
    if (url == null) {
      return {'text': content, 'media': ''};
    }
    
    final textPart = content.replaceAll(url, '').trim();
    return {'text': textPart, 'media': url};
  }
  
  // Create a basic LinkPreview from a URL
  static LinkPreview createBasicLinkPreview(String url) {
    final Uri uri = Uri.parse(url);
    final String host = uri.host;
    
    // Try to create a more meaningful title
    String title = host;
    if (host.startsWith('www.')) {
      title = host.substring(4);
    }
    
    // Capitalize first letter
    title = title.split('.').first;
    title = title[0].toUpperCase() + title.substring(1);
    
    return LinkPreview(
      url: url,
      title: 'Link to $title',
      description: 'Visit this link for more information.',
    );
  }
  
  // Check if message contains an external link (not a local file)
  static bool containsExternalLink(String content) {
    final url = extractUrl(content);
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }
}
