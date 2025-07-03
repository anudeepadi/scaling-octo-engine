import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../models/chat_message.dart';
import '../utils/app_localizations.dart';
import 'dart:io';

class DashChatScreen extends StatefulWidget {
  const DashChatScreen({super.key});

  @override
  State<DashChatScreen> createState() => _DashChatScreenState();
}

class _DashChatScreenState extends State<DashChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _showDebugInfo = false; // Keep debug panel hidden by default

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

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    final chatProvider = context.read<DashChatProvider>();
    await chatProvider.sendMessage(text.trim());
    _messageController.clear();
    _scrollToBottom();
  }

  Widget _buildMessageInput() {
    return Consumer<DashChatProvider>(
      builder: (context, chatProvider, child) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black12,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  onSubmitted: _handleSubmitted,
                  enabled: !chatProvider.isSendingMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: chatProvider.isSendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: chatProvider.isSendingMessage || _messageController.text.trim().isEmpty
                    ? null
                    : () => _handleSubmitted(_messageController.text),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('dash_chat')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Android debug button
          if (Platform.isAndroid)
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onSelected: (value) {
                switch (value) {
                  case 'reload':
                    context.read<DashChatProvider>().forceMessageReload();
                    break;
                  case 'debug_info':
                    setState(() {
                      _showDebugInfo = !_showDebugInfo;
                    });
                    break;
                  case 'force_sync':
                    context.read<DashChatProvider>().forceMessageSync();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reload',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Force Reload Messages'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'debug_info',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Toggle Debug Info'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'force_sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Force Message Sync'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Consumer<DashChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // Android Debug Info Panel
              if (Platform.isAndroid && _showDebugInfo)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.android, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Android Debug Info',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Messages: ${chatProvider.messages.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Loading: ${chatProvider.isLoading}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Sending: ${chatProvider.isSendingMessage}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chatProvider.getAndroidDebugInfo(),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              
              // Loading indicator
              if (chatProvider.isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Loading messages...'),
                    ],
                  ),
                ),
              
              // Chat messages
              Expanded(
                child: chatProvider.messages.isEmpty && !chatProvider.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).translate('no_messages'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).translate('start_conversation'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            // Android-specific empty state message
                            if (Platform.isAndroid) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.android, color: Colors.green),
                                    SizedBox(height: 8),
                                    Text(
                                      'Android Debug Mode',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Tap the bug icon to access debug tools',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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