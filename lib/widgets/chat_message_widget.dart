import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../utils/debug_config.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onReplyTap;
  final Function(String)? onReactionAdd;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onReplyTap,
    this.onReactionAdd,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  // Helper function to extract YouTube video ID
  String? _getYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
    }
    return null;
  }

  // Helper function to check if a URL points to a known image/gif type
  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');
  }

  // Helper function to check if content is a local asset path
  bool _isLocalAssetGif(String content) {
    final trimmedContent = content.trim();
    return trimmedContent.startsWith('assets/') &&
        trimmedContent.toLowerCase().endsWith('.gif');
  }

  // Helper to launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      DebugConfig.debugPrint('Could not launch $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Widget _buildContent() {
    // Handle video messages first
    if (widget.message.type == MessageType.video) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Video thumbnail background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.withValues(alpha: 0.7),
                    Colors.red.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            // Doctor's image placeholder
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Doctor's name and title
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Play button
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 50,
              ),
            ),
          ],
        ),
      );
    }

    // --- Check for Local Asset GIF First ---
    if (_isLocalAssetGif(widget.message.content)) {
      try {
        return Image.asset(
          widget.message.content.trim(),
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            DebugConfig.debugPrint(
                "Image.asset Error loading ${widget.message.content}: $error");
            return Container(
                height: 150,
                color: Colors.grey[300],
                child:
                    const Center(child: Icon(Icons.error, color: Colors.red)));
          },
        );
      } catch (e) {
        DebugConfig.debugPrint(
            "Error loading asset ${widget.message.content}: $e");
        return Text("[Error loading asset: ${widget.message.content}]",
            style: const TextStyle(color: Colors.red));
      }
    }

    // --- Network URL Processing ---
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(widget.message.content);
    String? firstUrl = match?.group(0);

    // Try to get videoId ONLY from the found URL
    String? videoId = (firstUrl != null) ? _getYoutubeVideoId(firstUrl) : null;

    if (videoId != null && firstUrl != null && match != null) {
      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
      // Build the content with text before/after thumbnail
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display text before the URL if any
          if (match.start > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.message.content.substring(0, match.start).trimRight(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          // Always display the YouTube URL above the thumbnail
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: widget.message.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color:
                        widget.message.isMe ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      firstUrl,
                      style: TextStyle(
                        color: widget.message.isMe
                            ? Colors.white70
                            : Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Display the tappable thumbnail
          GestureDetector(
            onTap: () => _launchURL(firstUrl),
            child: Stack(
              children: [
                Image.network(
                  thumbnailUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    DebugConfig.debugPrint(
                        "Error loading $thumbnailUrl: $error");
                    return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error),
                            SizedBox(height: 4),
                            Text('Tap to open link',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ));
                  },
                ),
                // YouTube play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display text after the URL if any
          if (match.end < widget.message.content.length)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.message.content.substring(match.end).trimLeft(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      );
    } else if (firstUrl != null && _isImageUrl(firstUrl) && match != null) {
      // It's an image/GIF URL
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display text before the URL if any
          if (match.start > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.message.content.substring(0, match.start).trimRight(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          // Display the tappable image
          GestureDetector(
            onTap: () => _launchURL(firstUrl),
            child: Image.network(
              firstUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                DebugConfig.debugPrint("Error loading $firstUrl: $error");
                return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error),
                        SizedBox(height: 4),
                        Text('Tap to open link',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ));
              },
            ),
          ),
          // Display text after the URL if any
          if (match.end < widget.message.content.length)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.message.content.substring(match.end).trimLeft(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      );
    } else if (firstUrl != null &&
        match != null &&
        widget.message.linkPreview != null) {
      // Web page preview with thumbnail
      final linkPreview = widget.message.linkPreview!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display text before the URL if any
          if (match.start > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                widget.message.content.substring(0, match.start).trimRight(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          // Web page preview card with improved layout
          GestureDetector(
            onTap: () => _launchURL(firstUrl),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minWidth: 200,
                maxWidth: double.infinity,
              ),
              decoration: BoxDecoration(
                color: widget.message.isMe
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.message.isMe
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.borderLight,
                  width: 1,
                ),
                boxShadow: widget.message.isMe
                    ? []
                    : [
                        BoxShadow(
                          color: AppTheme.shadowSubtle,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail image - hide entirely if it fails to load
                  if (linkPreview.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: _LinkPreviewImage(
                        imageUrl: linkPreview.imageUrl!,
                      ),
                    ),
                  // Content section with improved padding
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with improved wrapping
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            linkPreview.title,
                            style: TextStyle(
                              color: widget.message.isMe
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3, // Better line height for readability
                            ),
                            maxLines: 3, // Allow more lines for longer titles
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Description with improved wrapping
                        if (linkPreview.description.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              linkPreview.description,
                              style: TextStyle(
                                color: widget.message.isMe
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4, // Better line height
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 3, // Allow more lines for descriptions
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // URL with icon - improved layout
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.link_rounded,
                                  size: 14,
                                  color: widget.message.isMe
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Site name (if available)
                                    if (linkPreview.siteName != null &&
                                        linkPreview.siteName!.isNotEmpty)
                                      Text(
                                        linkPreview.siteName!,
                                        style: TextStyle(
                                          color: widget.message.isMe
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    // URL hostname with better wrapping
                                    Text(
                                      Uri.parse(firstUrl).host,
                                      style: TextStyle(
                                        color: widget.message.isMe
                                            ? Colors.white
                                                .withValues(alpha: 0.7)
                                            : AppTheme.textTertiary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        height: 1.2,
                                      ),
                                      maxLines:
                                          2, // Allow URL to wrap to 2 lines if needed
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Display text after the URL if any
          if (match.end < widget.message.content.length)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.message.content.substring(match.end).trimLeft(),
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      );
    } else {
      // Default text with linkify
      return Linkify(
        onOpen: (link) => _launchURL(link.url),
        text: widget.message.content,
        style: TextStyle(
          color: widget.message.isMe ? Colors.white : Colors.black,
        ),
        linkStyle: TextStyle(
          color: widget.message.isMe ? Colors.white : AppTheme.quitxtPurple,
          decoration: TextDecoration.underline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Quick reply buttons are now handled by the screen's ListView logic
    // ChatMessageWidget only renders the message content bubble

    return Padding(
      padding: EdgeInsets.only(
        left: widget.message.isMe ? 60 : 0,
        right: widget.message.isMe ? 0 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: widget.message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isMe) _buildAvatar(),
          if (!widget.message.isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: widget.message.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildModernMessageBubble(),
                  const SizedBox(height: 2),
                  _buildMessageInfo(),
                ],
              ),
            ),
          ),
          if (widget.message.isMe) const SizedBox(width: 8),
          if (widget.message.isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.message.isMe) {
      // User avatar - keep as icon for now
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 16,
        ),
      );
    } else {
      // Quitxt bot avatar - use the logo
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.wellnessGreen.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/logos/avatar high rez.jpg',
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  Widget _buildModernMessageBubble() {
    return GestureDetector(
      onTap: widget.onReplyTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: widget.message.isMe
              ? LinearGradient(
                  colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.message.isMe ? null : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(widget.message.isMe ? 20 : 4),
            bottomRight: Radius.circular(widget.message.isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.message.isMe
                  ? AppTheme.quitxtTeal.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(widget.message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (widget.message.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 12,
              color: _getStatusColor(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    // Format as 12-hour time (e.g., "2:30 PM")
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
      case MessageStatus.error:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey[600]!;
      case MessageStatus.delivered:
        return AppTheme.quitxtTeal;
      case MessageStatus.read:
        return AppTheme.quitxtTeal;
      case MessageStatus.failed:
      case MessageStatus.error:
        return Colors.red;
    }
  }
}

// Helper widget to handle link preview images that can fail to load
class _LinkPreviewImage extends StatefulWidget {
  final String imageUrl;

  const _LinkPreviewImage({
    required this.imageUrl,
  });

  @override
  State<_LinkPreviewImage> createState() => _LinkPreviewImageState();
}

class _LinkPreviewImageState extends State<_LinkPreviewImage> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    // If image failed to load, don't show anything (return empty container)
    if (_imageLoadFailed) {
      return const SizedBox.shrink();
    }

    return Image.network(
      widget.imageUrl,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 120,
          width: double.infinity,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        DebugConfig.debugPrint(
            "Link preview image failed to load: ${widget.imageUrl}, error: $error");
        // Mark as failed and trigger rebuild to hide the image
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _imageLoadFailed = true;
            });
          }
        });
        // Return empty container immediately
        return const SizedBox.shrink();
      },
    );
  }
}
