import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File, Platform;
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/media_picker_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _profileImagePath;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    // In demo mode, set a default display name
    _displayNameController.text = 'Demo User';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await MediaPickerService.pickMedia(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        source: MediaSource.gallery,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;

        if (path != null) {
          setState(() {
            _profileImagePath = path;
            _imageChanged = true;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate updating profile
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showSuccessDialog('Profile updated successfully');
        }
      } catch (e) {
        _showErrorDialog('Failed to update profile: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signOut() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorDialog('Failed to sign out: ${e.toString()}');
    }
  }

  void _clearChatHistory() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.clearChatHistory();
      if (mounted) {
        _showSuccessDialog('Chat history cleared successfully');
      }
    } catch (e) {
      _showErrorDialog('Failed to clear chat history: ${e.toString()}');
    }
  }

  void _showSuccessDialog(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileImage(ThemeData theme) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: _profileImagePath == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: theme.primaryColor,
                  )
                : _profileImagePath!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          _profileImagePath!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 50,
                              color: theme.primaryColor,
                            );
                          },
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          File(_profileImagePath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 50,
                              color: theme.primaryColor,
                            );
                          },
                        ),
                      ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // In demo mode, use a hardcoded email
    const email = 'demo@example.com';

    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Profile'),
            ),
            child: _buildContent(theme, email),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: _buildContent(theme, email),
          );
  }

  Widget _buildContent(ThemeData theme, String email) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImage(theme),
              const SizedBox(height: 24),
              Text(
                email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              if (Platform.isIOS)
                CupertinoFormSection(
                  header: const Text('Account Information'),
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: _displayNameController,
                      prefix: const Text('Display Name'),
                      placeholder: 'Enter your display name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              if (Platform.isIOS)
                Column(
                  children: [
                    CupertinoButton.filled(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : const Text('Update Profile'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _clearChatHistory,
                      child: const Text('Clear Chat History'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _signOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Update Profile'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _clearChatHistory,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Clear Chat History'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}