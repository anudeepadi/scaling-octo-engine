import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';

import '../providers/dash_chat_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../utils/debug_config.dart';

class DashMessagingScreen extends StatefulWidget {
  const DashMessagingScreen({super.key});

  @override
  DashMessagingScreenState createState() => DashMessagingScreenState();
}

class DashMessagingScreenState extends State<DashMessagingScreen> {
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
        DebugConfig.debugPrint('DashMessagingScreen: Linked DashChatProvider and ChatProvider.');
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
      DebugConfig.debugPrint("Error sending message: $e");
    }
  }

  void _scrollToBottom({bool isDelayed = false}) {
    if (_scrollController.hasClients) {
      void scrollToTask() {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      if (isDelayed) {
        Future.delayed(const Duration(milliseconds: 100), scrollToTask);
      } else {
        scrollToTask();
      }
    }
  }

  void _processCustomJson() {
    // Skip loading demo JSON messages to keep chat completely clean
    DebugConfig.debugPrint('Demo JSON message loading disabled - no hardcoded messages will be loaded');
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
          // Add debug button to show conversation history
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Show conversation history',
                onPressed: () {
                  _showConversationHistoryDialog(context, dashChatProvider);
                },
              );
            },
          ),
          // Add test button for chronological ordering
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Test chronological ordering',
                onPressed: () {
                  dashChatProvider.testChronologicalOrdering();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing chronological ordering... Check console for results.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          // Add test button for message alignment
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.align_horizontal_left),
                tooltip: 'Test message alignment fix',
                onPressed: () {
                  dashChatProvider.debugMessageAlignment();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing message alignment... Check console for results.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          // Add test button for message shifting
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Test message shifting',
                onPressed: () {
                  dashChatProvider.testMessageShifting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testing message shifting... Check console for results.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          // Add toggle button for message shifting
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.toggle_on),
                tooltip: 'Toggle message shifting on/off',
                onPressed: () {
                  dashChatProvider.toggleMessageShifting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toggled message shifting... Check console for status.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
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

                // Calculate the most recent quick reply index once for efficiency
                DebugConfig.debugPrint('🔍 Analyzing ${dashChatProvider.messages.length} messages for quick replies');
                final mostRecentQuickReplyIndex = _findMostRecentQuickReplyIndex(dashChatProvider.messages);
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: dashChatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = dashChatProvider.messages[index];
                    
                    // Only show quick reply buttons for the most recent quick reply message
                    final shouldShowQuickReplies = message.type == MessageType.quickReply && 
                        message.suggestedReplies != null && 
                        message.suggestedReplies!.isNotEmpty &&
                        mostRecentQuickReplyIndex != null &&
                        index == mostRecentQuickReplyIndex;
                    
                    if (shouldShowQuickReplies) {
                      return Column(
                        children: [
                          ChatMessageWidget(message: message),
                          QuickReplyWidget(
                            quickReplies: message.suggestedReplies!,
                            messageId: message.id,
                            onReplySelected: (reply) {
                              dashChatProvider.handleQuickReply(reply);
                              _scrollToBottom();
                            },
                          ),
                        ],
                      );
                    } else {
                      // For all other messages (including older quick reply messages), just show the content
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
          // Add debug button to verify message ordering
          Consumer<DashChatProvider>(
            builder: (context, dashChatProvider, child) {
              return IconButton(
                icon: const Icon(Icons.sort),
                tooltip: 'Verify message ordering',
                onPressed: () {
                  dashChatProvider.verifyMessageOrdering();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message ordering verification started. Check console for results.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showConversationHistoryDialog(BuildContext context, DashChatProvider dashChatProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conversation History'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: dashChatProvider.getConversationHistory(limit: 30),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                
                final history = snapshot.data ?? [];
                
                if (history.isEmpty) {
                  return const Text('No conversation history found.');
                }
                
                return SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final message = history[index];
                      final isUser = message['isUserMessage'] ?? false;
                      final messageText = message['message'] ?? '';
                      final timestamp = message['timestamp'] ?? '';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isUser ? Colors.blue[50] : Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUser ? Icons.person : Icons.smart_toy,
                                    size: 16,
                                    color: isUser ? Colors.blue : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUser ? 'You' : 'Server',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isUser ? Colors.blue : Colors.green,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    timestamp.contains(' ') 
                                        ? timestamp.split(' ')[1].substring(0, 8)
                                        : 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                messageText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
        DebugConfig.debugPrint('🎯 Most recent quick reply at index $i: "${message.content.isEmpty ? "[Quick Reply]" : message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}"');
        return i;
      }
    }
    DebugConfig.debugPrint('🎯 No quick reply messages found in ${messages.length} messages');
    return null; // No quick reply messages found
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 