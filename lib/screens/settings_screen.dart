import 'package:flutter/material.dart';
import '../utils/env_switcher.dart';
import '../utils/platform_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Environment _currentEnv = Environment.development;
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current environment
      _currentEnv = await EnvSwitcher.getCurrentEnvironment();

      // Set the server URL textfield
      _serverUrlController.text = dotenv.env['SERVER_URL'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchEnvironment(Environment env) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await EnvSwitcher.switchEnvironment(env);
      setState(() {
        _currentEnv = env;
      });
      
      // Update the server URL text field
      _serverUrlController.text = dotenv.env['SERVER_URL'] ?? '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${env.toString()} environment')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching environment: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomServerUrl() async {
    final newUrl = _serverUrlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hostUrl', newUrl);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server URL saved: $newUrl')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving server URL: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Environment Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Environment selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Environment:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<Environment>(
                            title: const Text('Development (Local)'),
                            value: Environment.development,
                            groupValue: _currentEnv,
                            onChanged: (value) {
                              if (value != null) {
                                _switchEnvironment(value);
                              }
                            },
                          ),
                          RadioListTile<Environment>(
                            title: const Text('Production (Remote)'),
                            value: Environment.production,
                            groupValue: _currentEnv,
                            onChanged: (value) {
                              if (value != null) {
                                _switchEnvironment(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Current server URL
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Server URL:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _serverUrlController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter server URL',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _saveCustomServerUrl,
                            child: const Text('Save Custom URL'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Current configuration info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Configuration:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text('Environment: ${dotenv.env['ENV'] ?? 'Not set'}'),
                          Text('Original Server URL: ${dotenv.env['SERVER_URL'] ?? 'Not set'}'),
                          if (Platform.isAndroid)
                            Text('Transformed URL (Android): ${PlatformUtils.transformLocalHostUrl(dotenv.env['SERVER_URL'] ?? 'Not set')}'),
                          Text('Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : Platform.operatingSystem}'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // App restart needed warning
                  Card(
                    color: Colors.amber.shade100,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You may need to restart the app for some changes to take effect.',
                              style: TextStyle(color: Colors.black87),
                            ),
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

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
} 