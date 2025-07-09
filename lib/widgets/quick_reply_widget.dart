import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';
import '../services/quick_reply_state_service.dart';

class QuickReplyWidget extends StatefulWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply) onReplySelected;
  final String? messageId; // Add messageId to group quick replies

  const QuickReplyWidget({
    Key? key,
    required this.quickReplies,
    required this.onReplySelected,
    this.messageId,
  }) : super(key: key);

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
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.quickReplies.map((reply) {
          final bool isSelected = widget.messageId != null && 
              _quickReplyService.isQuickReplySelected(widget.messageId!, reply.value);
          final bool isDisabled = widget.messageId != null && 
              _quickReplyService.isOptionDisabled(widget.messageId!, reply.value);
          final bool isGreyedOut = isDisabled || isSelected;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            alignment: Alignment.centerLeft,
            child: Platform.isIOS 
              ? _buildIOSQuickReply(reply, context, isGreyedOut, isSelected)
              : _buildAndroidQuickReply(reply, context, isGreyedOut, isSelected),
          );
        }).toList(),
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
