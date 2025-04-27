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
import 'platform/ios_chat_message_widget.dart';
import 'quick_reply_widget.dart';
import 'improved_message_item.dart';
import '../providers/chat_mode_provider.dart';
import '../providers/chat_provider.dart';

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
     // Add trim() to handle potential leading/trailing whitespace
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

    // --- Check for Local Asset GIF First --- 
    if (_isLocalAssetGif(widget.message.content)) {
       print("ChatMessageWidget (${widget.message.id}): Entered _isLocalAssetGif block."); // Confirm entry
       try {
          return Image.asset(
             widget.message.content.trim(), // Use trimmed content here too
             height: 150, // Adjust size as needed
             fit: BoxFit.contain, // Or BoxFit.cover
             errorBuilder: (context, error, stackTrace) {
                print("Image.asset Error loading ${widget.message.content}: $error");
                return Container(
                   height: 150,
                   color: Colors.grey[300],
                   child: const Center(
                      child: Icon(Icons.error, color: Colors.red)
                   )
                );
             },
          );
       } catch (e) {
           print("ChatMessageWidget (${widget.message.id}): EXCEPTION loading asset ${widget.message.content}: $e");
           // Fallback or error display if exception occurs during asset loading
           return Text("[Error loading asset: ${widget.message.content}]", style: const TextStyle(color: Colors.red));
       }
    }
    // --- End Local Asset GIF Check --- 

    // --- Network URL Processing --- 
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
                      ? Colors.black87 // Dark text on light grey
                      : Colors.white, // White text on dark grey
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
                      ? Colors.black87 // Dark text on light grey
                      : Colors.white, // White text on dark grey
                ),
              ),
            ),
        ],
      );
    } else {
      // --- Add Image/GIF Handling --- 
      if (firstUrl != null && _isImageUrl(firstUrl) && match != null) {
        // It's an image/GIF URL
        print("ChatMessageWidget (${widget.message.id}): Identified as Network Image/GIF URL.");
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
                        ? Colors.black87 // Dark text on light grey
                        : Colors.white, // White text on dark grey
                  ),
                ),
              ),
            // Display the tappable thumbnail
            GestureDetector(
              onTap: () => _launchURL(firstUrl), // Launch the found URL
              child: Image.network(
                firstUrl,
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
                  print("Image.network Error loading $firstUrl: $error"); // Add error logging
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
                        ? Colors.black87 // Dark text on light grey
                        : Colors.white, // White text on dark grey
                  ),
                ),
              ),
          ],
        );
      } else {
        // --- End Image/GIF Handling ---
        // Default: Use Linkify for the whole message if no YouTube/Image/GIF/Asset found or error
        print("ChatMessageWidget (${widget.message.id}): Falling back to Linkify.");
        return Linkify(
          onOpen: (link) => _launchURL(link.url),
          text: widget.message.content,
          style: TextStyle(
            color: widget.message.isMe
                ? Colors.black87 // Dark text on light grey
                : Colors.white, // White text on dark grey
          ),
          linkStyle: TextStyle(
            color: widget.message.isMe
                ? Theme.of(context).colorScheme.primary // Keep link color for user messages
                : Colors.lightBlue[200], // Lighter blue links on dark background
            decoration: TextDecoration.underline,
          ),
        );
      }
    }
    // This part should ideally not be reached if all cases (local, yt, net img, linkify) are handled
    // Return Linkify as a final safety net
    // print("ChatMessageWidget (${widget.message.id}): Reached unexpected end, using Linkify.");
    // return Linkify(
    //    onOpen: (link) => _launchURL(link.url),
    //    text: widget.message.content,
    //    style: TextStyle(
    //       color: widget.message.isMe
    //          ? Theme.of(context).colorScheme.onPrimary
    //          : Theme.of(context).colorScheme.onSurface,
    //    ),
    //    linkStyle: TextStyle(
    //       color: widget.message.isMe
    //          ? Theme.of(context).colorScheme.onPrimary
    //          : Theme.of(context).colorScheme.primary,
    //       decoration: TextDecoration.underline,
    //    ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    // Skip rendering if it's a quick reply message
    if (widget.message.type == MessageType.quickReply) {
      return const SizedBox.shrink();
    }

    // --- Build Quick Replies Separately (if they exist) ---
    Widget? quickRepliesWidget;
    if (widget.message.suggestedReplies != null &&
        widget.message.suggestedReplies!.isNotEmpty) {
      quickRepliesWidget = Padding(
        // Add horizontal padding to align roughly with bubble, top padding for spacing
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0), 
        child: Column(
          // Align buttons based on message sender (might need adjustment)
          crossAxisAlignment: widget.message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Take minimum vertical space
          children: widget.message.suggestedReplies!
              .map((reply) => Padding(
                    // Add padding between buttons
                    padding: const EdgeInsets.only(top: 6.0), 
                    child: TextButton(
                        onPressed: () {
                          print("[ChatMessageWidget] Quick Reply Button Tapped! Reply Text: ${reply.text}, Value: ${reply.value}");
                          // Check if this is the Gemini switch button
                          if (reply.text == "Chat with Gemini") {
                            print("[ChatMessageWidget] Switching to Gemini Mode...");
                            // Get providers
                            final chatModeProvider = context.read<ChatModeProvider>();
                            final genericChatProvider = context.read<ChatProvider>(); // Use generic ChatProvider
                            
                            // Switch mode
                            chatModeProvider.setMode(ChatMode.gemini);
                            
                            // Optional: Decide if you want to clear history on switch
                            // genericChatProvider.clearChatHistory(); 

                          } else {
                            // Otherwise, handle as a normal Dash quick reply
                            print("[ChatMessageWidget] Handling as normal Dash quick reply.");
                            final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);
                            dashChatProvider.handleQuickReply(reply);
                          }
                        },
                        child: Text(reply.text),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF008080), // Teal text
                          backgroundColor: Colors.grey[100], // Light grey background
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder( // Rounded corners
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft, // Align text left
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 1, // Slight elevation can help separation
                        ),
                    ),
                  ))
              .toList(),
        ),
      );
    } // --- End Build Quick Replies ---

    // --- Build Content Bubble --- 
    Widget contentBubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit bubble width
      ),
      // Keep margin on the bubble itself for spacing from edges
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), 
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        // Adjust colors based on image more closely
        color: widget.message.isMe
            ? Colors.grey[300] // Keep light grey for user messages
            : const Color(0xFF303030), // Very dark grey for incoming messages
        borderRadius: BorderRadius.circular(12),
      ),
      // Content bubble only contains the main message content now
      child: _buildContent(), 
    );
    // --- End Build Content Bubble ---

    // --- Combine Bubble and Replies (if any) in an Aligned Column ---
    return Align(
      alignment: widget.message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
         mainAxisSize: MainAxisSize.min,
         // Align the whole column block left/right
         crossAxisAlignment: widget.message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, 
         children: [
            contentBubble,
            if (quickRepliesWidget != null) quickRepliesWidget, // Add replies below bubble
         ],
      )
    );
    // --- End Combination ---
  }
}
