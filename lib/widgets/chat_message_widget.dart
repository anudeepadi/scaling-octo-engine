import 'package:flutter/material.dart';
import 'dart:io' show Platform, File;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../providers/dash_chat_provider.dart';
import 'video_player_widget.dart';
import 'youtube_player_widget.dart';
import '../theme/app_theme.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onReplyTap;
  final Function(String)? onReactionAdd;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.onReplyTap,
    this.onReactionAdd,
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
     return trimmedContent.startsWith('assets/') && trimmedContent.toLowerCase().endsWith('.gif');
  }

  // Helper to launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Widget _buildContent() {
    // --- Check for Local Asset GIF First --- 
    if (_isLocalAssetGif(widget.message.content)) {
       try {
          return Image.asset(
             widget.message.content.trim(),
             height: 150,
             fit: BoxFit.contain,
             errorBuilder: (context, error, stackTrace) {
                print("Image.asset Error loading ${widget.message.content}: $error");
                return Container(
                   height: 150,
                   color: Colors.grey[300],
                   child: const Center(child: Icon(Icons.error, color: Colors.red))
                );
             },
          );
       } catch (e) {
           print("Error loading asset ${widget.message.content}: $e");
           return Text("[Error loading asset: ${widget.message.content}]", style: const TextStyle(color: Colors.red));
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
          // Display the tappable thumbnail
          GestureDetector(
            onTap: () => _launchURL(firstUrl),
            child: Image.network(
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
                print("Error loading $thumbnailUrl: $error");
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
                print("Error loading $firstUrl: $error");
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
          color: widget.message.isMe
              ? Colors.white
              : AppTheme.quitxtPurple,
          decoration: TextDecoration.underline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render quick reply buttons if this is a quick reply message
    final replies = (widget.message.suggestedReplies != null && widget.message.suggestedReplies!.isNotEmpty)
        ? widget.message.suggestedReplies
        : (widget.message.quickReplies != null && widget.message.quickReplies!.isNotEmpty)
            ? widget.message.quickReplies
            : null;
    if (widget.message.type == MessageType.quickReply && replies != null && replies.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Wrap(
          spacing: 8,
          children: replies.map((reply) {
            return ElevatedButton(
              onPressed: () {
                final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);
                dashChatProvider.handleQuickReply(reply);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.quitxtTeal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
              ),
              child: Text(reply.text),
            );
          }).toList(),
        ),
      );
    }

    // Build content bubble
    Widget contentBubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.message.isMe
            ? AppTheme.quitxtTeal
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildContent(),
    );

    return Align(
      alignment: widget.message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: widget.message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
         children: [
            contentBubble,
         ],
      ),
    );
  }
}