import 'package:flutter/material.dart';
import 'dart:io' show Platform, File;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/chat_message.dart';
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
  Widget _buildContent() {
    print('_buildContent: MessageType=${widget.message.type}, hasReplies=${widget.message.suggestedReplies != null}, numReplies=${widget.message.suggestedReplies?.length ?? 0}');

    // Use the improved message item for most message types
    if (widget.message.type != MessageType.quickReply) {
      return ImprovedMessageItem(
        message: widget.message,
        onReplySelected: (value) {
          if (widget.onReactionAdd != null) {
            widget.onReactionAdd!(value);
          }
        },
      );
    }
    
    // Handle quick reply type
    return widget.message.suggestedReplies != null ?
      QuickReplyWidget(
        quickReplies: widget.message.suggestedReplies!,
        onReplySelected: (value) {
          if (widget.onReactionAdd != null) {
            widget.onReactionAdd!(value);
          }
        },
      ) : const SizedBox.shrink();
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
          children: [
            Text(
              widget.message.content,
              style: TextStyle(
                color: widget.message.isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
                              backgroundColor: Theme.of(context).colorScheme.surface,
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
