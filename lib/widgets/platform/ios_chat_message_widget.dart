import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/chat_message.dart';
import '../video_player_widget.dart';
import '../youtube_player_widget.dart';
import '../quick_reply_widget.dart';
import '../gemini_quick_reply_widget.dart';

class IosChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onReplyTap;
  final Function(String)? onReactionAdd;

  const IosChatMessageWidget({
    Key? key,
    required this.message,
    this.onReplyTap,
    this.onReactionAdd,
  }) : super(key: key);

  @override
  State<IosChatMessageWidget> createState() => _IosChatMessageWidgetState();
}

class _IosChatMessageWidgetState extends State<IosChatMessageWidget> {
  Widget _buildContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.message.isMe ? CupertinoColors.white : CupertinoColors.black,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.message.mediaUrl!,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CupertinoActivityIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed);
            },
          ),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            widget.message.mediaUrl!,
            fit: BoxFit.cover,
            width: 200,
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading GIF as asset: $error');
              try {
                return Image.file(
                  File(widget.message.mediaUrl!),
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading local GIF: $error');
                    return Image.network(
                      widget.message.mediaUrl!,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CupertinoActivityIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed);
                      },
                    );
                  },
                );
              } catch (e) {
                print('Error loading GIF: $e');
                return const Icon(CupertinoIcons.photo, size: 50, color: CupertinoColors.systemGrey);
              }
            },
          ),
        );
      case MessageType.file:
        return Row(
          children: [
            const Icon(CupertinoIcons.doc, color: CupertinoColors.activeBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message.fileName ?? 'File',
                style: TextStyle(
                  color: widget.message.isMe ? CupertinoColors.white : CupertinoColors.black,
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
      case MessageType.geminiQuickReply:
        print('iOS Rendering Gemini quick replies');
        return widget.message.suggestedReplies != null ?
          GeminiQuickReplyWidget(
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

  @override
  Widget build(BuildContext context) {
    // Special debug case - force render Gemini quick replies outside the bubble
    if (widget.message.type == MessageType.geminiQuickReply) {
      print('iOS - Rendering Gemini Quick Reply directly, bypassing bubble');
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
          child: GeminiQuickReplyWidget(
            quickReplies: widget.message.suggestedReplies ?? [],
            onReplySelected: (value) {
              if (widget.onReactionAdd != null) {
                widget.onReactionAdd!(value);
              }
            },
          ),
        ),
      );
    }
  
    return Align(
      alignment: widget.message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.message.isMe ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
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
                    fontSize: 10,
                    color: widget.message.isMe ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.systemGrey,
                  ),
                ),
                if (widget.message.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(),
                    size: 12,
                    color: CupertinoColors.white.withOpacity(0.7),
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
        return CupertinoIcons.time;
      case MessageStatus.sent:
        return CupertinoIcons.check_mark;
      case MessageStatus.delivered:
        return CupertinoIcons.check_mark_circled;
      case MessageStatus.read:
        return CupertinoIcons.check_mark_circled_solid;
      case MessageStatus.failed:
        return CupertinoIcons.exclamationmark_circle;
      default:
        return CupertinoIcons.check_mark;
    }
  }
}
