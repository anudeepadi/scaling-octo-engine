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
      margin: const EdgeInsets.only(bottom: 4),
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          if (Platform.isIOS) {
            return _buildIOSQuickReply(quickReplies[index], context);
          } else {
            return _buildAndroidQuickReply(quickReplies[index], context);
          }
        },
      ),
    );
  }

  Widget _buildIOSQuickReply(QuickReply reply, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        minSize: 20,
        onPressed: () => onReplySelected(reply.value),
        child: Text(
          reply.text,
          style: const TextStyle(
            color: CupertinoColors.systemBlue,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidQuickReply(QuickReply reply, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(10, 20),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => onReplySelected(reply.value),
        child: Text(
          reply.text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
