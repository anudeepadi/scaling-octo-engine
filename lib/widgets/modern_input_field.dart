import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ModernInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSend;
  final Function(String)? onTextChanged;
  final String hintText;
  final bool enabled;

  const ModernInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onSend,
    this.onTextChanged,
    this.hintText = 'Type a message...',
    this.enabled = true,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField>
    with TickerProviderStateMixin {
  bool _isComposing = false;
  bool _showAttachmentOptions = false;
  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _sendButtonController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final isComposing = widget.controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      
      if (_isComposing) {
        _sendButtonController.forward();
        _attachmentController.reverse();
      } else {
        _sendButtonController.reverse();
        _attachmentController.forward();
      }
    }
    
    widget.onTextChanged?.call(widget.controller.text);
  }

  void _handleSend() {
    if (_isComposing && widget.onSend != null) {
      HapticFeedback.lightImpact();
      widget.onSend!();
    }
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
    
    if (_showAttachmentOptions) {
      _attachmentController.forward();
    } else {
      _attachmentController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showAttachmentOptions) _buildAttachmentOptions(),
            _buildInputRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Attachment button
          AnimatedBuilder(
            animation: _attachmentController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _attachmentController.value),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _showAttachmentOptions
                        ? AppTheme.quitxtTeal.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _showAttachmentOptions
                          ? AppTheme.quitxtTeal.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _toggleAttachmentOptions,
                      child: Icon(
                        _showAttachmentOptions ? Icons.close : Icons.add,
                        color: _showAttachmentOptions
                            ? AppTheme.quitxtTeal
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Text input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? AppTheme.quitxtTeal.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      minLines: 1,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  // Emoji button
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Implement emoji picker
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Send button
          AnimatedBuilder(
            animation: _sendButtonController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _sendButtonController.value),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _isComposing
                        ? LinearGradient(
                            colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _isComposing ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: _isComposing
                        ? [
                            BoxShadow(
                              color: AppTheme.quitxtTeal.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _isComposing ? _handleSend : null,
                      child: Icon(
                        Icons.send_rounded,
                        color: _isComposing ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _showAttachmentOptions ? 80 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue,
              onTap: () {
                // TODO: Implement camera
                _toggleAttachmentOptions();
              },
            ),
            _buildAttachmentOption(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.green,
              onTap: () {
                // TODO: Implement gallery
                _toggleAttachmentOptions();
              },
            ),
            _buildAttachmentOption(
              icon: Icons.gif_box,
              label: 'GIF',
              color: Colors.orange,
              onTap: () {
                // TODO: Implement GIF picker
                _toggleAttachmentOptions();
              },
            ),
            _buildAttachmentOption(
              icon: Icons.location_on,
              label: 'Location',
              color: Colors.red,
              onTap: () {
                // TODO: Implement location sharing
                _toggleAttachmentOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}