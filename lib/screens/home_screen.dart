import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/service_provider.dart';
import '../providers/dash_chat_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/media_picker_service.dart';
import '../services/gif_service.dart';
import '../services/dash_messaging_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import 'profile_screen.dart';
import 'clean_chat_screen.dart';
import '../utils/debug_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isDrawerOpen = false;
  bool _isComposing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_handleTextChange);

    // Link DashChatProvider to ChatProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        final dashProvider = context.read<DashChatProvider>();
        dashProvider.setChatProvider(chatProvider);
        DebugConfig.debugPrint('HomeScreen: Linked DashChatProvider and ChatProvider.');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        DebugConfig.debugPrint('App resumed - checking for new messages');
        // Refresh messages when app comes back to foreground
        if (mounted) {
          final dashProvider = context.read<DashChatProvider>();
          dashProvider.refreshMessages();
        }
        break;
      case AppLifecycleState.paused:
        DebugConfig.debugPrint('App paused');
        break;
      case AppLifecycleState.inactive:
        DebugConfig.debugPrint('App inactive');
        break;
      case AppLifecycleState.detached:
        DebugConfig.debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        DebugConfig.debugPrint('App hidden');
        break;
    }
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

    DebugConfig.debugPrint('[SendMessage] Sending message with ID: ${DateTime.now().millisecondsSinceEpoch}');
    
    final dashChatProvider = context.read<DashChatProvider>();
    
    // FIXED: Don't add message to ChatProvider immediately
    // Let DashMessagingService handle adding the message with proper timestamp ordering
    // This prevents duplicate messages and ensures chronological order
    
    // Send message to the Dash backend - this will handle adding to UI via Firebase
    dashChatProvider.sendMessage(text);

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickGif() async {
    // Show a grid of local GIFs in a bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => _buildGifPicker(),
    );
  }

  Widget _buildGifPicker() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Select a GIF',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                            DebugConfig.debugPrint('Error loading GIF: $error');
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
    );
  }

  void _sendGif(String gifPath) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addGifMessage(gifPath);
  }

  Future<void> _pickMedia() async {
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

  Widget _buildDrawer() {
    final authProvider = context.read<AuthProvider>();
    final userProfileProvider = context.watch<UserProfileProvider>();
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B7A3), // Lighter teal
              Color(0xFF009688), // AppTheme.quitxtTeal
              Color(0xFF00796B), // Darker teal
            ],
          ),
        ),
        child: Column(
          children: [
            // Header section with logo and user info
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QuiTXT logo and app name
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Q',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QuiTXT mobile app',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User info
                  Text(
                    'User: ${userProfileProvider.displayName ?? authProvider.currentUser?.displayName ?? authProvider.currentUser?.email ?? 'User'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile item
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      title: const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                        Navigator.pop(context);
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    
                    // Chat item
                    ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      title: const Text(
                        'Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                        Navigator.pop(context);
                        // Already on chat screen, so just close drawer
                      },
                    ),
                    
                    // Exit item
                    ListTile(
                      leading: const Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 24,
                      ),
                      title: const Text(
                        'Exit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () async {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                        Navigator.pop(context);
                        
                        
                        // Show confirmation dialog
                        bool confirmLogout = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Exit'),
                            content: const Text('Are you sure you want to exit?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('EXIT'),
                              ),
                            ],
                          ),
                        ) ?? false;
                        
                        // If confirmed, proceed with logout
                        if (confirmLogout && mounted) {
                          await context.read<AuthProvider>().signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                onSubmitted: _handleSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.quitxtPurple,
              borderRadius: BorderRadius.circular(25),
            ),
            child: MaterialButton(
              onPressed: _isComposing
                  ? () => _handleSubmitted(_messageController.text)
                  : null,
              minWidth: 80,
              height: 45,
              child: const Text(
                'SEND',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('app_title')),
        backgroundColor: AppTheme.quitxtTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isDrawerOpen = true;
            });
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Consumer<DashChatProvider>(
                builder: (context, dashChatProvider, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (dashChatProvider.messages.isNotEmpty) {
                      _scrollToBottom();
                    }
                  });

                  if (dashChatProvider.messages.isEmpty) {
                    return Center(
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
                            'Welcome to QuitTXT',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your conversation will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show quick reply buttons for ALL poll messages, not just the most recent one
                  DebugConfig.debugPrint('🔍 HomeScreen: Analyzing ${dashChatProvider.messages.length} messages for quick replies');
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: dashChatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = dashChatProvider.messages[index];
                      
                      // Check if this message has quick replies - show for ALL poll messages
                      final shouldShowQuickReplies = message.type == MessageType.quickReply && 
                          message.suggestedReplies != null && 
                          message.suggestedReplies!.isNotEmpty;
                      
                      DebugConfig.debugPrint('🔍 HomeScreen: Message ${index}: type=${message.type}, hasReplies=${message.suggestedReplies?.isNotEmpty}, shouldShow=$shouldShowQuickReplies');
                      
                      if (shouldShowQuickReplies) {
                        // For poll messages with quick replies, show both content and buttons
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
                        // For regular messages, just show the content
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
                    },
                  );
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}