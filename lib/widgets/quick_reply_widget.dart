import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';
import '../services/quick_reply_state_service.dart';
import '../theme/app_theme.dart';

class QuickReplyWidget extends StatefulWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply) onReplySelected;
  final String? messageId; // Add messageId to group quick replies

  const QuickReplyWidget({
    super.key,
    required this.quickReplies,
    required this.onReplySelected,
    this.messageId,
  });

  @override
  State<QuickReplyWidget> createState() => _QuickReplyWidgetState();
}

class _QuickReplyWidgetState extends State<QuickReplyWidget> {
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

  void _handleQuickReplyTap(QuickReply reply) {
    // If no messageId provided, use old behavior (single selection)
    if (widget.messageId == null) {
      widget.onReplySelected(reply);
      return;
    }

    // Check if any option has already been selected for this message
    if (_quickReplyService.isMessageSetDisabled(widget.messageId!)) {
      _showAlreadySelectedDialog();
      return;
    }
    
    // Select this option and disable all others in the set
    _quickReplyService.selectQuickReply(widget.messageId!, reply.value);
    
    // Trigger UI update
    setState(() {});
    
    // Call the original callback
    widget.onReplySelected(reply);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quickReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Replies',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick reply buttons in a wrap layout
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.quickReplies.map((reply) {
              final bool isSelected = widget.messageId != null && 
                  _quickReplyService.isQuickReplySelected(widget.messageId!, reply.value);
              final bool isDisabled = widget.messageId != null && 
                  _quickReplyService.isOptionDisabled(widget.messageId!, reply.value);
              
              return _buildModernQuickReply(reply, isSelected, isDisabled);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickReply(QuickReply reply, bool isSelected, bool isDisabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: (isDisabled || isSelected) ? null : () {
          HapticFeedback.lightImpact();
          _handleQuickReplyTap(reply);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.quitxtTeal.withValues(alpha: 0.1),
                      AppTheme.quitxtPurple.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent
                  : AppTheme.quitxtTeal.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: isSelected 
                ? [
                    BoxShadow(
                      color: AppTheme.quitxtTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ] else if (reply.icon != null) ...[
                Icon(
                  reply.icon,
                  size: 16,
                  color: AppTheme.quitxtTeal,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  reply.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.quitxtTeal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSQuickReply(QuickReply reply, BuildContext context, bool isGreyedOut, bool isSelected) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isGreyedOut 
          ? CupertinoColors.systemGrey4 // Greyed out color
          : const Color(0xFF009688), // Teal color to match app theme
      borderRadius: BorderRadius.circular(16),
      minSize: 0,
      onPressed: () => _handleQuickReplyTap(reply),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen,
                size: 14,
              ),
            ),
          Text(
            reply.text,
            style: TextStyle(
              color: isGreyedOut
                  ? CupertinoColors.systemGrey2 // Greyed out text
                  : CupertinoColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidQuickReply(QuickReply reply, BuildContext context, bool isGreyedOut, bool isSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isGreyedOut 
            ? Colors.grey[400] // Greyed out color
            : const Color(0xFF009688), // Teal color to match app theme
        foregroundColor: isGreyedOut 
            ? Colors.grey[600] // Greyed out text
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _handleQuickReplyTap(reply),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 14,
              ),
            ),
          Text(
            reply.text,
            style: TextStyle(
              color: isGreyedOut 
                  ? Colors.grey[600] // Greyed out text
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
