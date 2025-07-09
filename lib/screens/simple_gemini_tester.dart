import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Need http for direct API call
import 'dart:convert'; // For jsonEncode/Decode
import '../utils/debug_config.dart';

// --- IMPORTANT: Replace with your new, valid API key securely! ---
// --- DO NOT COMMIT THIS KEY TO VERSION CONTROL ---
const String _geminiApiKey = 'AIzaSyCODVjQ7aIyDAcHXXW3XBiB9quiPwznocs'; 
// --- Example using environment variable (preferred): ---
// const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

class SimpleGeminiTesterScreen extends StatefulWidget {
  const SimpleGeminiTesterScreen({Key? key}) : super(key: key);

  @override
  _SimpleGeminiTesterScreenState createState() =>
      _SimpleGeminiTesterScreenState();
}

class _SimpleGeminiTesterScreenState extends State<SimpleGeminiTesterScreen> {
  final TextEditingController _textController = TextEditingController();
  String _responseText = 'Response will appear here...';
  bool _isLoading = false;
  String? _errorText;

  Future<void> _callGeminiApi() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Please enter some text.';
        _responseText = '';
      });
      return;
    }
     if (_geminiApiKey == 'YOUR_GEMINI_API_KEY') {
       setState(() {
        _errorText = 'ERROR: Please replace YOUR_GEMINI_API_KEY in the code.';
        _responseText = '';
      });
      return;
    }


    setState(() {
      _isLoading = true;
      _responseText = '';
      _errorText = null;
    });

    // Basic implementation similar to GeminiService (adapt model name if needed)
    // Note: This is a simplified text-only implementation.
    const String modelName = 'gemini-1.5-flash'; // Use a currently available model
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_geminiApiKey');

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": _textController.text.trim()}
          ]
        }
      ],
      // Optional: Add generationConfig if needed
      // "generationConfig": { ... } 
    });

    DebugConfig.debugPrint("[SimpleTester] Calling Gemini API: $url");
    DebugConfig.debugPrint("[SimpleTester] Request Body: $requestBody");


    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      DebugConfig.debugPrint("[SimpleTester] API Response Status: ${response.statusCode}");
      DebugConfig.debugPrint("[SimpleTester] API Response Body: ${response.body}");


      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        // Extract the text content - structure might vary slightly based on model/response type
        final candidates = decodedResponse['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
           final content = candidates[0]['content'] as Map<String, dynamic>?;
           if (content != null) {
              final parts = content['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                 final text = parts[0]['text'] as String?;
                 if (text != null) {
                   setState(() {
                     _responseText = text;
                   });
                 } else {
                    throw Exception('Could not extract text from API response part.');
                 }
              } else {
                  throw Exception('Could not extract parts from API response content.');
              }
           } else {
              throw Exception('Could not extract content from API response candidate.');
           }
        } else {
            // Handle cases where response might be blocked (safety reasons)
            final promptFeedback = decodedResponse['promptFeedback'] as Map<String, dynamic>?;
             if (promptFeedback != null && promptFeedback['blockReason'] != null) {
                setState(() {
                 _responseText = 'Response blocked: ${promptFeedback['blockReason']}';
               });
             } else {
               throw Exception('No candidates found and no block reason provided in API response.');
             }
        }

      } else {
        throw Exception('API Error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      DebugConfig.debugPrint("[SimpleTester] Error calling API: $e");
      setState(() {
        _errorText = "Error: $e";
        _responseText = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
       DebugConfig.debugPrint("[SimpleTester] Request Finished.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Gemini API Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter prompt for Gemini',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _callGeminiApi,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send to Gemini'),
            ),
            const SizedBox(height: 20),
            const Text('Response:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _isLoading 
                      ? 'Loading...' 
                      : (_errorText ?? _responseText),
                    style: TextStyle(
                      color: _errorText != null ? Colors.red : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 