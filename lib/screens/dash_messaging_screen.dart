import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../providers/dash_chat_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';

class DashMessagingScreen extends StatefulWidget {
  const DashMessagingScreen({Key? key}) : super(key: key);

  @override
  _DashMessagingScreenState createState() => _DashMessagingScreenState();
}

class _DashMessagingScreenState extends State<DashMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Link DashChatProvider to ChatProvider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        final dashProvider = context.read<DashChatProvider>();
        dashProvider.setChatProvider(chatProvider);
        print('DashMessagingScreen: Linked DashChatProvider and ChatProvider.');
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    try {
      _messageController.clear();
      
      // Use DashChatProvider to send message
      final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);
      await dashChatProvider.sendMessage(messageText);
      
      _scrollToBottom();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _scrollToBottom({bool isDelayed = false}) {
    if (_scrollController.hasClients) {
      final scrollToTask = () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      };
      
      if (isDelayed) {
        Future.delayed(const Duration(milliseconds: 100), scrollToTask);
      } else {
        scrollToTask();
      }
    }
  }

  void _processCustomJson() {
    // Skip loading demo JSON messages to keep chat completely clean
    print('Demo JSON message loading disabled - no hardcoded messages will be loaded');
    return;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dash Messaging Help'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commands you can try:'),
              SizedBox(height: 8),
              Text('• #test - Load test messages'),
              Text('• #demo_conversation - Start demo conversation'),
              Text('• #server_responses - Load predefined responses'),
              Text('• start - Begin smoking cessation program'),
              Text('• exit - Exit the program'),
              SizedBox(height: 16),
              Text('Just type your message and press send to interact with the QuitTXT system.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showServerUrlDialog(BuildContext context, DashChatProvider dashChatProvider) {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Server URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://your-server.ngrok.io/scheduler/mobile-app',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the ngrok URL or server endpoint for the Dash messaging system.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  // Update server URL in DashMessagingService
                  dashChatProvider.updateServerUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL updated to: $url')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dash Messaging'),
        actions: [
          // Add help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Show help',
            onPressed: () => _showHelpDialog(context),
          ),
          // Add action to trigger the interactive demo conversation
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Start demo conversation',
                onPressed: () {
                  dashChatProvider.sendMessage('#demo_conversation');
                },
              );
            },
          ),
          // Add action to trigger custom JSON responses
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: 'Load custom JSON responses',
            onPressed: _processCustomJson,
          ),
          // Add action to trigger predefined server responses
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.message),
                tooltip: 'Load predefined server responses',
                onPressed: () {
                  dashChatProvider.sendMessage('#server_responses');
                },
              );
            },
          ),
          // Add action to trigger test messages
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.science),
                tooltip: 'Load test messages',
                onPressed: () {
                  dashChatProvider.sendMessage('#test');
                },
              );
            },
          ),
          // Add action to update server URL
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.cloud_sync),
                tooltip: 'Update server URL',
                onPressed: () {
                  _showServerUrlDialog(context, dashChatProvider);
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // Use Consumer to listen to ChatProvider messages via DashChatProvider
            child: Consumer<DashChatProvider>(
              builder: (context, dashChatProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (dashChatProvider.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });

                if (dashChatProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (dashChatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Try sending "start" to begin or "#test" for sample messages.'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: dashChatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = dashChatProvider.messages[index];
                    
                    if (message.type == MessageType.quickReply && 
                        message.suggestedReplies != null && 
                        message.suggestedReplies!.isNotEmpty) {
                      return Column(
                        children: [
                          if (message.content.isNotEmpty)
                            ChatMessageWidget(message: message),
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
                      return ChatMessageWidget(message: message);
                    }
                  },
                );
              },
            ),
          ),
          // Keep the message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<DashChatProvider>(
              builder: (context, dashChatProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message... (try "start" or "#test")',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !dashChatProvider.isSendingMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: dashChatProvider.isSendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: dashChatProvider.isSendingMessage
                          ? null
                          : _sendMessage,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 