import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../providers/dash_chat_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../services/media_picker_service.dart';
import '../services/gif_service.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

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

    // Link DashChatProvider to ChatProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        final dashProvider = context.read<DashChatProvider>();
        dashProvider.setChatProvider(chatProvider);
        print('HomeScreen: Linked DashChatProvider and ChatProvider.');
      }
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
    final dashChatProvider = context.read<DashChatProvider>();
    
    // Add the user's message to the UI immediately
    chatProvider.addTextMessage(text, isMe: true);

    // Send message to the Dash backend
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.currentUser?.displayName ?? 'User'),
            accountEmail: Text(authProvider.currentUser?.email ?? 'No email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (authProvider.currentUser?.displayName?.isNotEmpty == true
                    ? authProvider.currentUser!.displayName![0]
                    : 'U'),
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.quitxtTeal,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              // Update state and close drawer before navigating
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
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Server Settings'),
            onTap: () {
              // Update state and close drawer before navigating
              setState(() {
                _isDrawerOpen = false;
              });
              Navigator.pop(context);
              
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Close the drawer
              setState(() {
                _isDrawerOpen = false;
              });
              Navigator.pop(context);
              
              // Show confirmation dialog
              bool confirmLogout = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('LOGOUT'),
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
    );
  }

  Widget _buildMessageInput() {
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: localizations.translate('type_message'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
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
          const SizedBox(width: 4),
          FloatingActionButton(
            onPressed: _isComposing
                ? () => _handleSubmitted(_messageController.text)
                : null,
            backgroundColor: AppTheme.quitxtPurple,
            mini: true,
            child: Text(
              localizations.translate('send'), 
              style: const TextStyle(fontSize: 10, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('app_title')),
        backgroundColor: AppTheme.quitxtPurple,
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chatProvider.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });

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
                          // Use the Dash messaging service for quick replies
                          final dashChatProvider = context.read<DashChatProvider>();
                          dashChatProvider.handleQuickReply(
                            QuickReply(text: value, value: value)
                          );
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
    );
  }
}