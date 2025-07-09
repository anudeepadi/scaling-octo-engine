import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).translate('please_enter_email');
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context).translate('invalid_email');
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate('please_enter_password');
    }
    
    if (value.length < 6) {
      return AppLocalizations.of(context).translate('password_too_short');
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate('please_enter_password');
    }
    
    if (value != _passwordController.text) {
      return AppLocalizations.of(context).translate('password_mismatch');
    }
    
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
      );

      if (!success && mounted) {
        final errorMessage = authProvider.error ?? AppLocalizations.of(context).translate('auth_error');
        _showErrorDialog(errorMessage);
      } else if (success && mounted) {
        // Registration successful, navigate back to login or home
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.signInWithGoogle();

    if (!success && mounted) {
      final errorMessage = authProvider.error ?? 'Google sign-in failed';
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    final localizations = AppLocalizations.of(context);
    
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(localizations.translate('error')),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('ok')),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.translate('error')),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('ok')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.quitxtGreen, // Green background
      appBar: AppBar(
        backgroundColor: AppTheme.quitxtPurple, // Purple header
        title: Text(localizations.translate('app_title')),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QuitTXT Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.quitxtBlack,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'QUITXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Registration Card
                  Card(
                    elevation: 8,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFFAFAFA)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Create Account Text
                              Text(
                                localizations.translate('register_title'),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.quitxtTeal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join QuitTXT to start your smoke-free journey',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              
                              // Full Name Field
                              TextFormField(
                                controller: _fullNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: localizations.translate('full_name_hint'),
                                  hintText: 'Enter your full name',
                                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.quitxtTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.quitxtTeal, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return localizations.translate('please_enter_name');
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: localizations.translate('email_hint'),
                                  hintText: 'Enter your email address',
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.quitxtTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.quitxtTeal, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 20),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: localizations.translate('password_hint'),
                                  hintText: 'Create a strong password',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.quitxtTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.quitxtTeal, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: AppTheme.quitxtTeal,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 20),
                              
                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: localizations.translate('confirm_password_hint'),
                                  hintText: 'Confirm your password',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.quitxtTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.quitxtTeal, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: AppTheme.quitxtTeal,
                                    ),
                                    onPressed: _toggleConfirmPasswordVisibility,
                                  ),
                                ),
                                validator: _validateConfirmPassword,
                              ),
                              const SizedBox(height: 32),
                              
                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.quitxtTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppTheme.quitxtTeal.withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    localizations.translate('register_button'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Divider with "OR"
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Google Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _handleGoogleSignIn,
                                  icon: Image.asset(
                                    'assets/images/google_logo.png',
                                    height: 20,
                                    width: 20,
                                    errorBuilder: (ctx, obj, _) => const Icon(Icons.g_mobiledata, size: 20),
                                  ),
                                  label: Text(
                                    'Continue with Google',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Already have account link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localizations.translate('already_have_account'),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      localizations.translate('sign_in_link'),
                                      style: const TextStyle(
                                        color: AppTheme.quitxtTeal,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.isLoading) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.quitxtTeal),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating your account...',
                                style: TextStyle(
                                  color: AppTheme.quitxtTeal,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 