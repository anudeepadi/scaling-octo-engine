import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/quick_reply.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/dash_chat_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/media_picker_service.dart';
import '../services/dash_messaging_service.dart';
import '../services/gif_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_reply_widget.dart';
import '../widgets/quit_day_debug_panel.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import '../utils/debug_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
        DebugConfig.debugPrint(
            'HomeScreen: Linked DashChatProvider and ChatProvider.');
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

    DebugConfig.debugPrint(
        '[SendMessage] Sending message with ID: ${DateTime.now().millisecondsSinceEpoch}');

    final dashChatProvider = context.read<DashChatProvider>();

    // FIXED: Don't add message to ChatProvider immediately
    // Let DashMessagingService handle adding the message with proper timestamp ordering
    // This prevents duplicate messages and ensures chronological order

    // Send message to the Dash backend - this will handle adding to UI via Firebase
    dashChatProvider.sendMessage(text);

    _messageController.clear();
    _scrollToBottom();
  }

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
  Future<void> _pickMediaFromSource(MediaSource source) async {
    final result = await MediaPickerService.pickMedia(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4'],
      source: source,
    );

    if (result != null && result.files.isNotEmpty && mounted) {
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
          color: AppTheme.surfaceWhite,
        ),
        child: Column(
          children: [
            // Modern header section
            Container(
              padding: const EdgeInsets.only(
                  top: 60, bottom: 32, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.08),
                    AppTheme.wellnessGreen.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern profile section
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.wellnessGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logos/avatar high rez.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // User info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowSubtle,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      userProfileProvider.displayName ??
                          authProvider.currentUser?.displayName ??
                          authProvider.currentUser?.email ??
                          'Welcome to your health journey',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Modern menu items
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Profile item
                    _buildModernMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      subtitle: 'Manage your account',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // Chat item
                    _buildModernMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Chat',
                      subtitle: 'Your health conversations',
                      onTap: () {
                        Navigator.pop(context);
                      },
                      isActive: true,
                    ),

                    const SizedBox(height: 8),

                    // Help item
                    _buildModernMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help',
                      subtitle: 'Quick keywords & support',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HelpScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // About item
                    _buildModernMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'App information',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutScreen()),
                        );
                      },
                    ),

                    const Spacer(),

                    // Exit item (at bottom)
                    _buildModernMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Exit the app',
                      isDestructive: true,
                      onTap: () async {
                        Navigator.pop(context);

                        // Show modern confirmation dialog
                        bool confirmLogout = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                content: const Text(
                                  'Are you sure you want to sign out of your account?',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: AppTheme.errorSoft,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirmLogout && mounted) {
                          await context.read<AuthProvider>().signOut();
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive ? AppTheme.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppTheme.errorSoft.withValues(alpha: 0.1)
                        : isActive
                            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                            : AppTheme.surfaceGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? AppTheme.errorSoft
                        : isActive
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? AppTheme.errorSoft
                              : AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderLight,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowSubtle,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      hintStyle: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isComposing
                      ? LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _isComposing ? null : AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isComposing
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isComposing
                        ? () => _handleSubmitted(_messageController.text)
                        : null,
                    child: Icon(
                      Icons.send_rounded,
                      color:
                          _isComposing ? Colors.white : AppTheme.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/logos/Quitxt.png',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'Quitxt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              );
            },
          ),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  color: AppTheme.backgroundSecondary,
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
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.quitxtTeal.withValues(alpha: 0.1),
                                  AppTheme.quitxtPurple.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Icon(
                              Icons.psychology,
                              size: 60,
                              color: AppTheme.quitxtTeal,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to Quitxt! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your personal smoking cessation assistant',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppTheme.quitxtTeal.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'Start your journey to a smoke-free life',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.quitxtTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show quick reply buttons for ALL poll messages, not just the most recent one
                  DebugConfig.debugPrint(
                      '🔍 HomeScreen: Analyzing ${dashChatProvider.messages.length} messages for quick replies');

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: dashChatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = dashChatProvider.messages[index];

                      // Check if this message has quick replies - show for ALL poll messages
                      final shouldShowQuickReplies =
                          message.type == MessageType.quickReply &&
                              message.suggestedReplies != null &&
                              message.suggestedReplies!.isNotEmpty;

                      DebugConfig.debugPrint(
                          '🔍 HomeScreen: Message $index: type=${message.type}, hasReplies=${message.suggestedReplies?.isNotEmpty}, shouldShow=$shouldShowQuickReplies');

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
                                      QuickReply(text: value, value: value));
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
                                  QuickReply(text: value, value: value));
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
          // Debug panel for testing quit days (only shows in debug mode)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return QuitDayDebugPanel(
                userId: authProvider.currentUser?.uid,
                serverUrl: DashMessagingService().hostUrl,
              );
            },
          ),
        ],
      ),
    );
  }
}
