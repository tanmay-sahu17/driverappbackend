import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _signInError;
  String? _signUpError;
  User? _user;
  Map<String, dynamic>? _driverProfile;

  /// Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get signInError => _signInError;
  String? get signUpError => _signUpError;
  bool get isSignedIn => _user != null;
  Map<String, dynamic>? get driverProfile => _driverProfile;

  /// Initialize auth provider
  AuthProvider() {
    initializeAuth();
  }

  void initializeAuth() {
    // Set initial loading state
    _setLoading(true);
    
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        print('✅ User session restored: ${user.email}');
        _loadDriverProfile();
      } else {
        print('❌ No active user session');
        _driverProfile = null;
      }
      
      // Auth state is now determined, stop loading
      if (_isLoading) {
        _setLoading(false);
      }
      
      notifyListeners();
    });
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Set sign in error
  void _setSignInError(String? error) {
    _signInError = error;
    notifyListeners();
  }

  /// Set sign up error
  void _setSignUpError(String? error) {
    _signUpError = error;
    notifyListeners();
  }

  /// Clear all errors
  void _clearError() {
    _errorMessage = null;
    _signInError = null;
    _signUpError = null;
    notifyListeners();
  }

  /// Clear signin error only
  void clearSignInError() {
    _signInError = null;
    notifyListeners();
  }

  /// Clear signup error only
  void clearSignUpError() {
    _signUpError = null;
    notifyListeners();
  }

  /// Load driver profile
  Future<void> _loadDriverProfile() async {
    try {
      // Here you would typically load the driver profile from your backend
      // For now, we'll just set some basic info
      _driverProfile = {
        'id': _user?.uid,
        'email': _user?.email,
        'displayName': _user?.displayName,
      };
    } catch (e) {
      print('Error loading driver profile: $e');
    }
  }

  /// Check if user session is available (for app startup)
  Future<bool> checkAuthStatus() async {
    try {
      _setLoading(true);
      
      // Firebase automatically restores auth state
      // We just need to check current user
      final user = _authService.currentUser;
      
      if (user != null) {
        _user = user;
        await _loadDriverProfile();
        print('✅ Existing session found for: ${user.email}');
        return true;
      } else {
        print('❌ No existing session found');
        return false;
      }
    } catch (e) {
      print('Error checking auth status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in method
  Future<void> signIn(String email, String password) async {
    _clearError();
    _setLoading(true);

    try {
      print('🔐 Attempting to sign in user: $email');
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.success) {
        _user = result.user;
        await _loadDriverProfile();
        // Clear any existing errors on successful login
        _clearError();
        print('✅ Sign in successful for: $email');
      } else {
        print('❌ Sign in failed: ${result.message}');
        _setSignInError(result.message);
      }
    } catch (e) {
      print('❌ Sign in exception: $e');
      _setSignInError('Sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String driverName,
    required String phoneNumber,
    required String licenseNumber,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // First register with backend
      final backendResult = await ApiService.signUp(
        email: email,
        password: password,
        driverName: driverName,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
      );

      if (backendResult != null && backendResult['success'] == true) {
        // Registration successful - now try to sign in
        print('✅ Registration successful, attempting signin...');
        
        // Give Firebase a moment to process the new user
        await Future.delayed(Duration(seconds: 1));
        
        // Try to sign in with the newly created account
        try {
          final result = await _authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (result.success) {
            _user = result.user;
            await _loadDriverProfile();
            print('✅ Auto-signin successful after registration');
          } else {
            // Registration was successful but auto-signin failed
            // This is not necessarily an error - user can manually sign in
            print('⚠️ Registration successful but auto-signin failed: ${result.message}');
            _setSignUpError('Account created successfully! Please sign in with your credentials.');
          }
        } catch (signinError) {
          // Registration successful but signin failed
          print('⚠️ Registration successful but auto-signin failed: $signinError');
          _setSignUpError('Account created successfully! Please sign in with your credentials.');
        }
      } else {
        _setSignUpError(backendResult?['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _setSignUpError('Sign up failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out method
  Future<void> signOut() async {
    try {
      print('🔓 Signing out user...');
      await _authService.signOut();
      _user = null;
      _driverProfile = null;
      _clearError();
      print('✅ User signed out successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Sign out error: $e');
      _setError('Sign out failed: ${e.toString()}');
    }
  }

  /// Reset password method
  Future<void> resetPassword(String email) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      // Set a success message or handle success as needed
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete account method
  Future<void> deleteAccount() async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.deleteUser();
      _user = null;
      _driverProfile = null;
      notifyListeners();
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}