import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/debug_config.dart';

// Update class to use Firebase Authentication
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Get Firebase Auth instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
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
    DebugConfig.debugPrint('AuthProvider: Initializing - User: ${_user?.uid}');
  }

  // Listener for auth state changes
  void _onAuthStateChanged(User? user) {
    _user = user;
    DebugConfig.debugPrint('AuthProvider: Auth State Changed - User: ${_user?.uid}');
    _isLoading = false; // Reset loading state on change
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use Firebase sign in with retry logic for network issues
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // _onAuthStateChanged will handle updating state and notifying listeners
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      _error = _getDetailedFirebaseErrorMessage(e);
      DebugConfig.debugPrint('AuthProvider: SignIn Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false; // Indicate failure
    } catch (e) {
      _error = _getNetworkErrorMessage(e);
      DebugConfig.debugPrint('AuthProvider: SignIn Unexpected Error - $e');
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
      
      // Update display name with the provided username
      if (username.isNotEmpty) {
        await userCredential.user?.updateDisplayName(username);
        // Reload user to get updated profile
        await userCredential.user?.reload();
        _user = _auth.currentUser;
      }

      // _onAuthStateChanged will handle updating state
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Sign up failed.';
       DebugConfig.debugPrint('AuthProvider: SignUp Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false; // Indicate failure
    } catch (e) {
       _error = 'An unexpected error occurred during sign up.';
       DebugConfig.debugPrint('AuthProvider: SignUp Unexpected Error - $e');
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
       DebugConfig.debugPrint('AuthProvider: SignOut Unexpected Error - $e');
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
      // First check if user is already signed in to Google
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      // If no current user, trigger the authentication flow
      currentUser ??= await _googleSignIn.signIn();
      
      if (currentUser == null) {
        // User canceled the sign-in process
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await currentUser.authentication;

      // Validate that we got the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _error = 'Failed to get Google authentication tokens.';
        DebugConfig.debugPrint('AuthProvider: Missing Google tokens - AccessToken: ${googleAuth.accessToken != null}, IdToken: ${googleAuth.idToken != null}');
        await _googleSignIn.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      DebugConfig.debugPrint('AuthProvider: Attempting Firebase sign in with Google credential');
      
      // Sign in to Firebase with the Google user credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      DebugConfig.debugPrint('AuthProvider: Google SignIn successful - User: ${userCredential.user?.uid}');
      
      // Success - _onAuthStateChanged will handle the rest
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e);
      DebugConfig.debugPrint('AuthProvider: Google SignIn FirebaseAuthException - ${e.code}: ${e.message}');
      // Clean up Google Sign-In state on error
      await _googleSignIn.signOut();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during Google sign in: $e';
      DebugConfig.debugPrint('AuthProvider: Google SignIn Unexpected Error - $e');
      // Clean up Google Sign-In state on error
      await _googleSignIn.signOut();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The Google sign-in credential is invalid.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled for this project.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this credential.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'network-request-failed':
        return 'Network error occurred. Please check your internet connection and try again.';
      default:
        return e.message ?? 'Google sign-in failed. Please try again.';
    }
  }

  String _getDetailedFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials provided. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || 
        errorString.contains('timeout') || 
        errorString.contains('connection') ||
        errorString.contains('resolve')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }
    return 'An unexpected error occurred. Please try again.';
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
      DebugConfig.debugPrint('AuthProvider: UpdateProfile Error - ${e.code}: ${e.message}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
       _error = 'An unexpected error occurred during profile update.';
       DebugConfig.debugPrint('AuthProvider: UpdateProfile Unexpected Error - $e');
       _isLoading = false;
       notifyListeners();
    }
  }
}