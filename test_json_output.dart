import 'dart:convert';
import 'package:flutter/material.dart';
import 'lib/services/dash_messaging_service.dart';
import 'lib/utils/debug_config.dart';

/// Simple script to test JSON output printing
/// Run this with: flutter run -d <device_id> test_json_output.dart
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  print('\n======= RCS JSON FORMAT TEST =======\n');
  
  // Sample JSON request structure
  final requestJson = {
    'messageId': 'msg_${DateTime.now().millisecondsSinceEpoch}',
    'userId': 'test-user-123',
    'messageText': 'Hello, this is a test message',
    'fcmToken': 'sample-fcm-token-for-testing-purposes',
    'messageTime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'eventTypeCode': 1,
  };
  
  // Sample JSON response structure
  final responseJson = {
    'messageBody': 'This is a sample server response',
    'isPoll': 'y',
    'questionsAnswers': {
      'Yes': 'yes',
      'No': 'no',
      'Maybe': 'maybe',
      'Not sure': 'not_sure'
    },
    'serverMessageId': 'server-msg-${DateTime.now().millisecondsSinceEpoch}',
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000
  };
  
  // Print JSON with border formatting
  printJsonWithBorder('REQUEST JSON', requestJson);
  print('\n');
  printJsonWithBorder('RESPONSE JSON', responseJson);
  
  // If you want to run in the app context
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JSON Test Output'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Check console for JSON output', 
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Use the DashMessagingService to print a sample
                  final service = DashMessagingService();
                  service.printSampleJsonRequest();
                },
                child: const Text('Print Sample From Service'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Helper function to print JSON with border
void printJsonWithBorder(String label, dynamic jsonData) {
  try {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
    
    print('\n📋 $label:');
    print('╔════════════════════════════════════════════');
    
    // Print each line with a border
    for (var line in prettyJson.split('\n')) {
      print('║ $line');
    }
    
    print('╚════════════════════════════════════════════');
  } catch (e) {
    print('\n📋 $label (raw): ${jsonData.toString()}');
    print('Error formatting JSON: $e');
  }
} 