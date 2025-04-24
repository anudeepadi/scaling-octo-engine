import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_chat_provider.dart';
import '../providers/chat_mode_provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/platform/ios_chat_message_widget.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({Key? key}) : super(key: key);

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[GeminiChatScreen] Build method called.');
    return Consumer<GeminiChatProvider>(
      builder: (context, geminiChatProvider, child) {
        print('[GeminiChatScreen] Consumer builder running. Message count from provider: ${geminiChatProvider.messages.length}');
        return Column(
          children: [
            // --- Add Temporary Debug Text --- 
            Container(
              color: Colors.amber.withOpacity(0.5),
              padding: const EdgeInsets.all(4),
              child: Text(
                 "DEBUG: Provider Msg Count: ${geminiChatProvider.messages.length}", 
                 style: const TextStyle(fontSize: 10, color: Colors.black)
              ),
            ),
            // --- End Debug Text ---
            // Use Flexible instead of Expanded to see if layout calculation changes
            Flexible(
              child: _buildMessageList(geminiChatProvider),
            ),
            if (geminiChatProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CupertinoActivityIndicator(),
              ),
            _buildTextComposer(geminiChatProvider),
          ],
        );
      },
    );
  }

  Widget _buildMessageList(GeminiChatProvider provider) {
    // Schedule scroll after build AND layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        // Use a short delay to give layout a chance to fully settle
        Future.delayed(const Duration(milliseconds: 50), () {
           if (_scrollController.hasClients) { // Check again after delay
               final targetScroll = _scrollController.position.maxScrollExtent;
               print("[GeminiChatScreen.Scroll] Scrolling to: $targetScroll");
              _scrollController.animateTo(
                targetScroll,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
           }
        });
      }
    });

    print("[GeminiChatScreen._buildMessageList] ListView itemCount: ${provider.messages.length}"); // Add log here
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        print('[GeminiChatScreen.itemBuilder] Building item index: $index, Message ID: ${message.id}, Content: "${message.content.substring(0, (message.content.length > 20 ? 20 : message.content.length))}..."');
        
        // --- REMOVE Temporary Text widget --- 
        // return Container(
        //    key: ValueKey(message.id), // Keep the key
        //    alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        //    padding: const EdgeInsets.all(8.0),
        //    child: Container(
        //      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //      color: message.isMe ? Colors.blue[100] : Colors.grey[300],
        //      child: Text(
        //         "${message.isMe ? 'Me:' : 'Gemini:'} ${message.content}", 
        //         style: const TextStyle(color: Colors.black)
        //      ),
        //    )
        // );
        // --- End REMOVE ---

        // --- RESTORE Original complex widget logic --- 
        // Handle quick reply messages separately
        if (message.type == MessageType.quickReply) {
          // Note: _buildQuickReplies itself might need a key if issues persist
          return _buildQuickReplies(message.quickReplies ?? [], provider);
        }
        
        // Use platform-specific message widget with unique keys
        return Platform.isIOS
            ? IosChatMessageWidget(
                key: ValueKey(message.id), // Add key
                message: message
              )
            : ChatMessageWidget(
                key: ValueKey(message.id), // Add key
                message: message
              );
         // --- End RESTORE ---
      },
    );
  }

  Widget _buildQuickReplies(List<QuickReply> replies, GeminiChatProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: CupertinoColors.systemBlue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              child: Text(
                reply.text,
                style: const TextStyle(fontSize: 14),
              ),
              onPressed: () {
                provider.sendMessage(reply.value);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextComposer(GeminiChatProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_outlined),
                onPressed: () async {
                  // Show GIF picker
                  await _pickGif(provider);
                },
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: _textController,
                  placeholder: 'Message Gemini...',
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                  onSubmitted: _isComposing ? (text) => _handleSubmitted(text, provider) : null,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: _isComposing
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.arrow_up_circle_fill, 
                          color: CupertinoColors.activeBlue,
                          size: 32,
                        ),
                        onPressed: () => _handleSubmitted(_textController.text, provider),
                      )
                    : CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.mic_fill,
                          color: CupertinoColors.activeBlue,
                          size: 28,
                        ),
                        onPressed: () {
                          // Voice input would be implemented here
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickGif(GeminiChatProvider provider) async {
    try {
      // List of GIFs in the assets folder
      final List<String> gifPaths = [
        'assets/images/AirbendingPrank.gif',
        'assets/images/School Cat Penis Drawing.gif',
        'assets/images/butt.gif',
        'assets/images/dont_touch.gif',
        'assets/images/dork.gif',
        'assets/images/dorky-selfies.gif',
        'assets/images/fanny-of-darkness.gif',
        'assets/images/ill-fart.gif',
        'assets/images/mean-trick.gif',
      ];

      // Show a bottom sheet to select a GIF
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Select a GIF', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gifPaths.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context, gifPaths[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              gifPaths[index],
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ).then((selectedGif) {
        if (selectedGif != null) {
          provider.addGifMessage(selectedGif);
        }
      });
    } catch (e) {
      print('Error picking GIF: $e');
    }
  }

  void _handleSubmitted(String text, GeminiChatProvider provider) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    
    if (text.trim().isNotEmpty) {
      provider.sendMessage(text);
    }
  }
} 