import 'package:flutter/material.dart';
import 'dart:io' show Platform, File;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/chat_message.dart';
import 'video_player_widget.dart';
import 'youtube_player_widget.dart';
import 'platform/ios_chat_message_widget.dart';
import 'quick_reply_widget.dart';

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
  Widget _buildContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.message.isMe ? Colors.white : Colors.black,
            fontSize: 16,  // Adjust text size to be more readable
          ),
        );
      case MessageType.image:
        return Image.network(
          widget.message.mediaUrl!,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error);
          },
        );
      case MessageType.video:
        return VideoPlayerWidget(
          videoUrl: widget.message.mediaUrl!,
          autoPlay: false,
          showControls: true,
        );
      case MessageType.youtube:
        return YouTubePlayerWidget(
          videoUrl: widget.message.mediaUrl!,
        );
      case MessageType.gif:
        return _buildGifMessage();
      case MessageType.file:
        return Row(
          children: [
            const Icon(Icons.file_present),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message.fileName ?? 'File',
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        );
      case MessageType.quickReply:
        return widget.message.suggestedReplies != null ? 
          QuickReplyWidget(
            quickReplies: widget.message.suggestedReplies!,
            onReplySelected: (value) {
              if (widget.onReactionAdd != null) {
                widget.onReactionAdd!(value);
              }
            },
          ) : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGifMessage() {
    try {
      final mediaUrl = widget.message.mediaUrl ?? '';
      print('Trying to load GIF: $mediaUrl');
      
      // Determine the asset path based on the input
      String assetPath;
      if (mediaUrl.startsWith('assets/')) {
        // Already a full asset path
        assetPath = mediaUrl;
      } else if (!mediaUrl.contains('/')) {
        // Just a filename, assume it's in assets/images
        assetPath = 'assets/images/$mediaUrl';
      } else {
        // Full path from elsewhere
        assetPath = mediaUrl;
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading GIF as asset: $error (path: $assetPath)');
                  // If asset loading fails, try file or fallback
                  return _buildGifFallback(mediaUrl);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in GIF rendering: $e');
      return Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40),
        ),
      );
    }
  }

  Widget _buildGifFallback(String mediaUrl) {
    try {
      if (mediaUrl.startsWith('http')) {
        // Network image
        return Image.network(
          mediaUrl,
          width: 200,
          height: 150,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 40),
          ),
        );
      } else {
        // Try as file
        return Image.file(
          File(mediaUrl),
          width: 200,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 40),
            ),
          ),
        );
      }
    } catch (e) {
      print('GIF fallback error: $e');
      return Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use iOS-specific implementation on iOS
    if (Platform.isIOS) {
      return IosChatMessageWidget(
        message: widget.message,
        onReplyTap: widget.onReplyTap,
        onReactionAdd: widget.onReactionAdd,
      );
    }
    
    // Default Android/material implementation
    return Align(
      alignment: widget.message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.message.isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.message.timestamp.hour}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.message.isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (widget.message.isMe) ...[  
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(),
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }
}