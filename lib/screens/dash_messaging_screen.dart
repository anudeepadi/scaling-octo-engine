import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
// Remove Cupertino import if not used elsewhere
// import 'package:flutter/cupertino.dart';
// Remove Platform import if not used elsewhere
// import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:firebase_auth/firebase_auth.dart'; // Add Auth import
import '../models/chat_message.dart';
import '../models/quick_reply.dart'; // Import the QuickReply model
import '../providers/dash_chat_provider.dart'; // Import DashChatProvider
// Remove DashMessagingService import
// import '../services/dash_messaging_service.dart';
// Remove AuthProvider import if not used elsewhere after changes
// import '../providers/auth_provider.dart';
import '../widgets/chat_message_widget.dart';
// Remove Provider import if not used elsewhere after changes
// import 'package:provider/provider.dart';

class DashMessagingScreen extends StatefulWidget {
  const DashMessagingScreen({Key? key}) : super(key: key);

  @override
  _DashMessagingScreenState createState() => _DashMessagingScreenState();
}

class _DashMessagingScreenState extends State<DashMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Add flag to prevent double message sending
  bool _isSendingMessage = false;

  // Add Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Stream<QuerySnapshot>? _messageStream;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _setupMessageStream();
  }

  void _setupMessageStream() {
    if (_currentUser != null) {
      _messageStream = _firestore
          .collection('messages')
          .doc(_currentUser!.uid)
          .collection('messages')
          .orderBy('timestamp', descending: false) // Order by timestamp
          .snapshots();
      // Add listener to scroll down when new messages arrive
      _messageStream?.listen((_) => _scrollToBottom(isDelayed: true));
    } else {
      print("DashMessagingScreen: User not logged in.");
      // Optionally handle the case where the user is not logged in
    }
  }

  Future<void> _sendMessage() async {
    // Guard against double message sending
    if (_isSendingMessage) {
      print("Already sending a message, ignoring duplicate send request");
      return;
    }
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUser == null) return;
    
    // Set flag to prevent double sending
    _isSendingMessage = true;
    
    try {
      _messageController.clear();

      // Use DashChatProvider to send message instead of directly adding to Firestore
      // This fixes the double message issue
      final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);
      await dashChatProvider.sendMessage(messageText);
    } catch (e) {
      print("Error sending message: $e");
    } finally {
      // Reset flag when done
      _isSendingMessage = false;
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

  @override
  Widget build(BuildContext context) {
    // Get the DashChatProvider instance
    final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);

    // Potentially get user again if Auth state changes? Or rely on initial state.
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      // Handle user not logged in UI
      return Scaffold(
        appBar: AppBar(title: const Text('Dash Messaging')),
        body: const Center(child: Text('Please log in to view messages.')),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Dash Messaging'),
        actions: [
          // Add action to trigger test messages
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Load test messages',
            onPressed: () {
              dashChatProvider.sendMessage('#test');
            },
          ),
          // Add action to update server URL
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Update server URL',
            onPressed: () {
              _showServerUrlDialog(context, dashChatProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // Use StreamBuilder to listen to Firestore
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Try sending "#test" to see sample messages.'));
                }
                if (snapshot.hasError) {
                  print("Firestore Stream Error: ${snapshot.error}");
                  return const Center(child: Text('Error loading messages.'));
                }

                // Map Firestore documents to ChatMessage objects
                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;

                  // Determine content based on sender
                  final isServerMessage = data['source'] == 'server';
                  final content = data[isServerMessage ? 'messageBody' : 'content'] ?? '';

                  // Extract quick replies (answers)
                  List<QuickReply>? suggestedReplies;
                  if (data.containsKey('answers') && data['answers'] is List) {
                    final answers = List<String>.from(data['answers']);
                    suggestedReplies = answers.map((text) => QuickReply(text: text, value: text)).toList();
                  }

                  return ChatMessage(
                    id: doc.id,
                    content: content, // Use the determined content
                    isMe: data['senderId'] == _currentUser?.uid, // Check if message is from current user
                    timestamp: timestamp?.toDate() ?? DateTime.now(), // Handle null timestamp
                    suggestedReplies: suggestedReplies, // Assign extracted replies
                    type: data.containsKey('type') && data['type'] is int
                          ? MessageType.values[data['type']]
                          : MessageType.text, // Default or handle error
                    status: data.containsKey('status') && data['status'] is int
                          ? MessageStatus.values[data['status']]
                          : MessageStatus.sent, // Default or handle error
                    // Add other fields as necessary from your data model
                    // e.g., senderName, senderPhotoUrl etc. if stored
                  );
                }).toList();

                // Use ListView.builder with the mapped messages
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatMessageWidget(
                      message: message,
                    );
                  },
                );
              },
            ),
          ),
          // Keep the message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message... (try "#test" for sample messages)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
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

  // Method to show dialog for updating server URL
  void _showServerUrlDialog(BuildContext context, DashChatProvider provider) {
    final TextEditingController urlController = TextEditingController();
    urlController.text = "https://f2f4-3-17-141-5.ngrok-free.app";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'Enter server URL',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Current server: ngrok endpoint'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                try {
                  Navigator.pop(context);
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updating server URL...')),
                  );
                  
                  await provider.updateHostUrl(newUrl);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server URL updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating server URL: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
} 