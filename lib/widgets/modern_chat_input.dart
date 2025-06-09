import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../theme/app_theme.dart';

class ModernChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onGifPressed;
  final bool isComposing;

  const ModernChatInput({
    Key? key,
    required this.controller,
    required this.onSubmitted,
    required this.onAttachmentPressed,
    required this.onGifPressed,
    required this.isComposing,
  }) : super(key: key);

  @override
  State<ModernChatInput> createState() => _ModernChatInputState();
}

class _ModernChatInputState extends State<ModernChatInput> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sendButtonAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ModernChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isComposing != oldWidget.isComposing) {
      if (widget.isComposing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.controller.text.isNotEmpty) {
      widget.onSubmitted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 8,
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isComposing ? 0 : 40,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isComposing ? 0 : 1,
                  child: IconButton(
                    icon: Icon(
                      isIOS ? CupertinoIcons.paperclip : Icons.attach_file_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: widget.isComposing ? null : widget.onAttachmentPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
              
              // Input Field Container
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _focusNode.hasFocus 
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // GIF Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.isComposing ? 0 : 40,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: widget.isComposing ? 0 : 1,
                          child: IconButton(
                            icon: Icon(
                              Icons.gif_box_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                            onPressed: widget.isComposing ? null : widget.onGifPressed,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ),
                      
                      // Text Input
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: theme.textTheme.bodyLarge,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          maxLines: 5,
                          minLines: 1,
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                      ),
                      
                      // Emoji Button (when not composing)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.isComposing ? 0 : 40,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: widget.isComposing ? 0 : 1,
                          child: IconButton(
                            icon: Icon(
                              isIOS 
                                  ? CupertinoIcons.smiley 
                                  : Icons.emoji_emotions_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: widget.isComposing ? null : () {
                              // TODO: Show emoji picker
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send Button
              AnimatedBuilder(
                animation: _sendButtonAnimation,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: widget.isComposing
                          ? LinearGradient(
                              colors: AppTheme.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isComposing 
                          ? null 
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: widget.isComposing
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isComposing ? _handleSubmit : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return RotationTransition(
                                turns: Tween<double>(
                                  begin: 0.0,
                                  end: 0.5,
                                ).animate(animation),
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              widget.isComposing
                                  ? (isIOS 
                                      ? CupertinoIcons.arrow_up_circle_fill 
                                      : Icons.send_rounded)
                                  : (isIOS 
                                      ? CupertinoIcons.mic 
                                      : Icons.mic_none_rounded),
                              key: ValueKey(widget.isComposing),
                              color: widget.isComposing
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
