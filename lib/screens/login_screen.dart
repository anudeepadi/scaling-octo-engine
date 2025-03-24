import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../providers/auth_provider.dart';
import 'package:gradient_borders/gradient_borders.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSignUp = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      bool success;
      if (_isSignUp) {
        success = await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
        );
      } else {
        success = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      
      if (!success && mounted) {
        final errorMessage = authProvider.error ?? 'Authentication failed';
        _showErrorDialog(errorMessage);
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Platform.isIOS
        ? CupertinoPageScaffold(
            child: _buildContent(theme),
          )
        : Scaffold(
            body: _buildContent(theme),
          );
  }

  Widget _buildContent(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 48),
              if (_isSignUp) _buildUsernameField(),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildToggleButton(),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isLoading) {
                    return Center(
                      child: Platform.isIOS
                          ? const CupertinoActivityIndicator()
                          : const CircularProgressIndicator(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.5),
                  theme.colorScheme.secondary.withOpacity(0.5),
                ],
              ),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.chat_rounded,
            size: 50,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'RCS Demo App',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp ? 'Create your account' : 'Sign in to your account',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    if (Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: CupertinoTextFormFieldRow(
          controller: _usernameController,
          placeholder: 'Username',
          prefix: const Icon(CupertinoIcons.person),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            return null;
          },
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            return null;
          },
        ),
      );
    }
  }

  Widget _buildEmailField() {
    if (Platform.isIOS) {
      return CupertinoTextFormFieldRow(
        controller: _emailController,
        placeholder: 'Email',
        prefix: const Icon(CupertinoIcons.mail),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter an email';
          }
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
      );
    } else {
      return TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter an email';
          }
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      );
    }
  }

  Widget _buildPasswordField() {
    if (Platform.isIOS) {
      return CupertinoTextFormFieldRow(
        controller: _passwordController,
        placeholder: 'Password',
        prefix: const Icon(CupertinoIcons.lock),
        obscureText: !_isPasswordVisible,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (_isSignUp && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        suffix: GestureDetector(
          onTap: _togglePasswordVisibility,
          child: Icon(
            _isPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    } else {
      return TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        obscureText: !_isPasswordVisible,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (_isSignUp && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      );
    }
  }

  Widget _buildSubmitButton() {
    if (Platform.isIOS) {
      return CupertinoButton.filled(
        onPressed: _submitForm,
        child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      );
    } else {
      return ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isSignUp ? 'Sign Up' : 'Sign In',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
  }

  Widget _buildToggleButton() {
    final toggleText = _isSignUp
        ? 'Already have an account? Sign In'
        : 'Don\'t have an account? Sign Up';
        
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: _toggleMode,
        child: Text(toggleText),
      );
    } else {
      return TextButton(
        onPressed: _toggleMode,
        child: Text(toggleText),
      );
    }
  }
}