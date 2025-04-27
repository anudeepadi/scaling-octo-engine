import 'package:flutter/material.dart';

/// Utility class to hold and provide access to the current BuildContext
/// This is useful for accessing BuildContext from non-widget classes
class ContextHolder {
  static BuildContext? _context;

  static BuildContext? get currentContext => _context;

  static void setContext(BuildContext context) {
    _context = context;
  }
}