import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../services/media_picker_service.dart';
import '../services/gif_service.dart';
import '../models/chat_message.dart';
import '../models/gemini_quick_reply.dart';
import '../utils/youtube_helper.dart';
import '../widgets/platform/ios_message_input.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isDrawerOpen = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);

    // Add test Gemini quick replies for debugging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      print('Adding test Gemini quick replies');

      // Add a test message
      chatProvider.addTextMessage('This is a test message from the bot', isMe: false);

      // Add test Gemini quick replies
      List<GeminiQuickReply> testReplies = [
        GeminiQuickReply(text: '👍 Test Reply 1', value: 'Test1'),
        GeminiQuickReply(text: '❓ Test Reply 2', value: 'Test2'),
        GeminiQuickReply(text: '🤔 Test Reply 3', value: 'Test3'),
      ];

      chatProvider.addGeminiQuickReplyMessage(testReplies);
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {
      _isComposing = _messageController.text.isNotEmpty;
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

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    if (YouTubeHelper.isValidYouTubeUrl(text)) {
      chatProvider.sendMedia(text, MessageType.youtube);
    } else {
      chatProvider.addTextMessage(text);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickGif() async {
    // Show a grid of local GIFs in a bottom sheet
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => _buildGifPicker(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => _buildGifPicker(),
      );
    }
  }

  Widget _buildGifPicker() {
    return Material(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Select a GIF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Platform.isIOS ? CupertinoColors.label : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: GifService.getLocalGifs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final gifPaths = snapshot.data ?? [];

                  if (gifPaths.isEmpty) {
                    return const Center(child: Text('No GIFs found'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: gifPaths.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _sendGif(gifPaths[index]);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            gifPaths[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading GIF: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 32),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendGif(String gifPath) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addGifMessage(gifPath);
  }

  Future<void> _pickMedia() async {
    if (Platform.isIOS) {
      // Show iOS-style action sheet
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Select Media'),
          message: const Text('Choose a media source'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickMediaFromSource(MediaSource.camera);
              },
              child: const Text('Take Photo or Video'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickMediaFromSource(MediaSource.gallery);
              },
              child: const Text('Choose from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      // Show Android-style bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const SizedBox(
                    width: 24,
                    child: Icon(Icons.camera_alt),
                  ),
                  title: const Text('Take Photo or Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMediaFromSource(MediaSource.camera);
                  },
                ),
                ListTile(
                  leading: const SizedBox(
                    width: 24,
                    child: Icon(Icons.photo_library),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMediaFromSource(MediaSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _pickMediaFromSource(MediaSource source) async {
    final result = await MediaPickerService.pickMedia(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4'],
      source: source,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path;

      if (path != null) {
        final chatProvider = context.read<ChatProvider>();
        if (MediaPickerService.isVideoFile(path)) {
          chatProvider.sendMedia(path, MessageType.video);
        } else if (MediaPickerService.isGifFile(path)) {
          chatProvider.sendMedia(path, MessageType.gif);
        } else if (MediaPickerService.isImageFile(path)) {
          chatProvider.sendMedia(path, MessageType.image);
        }
        _scrollToBottom();
      }
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chat History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _createNewChat,
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatProvider.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = chatProvider.conversations[index];
                    final isActive = conversation.id == chatProvider.currentConversationId;

                    return ListTile(
                      leading: SizedBox(
                        width: 24,
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: isActive ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      title: Text(
                        conversation.name,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      subtitle: conversation.lastMessagePreview != null
                          ? Text(
                              conversation.lastMessagePreview!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            )
                          : null,
                      onTap: () {
                        // Switch to this conversation
                        chatProvider.switchConversation(conversation.id);
                        
                        // Close the drawer on mobile
                        setState(() => _isDrawerOpen = false);
                      },
                      trailing: isActive
                          ? IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showConversationOptions(conversation),
                              iconSize: 20,
                            )
                          : null,
                      selected: isActive,
                      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _createNewChat() {
    // Show dialog to create a new chat
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('New Chat'),
          content: CupertinoTextField(
            placeholder: 'Enter chat name',
            controller: TextEditingController(text: 'New Chat'),
            autofocus: true,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final controller = context.findAncestorWidgetOfExactType<CupertinoTextField>()?.controller;
                final name = controller?.text.trim() ?? 'New Chat';
                
                if (name.isNotEmpty) {
                  Provider.of<ChatProvider>(context, listen: false).createNewConversation(name);
                }
                
                Navigator.of(context).pop();
              },
              isDefaultAction: true,
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } else {
      final controller = TextEditingController(text: 'New Chat');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Chat Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                
                if (name.isNotEmpty) {
                  Provider.of<ChatProvider>(context, listen: false).createNewConversation(name);
                }
                
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    }
  }
  
  void _showConversationOptions(dynamic conversation) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(conversation.name),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _renameConversation(conversation);
              },
              child: const Text('Rename'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _clearConversation();
              },
              child: const Text('Clear Chat'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameConversation(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
            ),
          ],
        ),
      );
    }
  }
  
  void _renameConversation(dynamic conversation) {
    final controller = TextEditingController(text: conversation.name);
    
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Rename Chat'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final name = controller.text.trim();
                
                if (name.isNotEmpty) {
                  Provider.of<ChatProvider>(context, listen: false)
                    .renameConversation(conversation.id, name);
                }
                
                Navigator.of(context).pop();
              },
              isDefaultAction: true,
              child: const Text('Rename'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename Chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Chat Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                
                if (name.isNotEmpty) {
                  Provider.of<ChatProvider>(context, listen: false)
                    .renameConversation(conversation.id, name);
                }
                
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        ),
      );
    }
  }
  
  void _clearConversation() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearChatHistory();
  }
  
  void _deleteConversation(dynamic conversation) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<ChatProvider>(context, listen: false)
                  .deleteConversation(conversation.id);
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<ChatProvider>(context, listen: false)
                  .deleteConversation(conversation.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessageInput() {
    if (Platform.isIOS) {
      return IosMessageInput(
        controller: _messageController,
        onSubmitted: _handleSubmitted,
        onPickMedia: _pickMedia,
        onPickGif: _pickGif,
        isComposing: _isComposing,
      );
    }

    // Default Android/Material implementation
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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickMedia,
            tooltip: 'Attach media',
          ),
          TextButton(
            onPressed: _pickGif,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(40, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'GIF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
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
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: _isComposing ? Theme.of(context).primaryColor : Colors.grey,
            onPressed: _isComposing
                ? () => _handleSubmitted(_messageController.text)
                : null,
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (context) => const ProfileScreen())
          : MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simplified build method without User object
    final appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: const Text('RCS Demo App'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(_isDrawerOpen ? CupertinoIcons.sidebar_left : CupertinoIcons.line_horizontal_3),
              onPressed: () {
                setState(() {
                  _isDrawerOpen = !_isDrawerOpen;
                });
              },
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.profile_circled),
              onPressed: _navigateToProfile,
            ),
          )
        : AppBar(
            title: const Text('RCS Demo App'),
            leading: IconButton(
              icon: Icon(_isDrawerOpen ? Icons.menu_open : Icons.menu),
              onPressed: () {
                setState(() {
                  _isDrawerOpen = !_isDrawerOpen;
                });
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: _navigateToProfile,
              ),
            ],
          );

    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: appBar as CupertinoNavigationBar,
            child: _buildBody(),
          )
        : Scaffold(
            appBar: appBar as PreferredSizeWidget,
            body: _buildBody(),
          );
  }

  Widget _buildBody() {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isDrawerOpen ? 250 : 0,
              child: _isDrawerOpen ? Material(
                type: MaterialType.card,
                child: _buildSidebar(),
              ) : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (chatProvider.messages.isNotEmpty) {
                            _scrollToBottom();
                          }
                        });
                        print('Rendering chat with ${chatProvider.messages.length} messages');

                        // Check for any Gemini quick reply messages
                        bool hasGeminiReplies = chatProvider.messages.any((msg) =>
                          msg.type == MessageType.geminiQuickReply
                        );
                        print('Has Gemini quick replies: $hasGeminiReplies');

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            return ChatMessageWidget(
                              message: chatProvider.messages[index],
                              onReplyTap: () => _scrollToBottom(),
                              onReactionAdd: (value) {
                                if (value.isNotEmpty) {
                                  chatProvider.sendQuickReply(value);
                                }
                                _scrollToBottom();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}