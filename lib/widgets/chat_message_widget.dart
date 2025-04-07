import 'package:flutter/material.dart';
import 'dart:io' show Platform, File;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import 'video_player_widget.dart';
import 'youtube_player_widget.dart';
import 'platform/ios_chat_message_widget.dart';
import 'quick_reply_widget.dart';
import 'improved_message_item.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onReplyTap;
  final Function(String)? onReactionAdd;
  final Function(String)? onQuickReplyTap;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.onReplyTap,
    this.onReactionAdd,
    this.onQuickReplyTap,
  }) : super(key: key);

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

  // Helper to launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
      // Optionally show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Widget _buildContent() {
    // <<< Add Logging Here >>>
    print("ChatMessageWidget (${widget.message.id}): Building content. isMe=${widget.message.isMe}");
    print("ChatMessageWidget (${widget.message.id}): Raw content = '${widget.message.content}'");

    // Regex to find the first http/https URL in the string
    // This regex is simple and might catch false positives, but good for common URLs
    final urlRegex = RegExp(
      r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(widget.message.content);
    String? firstUrl = match?.group(0);
    print("ChatMessageWidget (${widget.message.id}): Found URL = $firstUrl");

    // Try to get videoId ONLY from the found URL
    String? videoId = (firstUrl != null) ? _getYoutubeVideoId(firstUrl) : null;
    print("ChatMessageWidget (${widget.message.id}): Extracted videoId = $videoId");

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
                  color: widget.message.isMe
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          // Display the tappable thumbnail
          GestureDetector(
            onTap: () => _launchURL(firstUrl), // Launch the found URL
            child: Image.network(
              thumbnailUrl,
              height: 150, // Maintain approximate size
              width: double.infinity,
              fit: BoxFit.cover,
              // Basic placeholder/error handling for Image.network
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child; // Image loaded
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
                print("Image.network Error loading $thumbnailUrl: $error"); // Add error logging
                return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error),
                        SizedBox(height: 4),
                        Text('Tap to open link', style: TextStyle(fontSize: 12)),
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
                  color: widget.message.isMe
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
        ],
      );
    } else {
      // Default: Use Linkify for the whole message if no YouTube link found or error
      return Linkify(
        onOpen: (link) => _launchURL(link.url),
        text: widget.message.content,
        style: TextStyle(
          color: widget.message.isMe
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        linkStyle: TextStyle(
          color: widget.message.isMe
              ? Theme.of(context).colorScheme.onPrimary // Or a different color for links
              : Theme.of(context).colorScheme.primary, // Usually primary color for links
          decoration: TextDecoration.underline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip rendering if it's a quick reply message
    if (widget.message.type == MessageType.quickReply) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: widget.message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit bubble width
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.message.isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevent column from taking full width
          children: [
            _buildContent(), // Use the helper method to build content
            if (widget.message.suggestedReplies != null &&
                widget.message.suggestedReplies!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.message.suggestedReplies!
                      .map((reply) => TextButton(
                            onPressed: () => widget.onQuickReplyTap?.call(reply.value),
                            child: Text(reply.text),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary, // Text color
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Button bg
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
