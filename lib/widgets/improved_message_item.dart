import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'gemini_quick_reply_widget.dart';
import '../models/quick_reply.dart';

class ImprovedMessageItem extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onReplySelected;

  const ImprovedMessageItem({
    Key? key,
    required this.message,
    required this.onReplySelected,
  }) : super(key: key);

  // Extract YouTube video ID from URL
  String? _extractYoutubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    
    final match = regExp.firstMatch(url);
    return match?.group(7);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isMe 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text content
                if (message.content.isNotEmpty && 
                    message.type != MessageType.gif &&
                    message.type != MessageType.image)
                  Linkify(
                    text: message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    linkStyle: TextStyle(
                      color: isMe ? Colors.white70 : Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    onOpen: (link) async {
                      if (await canLaunchUrl(Uri.parse(link.url))) {
                        await launchUrl(Uri.parse(link.url));
                      }
                    },
                  ),
                
                const SizedBox(height: 4),
                
                // Media content based on message type
                if (message.type == MessageType.youtube && message.mediaUrl != null)
                  _buildYoutubePreview(context, message.mediaUrl!),
                
                if (message.type == MessageType.gif && message.mediaUrl != null)
                  _buildGifPreview(context, message.mediaUrl!),
                
                if (message.type == MessageType.image && message.mediaUrl != null)
                  _buildImagePreview(context, message.mediaUrl!),
                
                if (message.type == MessageType.linkPreview && 
                    message.linkPreview != null &&
                    message.mediaUrl != null)
                  _buildLinkPreview(context, message.linkPreview!),
              ],
            ),
          ),
        ),
        
        // Timestamp
        Padding(
          padding: const EdgeInsets.only(
            left: 12.0,
            right: 12.0,
            bottom: 8.0,
          ),
          child: Text(
            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
        
        // Quick Replies (if present)
        if (message.suggestedReplies != null && message.suggestedReplies!.isNotEmpty)
          GeminiQuickReplyWidget(
            quickReplies: message.suggestedReplies!,
            onReplySelected: onReplySelected,
          ),
      ],
    );
  }

  Widget _buildYoutubePreview(BuildContext context, String url) {
    final videoId = _extractYoutubeVideoId(url);
    
    if (videoId == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () async {
              final youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
              if (await canLaunchUrl(youtubeUrl)) {
                await launchUrl(youtubeUrl);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://img.youtube.com/vi/$videoId/0.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
            if (await canLaunchUrl(youtubeUrl)) {
              await launchUrl(youtubeUrl);
            }
          },
          child: Text(
            'Watch on YouTube',
            style: TextStyle(
              color: message.isMe ? Colors.white70 : Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGifPreview(BuildContext context, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context, linkPreview) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(linkPreview.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: message.isMe 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If we have an image thumbnail
            if (linkPreview.imageUrl != null && linkPreview.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: linkPreview.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.language),
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Link title
            Text(
              linkPreview.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: message.isMe ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Link description
            if (linkPreview.description.isNotEmpty)
              Text(
                linkPreview.description,
                style: TextStyle(
                  color: message.isMe ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            
            const SizedBox(height: 4),
            
            // Link URL
            Text(
              Uri.parse(linkPreview.url).host,
              style: TextStyle(
                color: message.isMe ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
