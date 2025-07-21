import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../models/chat_message.dart';
import '../utils/app_localizations.dart';

class CleanChatScreen extends StatefulWidget {
  const CleanChatScreen({super.key});

  @override
  State<CleanChatScreen> createState() => _CleanChatScreenState();
}

class _CleanChatScreenState extends State<CleanChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Show confirmation dialog before clearing messages
  Future<void> _showClearConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Messages'),
          content: const Text('Are you sure you want to delete all messages? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      final chatProvider = Provider.of<DashChatProvider>(context, listen: false);
      await chatProvider.clearAllMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All messages have been cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    final chatProvider = context.read<DashChatProvider>();
    await chatProvider.sendMessage(text.trim());
    _messageController.clear();
    _scrollToBottom();
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate('type_message'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF009688), // QuiTXT teal
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuiTXT Messages'),
        backgroundColor: const Color(0xFF009688), // QuiTXT teal
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Messages',
            onPressed: () => _showClearConfirmationDialog(context),
          ),
        ],
      ),
      body: Consumer<DashChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // CLEAN MESSAGE HISTORY ONLY - No debug info, no loading indicators
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Welcome to QuiTXT',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your message history will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          
                          // Find the most recent quick reply message (should be the active one)
                          final mostRecentQuickReplyIndex = _findMostRecentQuickReplyIndex(chatProvider.messages);
                          final shouldShowQuickReplies = message.type == MessageType.quickReply && 
                              message.suggestedReplies != null && 
                              message.suggestedReplies!.isNotEmpty &&
                              mostRecentQuickReplyIndex != null &&
                              index == mostRecentQuickReplyIndex; // Only show for most recent
                          
                          if (shouldShowQuickReplies) {
                            return Column(
                              children: [
                                if (message.content.isNotEmpty)
                                  ChatMessageWidget(message: message),
                                QuickReplyWidget(
                                  quickReplies: message.suggestedReplies!,
                                  messageId: message.id,
                                  onReplySelected: (reply) {
                                    chatProvider.sendMessage(reply.value);
                                    _scrollToBottom();
                                  },
                                ),
                              ],
                            );
                          } else {
                            return ChatMessageWidget(message: message);
                          }
                        },
                      ),
              ),
              
              // Message input
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  // Find the index of the most recent quick reply message
  int? _findMostRecentQuickReplyIndex(List<ChatMessage> messages) {
    // Search from the end (most recent) to find the last quick reply message
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (message.type == MessageType.quickReply && 
          message.suggestedReplies != null && 
          message.suggestedReplies!.isNotEmpty) {
        return i;
      }
    }
    return null; // No quick reply messages found
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
} 