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
      
      // No need to add to Firestore directly - DashChatProvider will handle that
      // This was causing double messages
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

  void _processCustomJson() {
    // The custom JSON to process with all the server responses
    final jsonString = '''
    {
      "serverResponses": [
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "7e9f2a1b-c3d4-5e6f-7g8h-9i0j1k2l3m4n",
          "messageBody": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking!",
          "timestamp": 1710072000,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "8f0e1d2c-3b4a-5d6e-7f8g-9h0i1j2k3l4m",
          "messageBody": "Welcome to Quitxt from the UT Health Science Center! Congrats on your decision to quit smoking! See why we think you're awesome, Tap pic below https://youtu.be/ZWsR3G0mdJo",
          "timestamp": 1710072100,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "9e0d1c2b-3a4f-5e6d-7c8b-9a0f1e2d3c4b",
          "messageBody": "We'll help you quit smoking with fun messages. By continuing, you agree with our terms of service. If you want to leave the program type EXIT. For more info Tap pic below https://quitxt.org",
          "timestamp": 1710072200,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "0a1b2c3d-4e5f-6g7h-8i9j-0k1l2m3n4o5p",
          "messageBody": "How many cigarettes do you smoke per day?",
          "timestamp": 1710072300,
          "isPoll": true,
          "pollId": 12345,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": {
            "Less than 5": "Less than 5",
            "5-10": "5-10",
            "11-20": "11-20",
            "More than 20": "More than 20"
          }
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
          "messageBody": "Reason #1 to quit smoking while you're young: You'll have more time to enjoy hoverboards and flying cars. https://quitxt.org/sites/quitxt/files/gifs/PreQ6_Hoverboard.gif",
          "timestamp": 1710072400,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1", 
          "serverMessageId": "2b3c4d5e-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
          "messageBody": "Drinking alcohol can trigger cravings for a cigarette and makes it harder for you to quit smoking. Tap pic below https://quitxt.org/binge-drinking",
          "timestamp": 1710072500,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "3c4d5e6f-7g8h-9i0j-1k2l-3m4n5o6p7q8r",
          "messageBody": "Like the Avengers protect the earth, you are protecting your lungs from respiratory diseases and cancer! Stay SUPER and quit smoking! https://quitxt.org/sites/quitxt/files/gifs/App1_Cue1_Avengers.gif",
          "timestamp": 1710072600,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "4d5e6f7g-8h9i-0j1k-2l3m-4n5o6p7q8r9s",
          "messageBody": "Reason #2 to quit smoking while you're young: Add a decade to your life and see the rise of fully automated smart homes; who needs to do chores when robots become a common commodity! https://quitxt.org/sites/quitxt/files/gifs/App1-Motiv2_automated_home.gif",
          "timestamp": 1710072700,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "5e6f7g8h-9i0j-1k2l-3m4n-5o6p7q8r9s0t",
          "messageBody": "Beber alcohol puede provocar los deseos de fumar y te hace más difícil dejar el cigarrillo. Clic el pic abajo https://quitxt.org/spanish/consumo-intensivo-de-alcohol",
          "timestamp": 1710072800,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "6f7g8h9i-0j1k-2l3m-4n5o-6p7q8r9s0t1u",
          "messageBody": "Como los Avengers protegen el planeta, ¡tú estás protegiendo tus pulmones de enfermedades respiratorias y de cáncer! ¡Sigue SUPER y deja de fumar!",
          "timestamp": 1710072900,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "7g8h9i0j-1k2l-3m4n-5o6p-7q8r9s0t1u2v",
          "messageBody": "Razón #2 para dejar de fumar siendo joven: ¡ganarás 10 años de vida y verás el aumento de las casas inteligentes; ¡quién necesita limpiar la casa cuando los robots lo harán por ti! https://quitxt.org/sites/quitxt/files/gifs/preq5_motiv2_automated_esp.gif",
          "timestamp": 1710073000,
          "isPoll": false,
          "pollId": null,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": null
        },
        {
          "recipientId": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
          "serverMessageId": "8h9i0j1k-2l3m-4n5o-6p7q-8r9s0t1u2v3w",
          "messageBody": "¿Cuántos cigarrillos fumas por día?",
          "timestamp": 1710073100,
          "isPoll": true,
          "pollId": 12346,
          "fcmToken": "e-D8y5f8RoOcRgQl4AV18K:APA91bEdH6CwssC17yIKENOuLiW5eOxnE5CaOxqiOkKXdL4ZgnbOAk9s1_EX0w0E4G0c_zn5QD8X7W0-BHGooS2RyBcfHFYl8hfNEwYVcNIEConIJTyeJnhAnxlhD3OwayB6S_yeZXST",
          "questionsAnswers": {
            "Menos de 5": "Menos de 5",
            "5-10": "5-10",
            "11-20": "11-20",
            "Más de 20": "Más de 20"
          }
        }
      ]
    }
    ''';
    
    final dashChatProvider = Provider.of<DashChatProvider>(context, listen: false);
    dashChatProvider.processCustomJsonInput(jsonString);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help - Demo Commands'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Available demo commands:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Play button: Show a complete interactive conversation demo'),
            Text('• List button: Load all predefined server responses'),
            Text('• Message button: Show server responses one by one'),
            Text('• Test button: Show sample test messages'),
            SizedBox(height: 16),
            Text('Message keywords:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Hello/Hi: English greeting'),
            Text('• Hola: Spanish greeting'),
            Text('• I want to quit smoking: Shows poll'),
            Text('• 5-10: Responds to cigarette poll'),
            Text('• Cool/Thanks: Trigger info messages'),
            Text('• EXIT/SALIR: Show exit messages'),
            Text('• #deactivate: Show deactivation message'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          // Add help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Show help',
            onPressed: () => _showHelpDialog(context),
          ),
          // Add action to trigger the interactive demo conversation
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start demo conversation',
            onPressed: () {
              dashChatProvider.sendMessage('#demo_conversation');
            },
          ),
          // Add action to trigger custom JSON responses
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: 'Load custom JSON responses',
            onPressed: _processCustomJson,
          ),
          // Add action to trigger predefined server responses
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Load predefined server responses',
            onPressed: () {
              dashChatProvider.sendMessage('#server_responses');
            },
          ),
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