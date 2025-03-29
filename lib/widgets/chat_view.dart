import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/system_chat_provider.dart';
import '../models/chat_message.dart';
import 'chat_message_widget.dart';
import 'quick_reply_bar.dart';
import 'chat_input.dart';
import 'typing_indicator.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add post-frame callback to scroll to bottom on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMessageSubmit(String message) {
    if (message.trim().isEmpty) return;
    context.read<SystemChatProvider>().addUserMessage(message);
    _scrollToBottom();
  }

  void _handleGifSelected(String gifUrl) {
    context.read<SystemChatProvider>().addGifMessage(gifUrl);
    _scrollToBottom();
  }

  void _handleQuickReplySelected(String value) {
    context.read<SystemChatProvider>().handleQuickReply(value);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<SystemChatProvider>(
            builder: (context, provider, child) {
              // Print diagnostics
              print('Rendering chat with ${provider.messages.length} messages');
              print('Has Gemini quick replies: ${provider.hasGeminiQuickReplies}');
              
              return Stack(
                children: [
                  // Chat messages
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 16, // Add extra padding at bottom for typing indicator
                    ),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      return ChatMessageWidget(
                        key: ValueKey('msg_${message.id}'),
                        message: message,
                        onReplyTap: () {
                          // Handle reply tap
                        },
                        onReactionAdd: _handleQuickReplySelected,
                      );
                    },
                  ),
                  
                  // Typing indicator (if needed)
                  if (provider.isTyping)
                    Positioned(
                      bottom: 0,
                      left: 16,
                      child: TypingIndicator(),
                    ),
                ],
              );
            },
          ),
        ),
        
        // Quick reply bar at the bottom
        Consumer<SystemChatProvider>(
          builder: (context, provider, child) {
            if (provider.hasQuickReplies) {
              return QuickReplyBar(
                onReplySelected: _handleQuickReplySelected,
                quickReplies: provider.quickReplies,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        
        // Chat input
        ChatInput(
          onMessageSubmit: _handleMessageSubmit,
          onGifSelected: _handleGifSelected,
        ),
      ],
    );
  }
}