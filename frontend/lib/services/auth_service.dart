import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Add timeout to handle network issues
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );
      
      return AuthResult(
        success: true,
        user: result.user,
        message: 'Sign in successful',
      );
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection and try again.';
          break;
        default:
          errorMessage = 'Sign in failed. Please try again.';
      }
      
      return AuthResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      print('Auth service error details: $e');
      String errorMessage = 'An unexpected error occurred. Please try again.';
      
      // Check for network-related errors
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      return AuthResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Create account with email and password
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      return AuthResult(
        success: true,
        user: result.user,
        message: 'Account created successfully',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Account creation failed. Please try again.';
      }

      return AuthResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Reset password
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Delete current user
  Future<void> deleteUser() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      await user.delete();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Please sign in again before deleting your account.';
          break;
        default:
          errorMessage = 'Failed to delete account. Please try again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Reset password (Legacy method - returns AuthResult)
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent. Check your inbox.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Verify Firebase token with backend
  Future<bool> verifyWithBackend() async {
    try {
      if (currentUser == null) return false;
      
      String? token = await currentUser!.getIdToken();
      if (token == null) return false;

      // Test backend connection
      return await ApiService.testConnection();
    } catch (e) {
      print('Error verifying with backend: $e');
      return false;
    }
  }
}

/// Auth result model
class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}