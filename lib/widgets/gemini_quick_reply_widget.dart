import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';
import 'dart:math' as math;

class GeminiQuickReplyWidget extends StatelessWidget {
  final List<QuickReply> quickReplies;
  final Function(String) onReplySelected;
  final bool animated;

  const GeminiQuickReplyWidget({
    Key? key,
    required this.quickReplies,
    required this.onReplySelected,
    this.animated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('GeminiQuickReplyWidget.build called with ${quickReplies.length} replies');
    if (quickReplies.isEmpty) {
      print('No quick replies to display');
      return const SizedBox.shrink();
    }
    
    print('Displaying quick replies: ${quickReplies.map((qr) => qr.text).join(', ')}');

    // Use a more contextual style that matches better with chat
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Platform.isIOS ? CupertinoIcons.sparkles : Icons.auto_awesome,
                color: Colors.blue,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                "Gemini Suggestions",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Display quick replies in a wrap for better text flow
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: quickReplies.map((reply) {
              if (Platform.isIOS) {
                return _buildIOSGeminiQuickReply(reply, context, quickReplies.indexOf(reply));
              } else {
                return _buildAndroidGeminiQuickReply(reply, context, quickReplies.indexOf(reply));
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSGeminiQuickReply(QuickReply reply, BuildContext context, int index) {
    return _AnimatedQuickReply(
      index: index,
      animated: animated,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: CupertinoColors.systemBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        minSize: 0,
        onPressed: () => onReplySelected(reply.value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            reply.text,
            style: const TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidGeminiQuickReply(QuickReply reply, BuildContext context, int index) {
    // Gemini brand color
    final geminiBlue = Color(0xFF4285F4);
    
    return _AnimatedQuickReply(
      index: index,
      animated: animated,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onReplySelected(reply.value),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: geminiBlue.withOpacity(0.1),
              border: Border.all(
                color: geminiBlue.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                reply.text,
                style: TextStyle(
                  color: geminiBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    Key? key,
    required this.child,
    required this.index,
    this.animated = true,
  }) : super(key: key);

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