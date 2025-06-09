import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';

class QuickReplyWidget extends StatelessWidget {
  final List<QuickReply> quickReplies;
  final Function(String) onReplySelected;

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
      margin: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: quickReplies.map((reply) {
          return Platform.isIOS 
            ? _buildIOSQuickReply(reply, context)
            : _buildAndroidQuickReply(reply, context);
        }).toList(),
      ),
    );
  }

  Widget _buildIOSQuickReply(QuickReply reply, BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      minSize: 20,
      onPressed: () => onReplySelected(reply.value),
      child: Text(
        reply.text,
        style: const TextStyle(
          color: CupertinoColors.systemBlue,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAndroidQuickReply(QuickReply reply, BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        minimumSize: const Size(30, 20),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => onReplySelected(reply.value),
      child: Text(
        reply.text,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
