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

    // Get screen width to properly constrain the widget
    final screenWidth = MediaQuery.of(context).size.width;

    // Use a simpler layout without ListTile to avoid overflow issues
    return Container(
      width: screenWidth - 16, // Leave 8px margin on each side
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
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
          
          // --- Replace Wrap with a horizontally scrolling ListView ---
          // Constrain the height of the ListView
          SizedBox(
            height: 40, // Adjust height as needed for button size + padding
            child: ListView.separated(
              scrollDirection: Axis.horizontal, // Make it scroll horizontally
              itemCount: quickReplies.length,
              itemBuilder: (context, index) {
                // Build each button using the existing method
                return _buildQuickReplyButton(
                  context, 
                  quickReplies[index], 
                  index // Pass index for animation
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8), // Spacing between buttons
            ),
          ),
          // --- End replacement ---
/* 
          // Old Wrap widget - commented out
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: quickReplies.map((reply) {
              return _buildQuickReplyButton(
                context, 
                reply, 
                quickReplies.indexOf(reply)
              );
            }).toList(),
          ),
*/
        ],
      ),
    );
  }

  Widget _buildQuickReplyButton(BuildContext context, QuickReply reply, int index) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    if (Platform.isIOS) {
      return _AnimatedQuickReply(
        index: index,
        animated: animated,
        child: GestureDetector(
          onTap: () => onReplySelected(reply.value),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              reply.text,
              style: const TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    } else {
      // Material design version
      final geminiBlue = Color(0xFF4285F4);
      
      return _AnimatedQuickReply(
        index: index,
        animated: animated,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onReplySelected(reply.value),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: geminiBlue.withOpacity(0.1),
                border: Border.all(
                  color: geminiBlue.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                reply.text,
                style: TextStyle(
                  color: geminiBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }
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