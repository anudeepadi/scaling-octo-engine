import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'widget_test.dart' as widget_tests;
import 'models/chat_message_test.dart' as chat_message_model_tests;
import 'widgets/chat_message_widget_test.dart' as chat_message_widget_tests;
import 'basic_functionality_test.dart' as basic_functionality_tests;

void main() {
  group('All Tests', () {
    group('Widget Tests', () {
      widget_tests.main();
    });

    group('Model Tests', () {
      chat_message_model_tests.main();
    });

    group('Widget Component Tests', () {
      chat_message_widget_tests.main();
    });

    group('Basic Functionality Tests', () {
      basic_functionality_tests.main();
    });
  });
}
