import 'package:flutter/foundation.dart';

// Simplified AuthProvider with no Firebase dependencies
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = true; // Set to true by default in demo mode
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => 'demo-user';

  AuthProvider() {
    print('AuthProvider: Initializing in demo mode');
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Always succeed in demo mode
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Always succeed in demo mode
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _isLoading = false;
    notifyListeners();
  }
}