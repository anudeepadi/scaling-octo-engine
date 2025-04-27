import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Update class to use Firebase Authentication
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Get Firebase Auth instance
  User? _user; // Hold the current Firebase User

  bool _isLoading = false;
  String? _error;
  // Remove default true for isAuthenticated
  // bool _isAuthenticated = true; 

  bool get isAuthenticated => _user != null; // Check if user object exists
  bool get isLoading => _isLoading;
  String? get error => _error;
  // Return actual Firebase User ID or a placeholder if null
  String get userId => _user?.uid ?? 'anonymous'; 
  // Add currentUser getter
  User? get currentUser => _user;

  AuthProvider() {
    // Listen to authentication state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // Set initial state
    _user = _auth.currentUser; 
    print('AuthProvider: Initializing - User: ${_user?.uid}');
  }

  // Listener for auth state changes
  void _onAuthStateChanged(User? user) {
    _user = user;
    print('AuthProvider: Auth State Changed - User: ${_user?.uid}');
    _isLoading = false; // Reset loading state on change
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use Firebase sign in
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // _onAuthStateChanged will handle updating state and notifying listeners
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Sign in failed.';
      print('AuthProvider: SignIn Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false; // Indicate failure
    } catch (e) {
      _error = 'An unexpected error occurred during sign in.';
      print('AuthProvider: SignIn Unexpected Error - $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use Firebase sign up
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Optionally update display name (username isn't directly part of standard email/pass signup)
      // You might store the username in Firestore linked to the userCredential.user.uid
      // await userCredential.user?.updateDisplayName(username); 

      // _onAuthStateChanged will handle updating state
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Sign up failed.';
       print('AuthProvider: SignUp Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false; // Indicate failure
    } catch (e) {
       _error = 'An unexpected error occurred during sign up.';
       print('AuthProvider: SignUp Unexpected Error - $e');
       _isLoading = false;
       notifyListeners();
       return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null; // Clear previous errors on sign out attempt
    notifyListeners();

    try {
      // Use Firebase sign out
      await _auth.signOut();
      // _onAuthStateChanged will handle updating state
    } catch (e) {
       // Although signOut rarely fails, good practice to catch potential errors
       _error = 'An unexpected error occurred during sign out.';
       print('AuthProvider: SignOut Unexpected Error - $e');
       _isLoading = false; // Ensure loading is false even on error
       notifyListeners();
    }
    // Loading state is reset within _onAuthStateChanged after sign out completes
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If no user was selected (user canceled the sign-in), return false
      if (googleUser == null) {
        _error = 'Google sign-in was canceled.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Get authentication details from Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a credential for Firebase using Google tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with Google credential
      await _auth.signInWithCredential(credential);
      
      // _onAuthStateChanged will handle updating state
      return true;
    } catch (e) {
      _error = 'An error occurred during Google sign-in: ${e.toString()}';
      print('AuthProvider: Google SignIn Error - $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    if (_user == null) {
      _error = "Not signed in.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use Firebase update profile methods
      if (displayName != null) {
        await _user!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }
      // Reload user data to reflect changes immediately if needed, though not strictly required
      // await _user!.reload(); 
      // _user = _auth.currentUser; // Re-assign user if reloaded
       _isLoading = false;
       notifyListeners(); // Notify UI of success/loading finished
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Profile update failed.';
      print('AuthProvider: UpdateProfile Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
       _error = 'An unexpected error occurred during profile update.';
       print('AuthProvider: UpdateProfile Unexpected Error - $e');
       _isLoading = false;
       notifyListeners();
    }
  }
}