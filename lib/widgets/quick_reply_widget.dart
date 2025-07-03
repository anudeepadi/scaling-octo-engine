import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';

class QuickReplyWidget extends StatelessWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply) onReplySelected;

  const QuickReplyWidget({
    Key? key,
    required this.quickReplies,
    required this.onReplySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quickReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quickReplies.map((reply) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            alignment: Alignment.centerLeft,
            child: Platform.isIOS 
              ? _buildIOSQuickReply(reply, context)
              : _buildAndroidQuickReply(reply, context),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIOSQuickReply(QuickReply reply, BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF009688), // Teal color to match app theme
      borderRadius: BorderRadius.circular(16),
      minSize: 0,
      onPressed: () => onReplySelected(reply),
      child: Text(
        reply.text,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAndroidQuickReply(QuickReply reply, BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF009688), // Teal color to match app theme
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => onReplySelected(reply),
      child: Text(
        reply.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
