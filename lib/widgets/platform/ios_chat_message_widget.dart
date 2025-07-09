import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../models/chat_message.dart';
import '../video_player_widget.dart';
import '../youtube_player_widget.dart';
import '../quick_reply_widget.dart';
import '../../utils/debug_config.dart';
import '../../services/quick_reply_state_service.dart';

class IosChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onReplyTap;
  final Function(String)? onReactionAdd;
  final Function(String)? onQuickReplyTap;

  const IosChatMessageWidget({
    super.key,
    required this.message,
    this.onReplyTap,
    this.onReactionAdd,
    this.onQuickReplyTap,
  });

  @override
  State<IosChatMessageWidget> createState() => _IosChatMessageWidgetState();
}

class _IosChatMessageWidgetState extends State<IosChatMessageWidget> {
  final QuickReplyStateService _quickReplyService = QuickReplyStateService();

  void _showAlreadySelectedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Option Already Selected'),
          content: const Text('You have already selected an option for this question and cannot select another one.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleQuickReplyTap(String value) {
    // Check if any option has already been selected for this message
    if (_quickReplyService.isMessageSetDisabled(widget.message.id)) {
      _showAlreadySelectedDialog();
      return;
    }
    
    // Select this option and disable all others in the set
    _quickReplyService.selectQuickReply(widget.message.id, value);
    
    // Trigger UI update
    setState(() {});
    
    // Call the original callback
    widget.onQuickReplyTap?.call(value);
  }

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
              DebugConfig.debugPrint('Error loading GIF as asset: $error');
              try {
                return Image.file(
                  File(widget.message.mediaUrl!),
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    DebugConfig.debugPrint('Error loading local GIF: $error');
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
                DebugConfig.debugPrint('Error loading GIF: $e');
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
            onReplySelected: (reply) {
              if (widget.onReactionAdd != null) {
                widget.onReactionAdd!(reply.value);
              }
            },
          ) : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
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
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.message.isMe
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.content,
              style: TextStyle(
                color: widget.message.isMe
                    ? CupertinoColors.white
                    : CupertinoColors.black,
              ),
            ),
            if (widget.message.suggestedReplies != null &&
                widget.message.suggestedReplies!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.message.suggestedReplies!
                      .map((reply) {
                        final bool isSelected = _quickReplyService.isQuickReplySelected(widget.message.id, reply.value);
                        final bool isDisabled = _quickReplyService.isOptionDisabled(widget.message.id, reply.value);
                        final bool isGreyedOut = isDisabled || isSelected;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: isGreyedOut 
                                ? CupertinoColors.systemGrey4 // Greyed out color
                                : (widget.message.isMe
                                    ? CupertinoColors.white.withValues(alpha: 0.2)
                                    : CupertinoColors.activeBlue.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      CupertinoIcons.check_mark_circled_solid,
                                      color: CupertinoColors.systemGreen,
                                      size: 16,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    reply.text,
                                    style: TextStyle(
                                      color: isGreyedOut
                                          ? CupertinoColors.systemGrey2 // Greyed out text
                                          : (widget.message.isMe
                                              ? CupertinoColors.white
                                              : CupertinoColors.activeBlue),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () => _handleQuickReplyTap(reply.value),
                          ),
                        );
                      })
                      .toList(),
                ),
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
