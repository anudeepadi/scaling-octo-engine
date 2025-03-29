import 'package:flutter/material.dart';
import 'dart:io' show Platform, File;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/chat_message.dart';
import 'video_player_widget.dart';
import 'youtube_player_widget.dart';
import 'platform/ios_chat_message_widget.dart';
import 'quick_reply_widget.dart';
import 'gemini_quick_reply_widget.dart';
import 'improved_message_item.dart';

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
    print('_buildContent: MessageType=${widget.message.type}, hasReplies=${widget.message.suggestedReplies != null}, numReplies=${widget.message.suggestedReplies?.length ?? 0}');

    // Use the improved message item for most message types
    if (widget.message.type != MessageType.quickReply && 
        widget.message.type != MessageType.geminiQuickReply) {
      return ImprovedMessageItem(
        message: widget.message,
        onReplySelected: (value) {
          if (widget.onReactionAdd != null) {
            widget.onReactionAdd!(value);
          }
        },
      );
    }
    
    // Handle the special case types
    switch (widget.message.type) {
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
        print('FOUND GEMINI QUICK REPLY MESSAGE - rendering widget');
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
      print('Rendering Gemini Quick Reply directly, bypassing bubble');
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direct render of the quick replies
              widget.message.suggestedReplies != null 
                ? GeminiQuickReplyWidget(
                    quickReplies: widget.message.suggestedReplies!,
                    onReplySelected: (value) {
                      if (widget.onReactionAdd != null) {
                        widget.onReactionAdd!(value);
                      }
                    },
                  )
                : const Text('No suggestions available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    // Use iOS-specific implementation on iOS
    if (Platform.isIOS) {
      if (widget.message.suggestedReplies != null && widget.message.suggestedReplies!.isNotEmpty) {
        print('iOS - Rendering with quick replies, count: ${widget.message.suggestedReplies!.length}');
      }
      
      return ImprovedMessageItem(
        message: widget.message,
        onReplySelected: (value) {
          if (widget.onReactionAdd != null) {
            widget.onReactionAdd!(value);
          }
        },
      );
    }
    
    // For Android and other platforms
    return ImprovedMessageItem(
      message: widget.message,
      onReplySelected: (value) {
        if (widget.onReactionAdd != null) {
          widget.onReactionAdd!(value);
        }
      },
    );
  }
}
