import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../providers/dash_chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../utils/debug_config.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({super.key});

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  bool _showEmojiPicker = false;
  late AnimationController _fabAnimationController;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabAnimationController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {
      _isComposing = _messageController.text.trim().isNotEmpty;
    });
    
    if (_isComposing) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final dashChatProvider = context.read<DashChatProvider>();
    dashChatProvider.sendMessage(text.trim());

    _messageController.clear();
    _scrollToBottom();
    _focusNode.unfocus();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildModernInputArea(),
        ],
      ),
      floatingActionButton: _buildScrollToBottomFab(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QuitTXT Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Here to help you quit smoking',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[700]),
          onPressed: () {
            _showChatOptions();
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer<DashChatProvider>(
      builder: (context, dashChatProvider, child) {
        if (dashChatProvider.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: dashChatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = dashChatProvider.messages[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildMessageBubble(message, dashChatProvider),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, DashChatProvider dashChatProvider) {
    final shouldShowQuickReplies = message.type == MessageType.quickReply && 
        message.suggestedReplies != null && 
        message.suggestedReplies!.isNotEmpty;

    if (shouldShowQuickReplies) {
      return Column(
        children: [
          ChatMessageWidget(
            message: message,
            onReplyTap: () => _scrollToBottom(),
            onReactionAdd: (value) {
              if (value.isNotEmpty) {
                dashChatProvider.handleQuickReply(
                  QuickReply(text: value, value: value)
                );
              }
              _scrollToBottom();
            },
          ),
          const SizedBox(height: 8),
          QuickReplyWidget(
            quickReplies: message.suggestedReplies!,
            onReplySelected: (reply) {
              dashChatProvider.handleQuickReply(reply);
              _scrollToBottom();
            },
          ),
        ],
      );
    } else {
      return ChatMessageWidget(
        message: message,
        onReplyTap: () => _scrollToBottom(),
        onReactionAdd: (value) {
          if (value.isNotEmpty) {
            dashChatProvider.handleQuickReply(
              QuickReply(text: value, value: value)
            );
          }
          _scrollToBottom();
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.quitxtTeal.withValues(alpha: 0.1),
                  AppTheme.quitxtPurple.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.psychology,
              size: 60,
              color: AppTheme.quitxtTeal,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to QuitTXT! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal smoking cessation assistant',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.quitxtTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Start your journey to a smoke-free life',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.quitxtTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 1,
                          onSubmitted: _handleSubmitted,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Implement attachment picker
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _fabAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _fabAnimationController.value),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isComposing
                              ? [AppTheme.quitxtTeal, AppTheme.quitxtPurple]
                              : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: _isComposing
                            ? [
                                BoxShadow(
                                  color: AppTheme.quitxtTeal.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _isComposing
                              ? () => _handleSubmitted(_messageController.text)
                              : null,
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildScrollToBottomFab() {
    return Consumer<DashChatProvider>(
      builder: (context, dashChatProvider, child) {
        if (dashChatProvider.messages.isEmpty) return const SizedBox.shrink();
        
        return FloatingActionButton.small(
          onPressed: _scrollToBottom,
          backgroundColor: AppTheme.quitxtTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          child: const Icon(Icons.keyboard_arrow_down),
        );
      },
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Clear Chat'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement clear chat
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement help
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}