import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';
import '../utils/debug_config.dart';
import '../services/quick_reply_state_service.dart';

class GeminiQuickReplyWidget extends StatefulWidget {
  final List<QuickReply> quickReplies;
  final Function(String) onReplySelected;
  final bool animated;
  final String? messageId; // Add messageId to group quick replies

  const GeminiQuickReplyWidget({
    super.key,
    required this.quickReplies,
    required this.onReplySelected,
    this.animated = true,
    this.messageId,
  });

  @override
  State<GeminiQuickReplyWidget> createState() => _GeminiQuickReplyWidgetState();
}

class _GeminiQuickReplyWidgetState extends State<GeminiQuickReplyWidget> {
  final QuickReplyStateService _quickReplyService = QuickReplyStateService();

  void _showAlreadySelectedDialog() {
    if (Platform.isIOS) {
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
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Option Already Selected'),
            content: const Text('You have already selected an option for this question and cannot select another one.'),
            actions: [
              TextButton(
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
  }

  void _handleQuickReplyTap(String value) {
    // If no messageId provided, use old behavior (single selection)
    if (widget.messageId == null) {
      widget.onReplySelected(value);
      return;
    }

    // Check if any option has already been selected for this message
    if (_quickReplyService.isMessageSetDisabled(widget.messageId!)) {
      _showAlreadySelectedDialog();
      return;
    }
    
    // Select this option and disable all others in the set
    _quickReplyService.selectQuickReply(widget.messageId!, value);
    
    // Trigger UI update
    setState(() {});
    
    // Call the original callback
    widget.onReplySelected(value);
  }

  @override
  Widget build(BuildContext context) {
    DebugConfig.debugPrint('GeminiQuickReplyWidget.build called with ${widget.quickReplies.length} replies');
    if (widget.quickReplies.isEmpty) {
      DebugConfig.debugPrint('No quick replies to display');
      return const SizedBox.shrink();
    }

    DebugConfig.debugPrint('Displaying quick replies: ${widget.quickReplies.map((qr) => qr.text).join(', ')}');

    // Get screen width to properly constrain the widget
    final screenWidth = MediaQuery.of(context).size.width;

    // Use a simpler layout without ListTile to avoid overflow issues
    return Container(
      width: screenWidth - 16, // Leave 8px margin on each side
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Platform.isIOS ? CupertinoIcons.sparkles : Icons.auto_awesome,
                color: Colors.blue,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Gemini Suggestions",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // --- Replace horizontally scrolling ListView with vertical Column ---
          const SizedBox(height: 4),
          
          // Horizontal layout with Wrap widget
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: widget.quickReplies.map((reply) {
              final bool isSelected = widget.messageId != null && 
                  _quickReplyService.isQuickReplySelected(widget.messageId!, reply.value);
              final bool isDisabled = widget.messageId != null && 
                  _quickReplyService.isOptionDisabled(widget.messageId!, reply.value);
              final bool isGreyedOut = isDisabled || isSelected;
              
              return _buildQuickReplyButton(
                context, 
                reply, 
                widget.quickReplies.indexOf(reply),
                isGreyedOut,
                isSelected
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyButton(BuildContext context, QuickReply reply, int index, bool isGreyedOut, bool isSelected) {
    if (Platform.isIOS) {
      return _AnimatedQuickReply(
        index: index,
        animated: widget.animated,
        child: GestureDetector(
          onTap: () => _handleQuickReplyTap(reply.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isGreyedOut 
                  ? CupertinoColors.systemGrey4.withValues(alpha: 0.5)
                  : CupertinoColors.systemBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.systemGreen,
                      size: 10,
                    ),
                  ),
                Text(
                  reply.text,
                  style: TextStyle(
                    color: isGreyedOut 
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Material design version
    final geminiBlue = Color(0xFF4285F4);
    
    return _AnimatedQuickReply(
      index: index,
      animated: widget.animated,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleQuickReplyTap(reply.value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isGreyedOut 
                  ? Colors.grey[300]
                  : geminiBlue.withValues(alpha: 0.1),
              border: Border.all(
                color: isGreyedOut 
                    ? Colors.grey[400]!
                    : geminiBlue.withValues(alpha: 0.3),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 10,
                    ),
                  ),
                Text(
                  reply.text,
                  style: TextStyle(
                    color: isGreyedOut 
                        ? Colors.grey[600]
                        : geminiBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animation wrapper for quick replies
class _AnimatedQuickReply extends StatefulWidget {
  final Widget child;
  final int index;
  final bool animated;

  const _AnimatedQuickReply({
    super.key,
    required this.child,
    required this.index,
    this.animated = true,
  });

  @override
  State<_AnimatedQuickReply> createState() => _AnimatedQuickReplyState();
}

class _AnimatedQuickReplyState extends State<_AnimatedQuickReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted && widget.animated) {
        _controller.forward();
      }
    });

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // If not animated, set to end state
    if (!widget.animated) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: 0.6 + (_scaleAnimation.value * 0.4),
            child: widget.child,
          ),
        );
      },
    );
  }
}