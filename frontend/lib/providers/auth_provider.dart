import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  // Private variables
  bool _isLoading = false;
  String? _errorMessage;
  String? _signInError;
  String? _signUpError;
  User? _user;
  Map<String, dynamic>? _driverProfile;
  Map<String, dynamic>? _driverAssignment;
  Map<String, dynamic>? _assignedBus;

  /// Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get signInError => _signInError;
  String? get signUpError => _signUpError;
  bool get isSignedIn => _driverProfile != null && _driverProfile!['driverId'] != null;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  Map<String, dynamic>? get driverAssignment => _driverAssignment;
  Map<String, dynamic>? get assignedBus => _assignedBus;
  bool get hasActiveAssignment => _driverAssignment != null && _assignedBus != null;

  /// Initialize auth provider
  AuthProvider() {
    initializeAuth();
  }

  void initializeAuth() {
    // Set initial loading state
    _setLoading(true);
    
    // For now, we don't have persistent sessions
    // Drivers need to login each time the app starts
    _user = null;
    _driverProfile = null;
    _driverAssignment = null;
    _assignedBus = null;
    
    // Auth state is determined, stop loading
    _setLoading(false);
    
    print('🔧 Auth provider initialized - no persistent session');
    notifyListeners();
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

  /// Sign in with contact number and password (direct authentication)
  Future<void> signInWithPhone(String contactNumber, String password) async {
    _clearError();
    _setLoading(true);

    try {
      print('🔐 Attempting to sign in with contact number: $contactNumber');
      
      // Direct login with contact number and password
      final result = await ApiService.loginWithContactNumber(
        contactNumber: contactNumber,
        password: password,
      );

      if (result != null && result['success'] == true) {
        // Store driver data from backend response
        final driverData = result['driver'];
        
        if (driverData != null) {
          // Create a mock Firebase user for compatibility
          _user = null; // We'll handle auth state differently now
          
          // Store driver profile data
          _driverProfile = {
            'driverId': driverData['driverId'] ?? '',
            'name': driverData['name'] ?? '',
            'contactNumber': driverData['contactNumber'] ?? '',
            'licenseNumber': driverData['licenseNumber'] ?? '',
            'assignedBusId': driverData['assignedBusId'],
            'status': driverData['status'] ?? 'available',
          };
          
          // Store assignment data if available
          final assignmentData = result['assignment'];
          final busData = result['assignedBus'];
          
          if (assignmentData != null) {
            _driverAssignment = Map<String, dynamic>.from(assignmentData);
            print('✅ Assignment loaded: ${_driverAssignment?['assignmentId']}');
          } else {
            _driverAssignment = null;
            print('ℹ️ No active assignment found');
          }
          
          if (busData != null) {
            _assignedBus = Map<String, dynamic>.from(busData);
            print('✅ Assigned bus loaded: ${_assignedBus?['busNumber']}');
          } else {
            _assignedBus = null;
            print('ℹ️ No assigned bus found');
          }
          
          // Clear any existing errors on successful login
          _clearError();
          print('✅ Sign in successful for contact number: $contactNumber');
          print('👤 Driver profile loaded: ${_driverProfile?['name']}');
          print('🚌 Assignment status: ${hasActiveAssignment ? "Assigned to ${_assignedBus?['busNumber']}" : "No assignment"}');
        } else {
          print('❌ No driver data in response');
          _setSignInError('Invalid response from server');
        }
      } else {
        final errorMessage = result?['message'] ?? 'Login failed';
        print('❌ Sign in failed: $errorMessage');
        _setSignInError(errorMessage);
      }
    } catch (e) {
      print('❌ Sign in exception: $e');
      _setSignInError('Sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in method (original email-based)
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

  /// Sign up with phone number and password (email is auto-generated)
  Future<void> signUp({
    required String password,
    required String driverName,
    required String contactNumber,
    required String licenseNumber,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // First register with backend (backend will generate email internally)
      final backendResult = await ApiService.signUp(
        password: password,
        driverName: driverName,
        contactNumber: contactNumber,
        licenseNumber: licenseNumber,
      );

      if (backendResult != null && backendResult['success'] == true) {
        // Registration successful
        print('✅ Registration successful for phone: $contactNumber');
        
        // Clean phone number to generate the same email pattern as backend
        String cleanPhone = contactNumber.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanPhone.length > 10) {
          cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
        }
        final generatedEmail = 'driver_$cleanPhone@busdriver.app';
        
        // Give Firebase a moment to process the new user
        await Future.delayed(Duration(seconds: 1));
        
        // Try to sign in with the generated email
        try {
          final result = await _authService.signInWithEmailAndPassword(
            email: generatedEmail,
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
            _setSignUpError('Account created successfully! Please sign in with your phone number and password.');
          }
        } catch (signinError) {
          // Registration successful but signin failed
          print('⚠️ Registration successful but auto-signin failed: $signinError');
          _setSignUpError('Account created successfully! Please sign in with your phone number and password.');
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
      // Clear driver profile, assignment, and user data
      _user = null;
      _driverProfile = null;
      _driverAssignment = null;
      _assignedBus = null;
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
      _driverAssignment = null;
      _assignedBus = null;
      notifyListeners();
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh assignment data for current driver
  Future<void> refreshAssignment() async {
    if (_driverProfile == null || _driverProfile!['driverId'] == null) {
      print('❌ Cannot refresh assignment: No driver logged in');
      return;
    }

    try {
      _setLoading(true);
      final driverId = _driverProfile!['driverId'];
      
      print('🔄 Refreshing assignment for driver: $driverId');
      
      final result = await ApiService.getDriverAssignment(driverId);
      
      if (result != null && result['success'] == true) {
        final assignmentData = result['assignment'];
        final busData = result['assignedBus'];
        
        if (assignmentData != null) {
          _driverAssignment = Map<String, dynamic>.from(assignmentData);
          print('✅ Assignment refreshed: ${_driverAssignment?['assignmentId']}');
        } else {
          _driverAssignment = null;
          print('ℹ️ No assignment found');
        }
        
        if (busData != null) {
          _assignedBus = Map<String, dynamic>.from(busData);
          print('✅ Assigned bus refreshed: ${_assignedBus?['busNumber']}');
        } else {
          _assignedBus = null;
          print('ℹ️ No assigned bus found');
        }
        
        notifyListeners();
      } else {
        print('❌ Failed to refresh assignment data');
        // Don't clear existing data on failure, just log
      }
    } catch (e) {
      print('❌ Error refreshing assignment: $e');
      // Don't clear existing data on error, just log
    } finally {
      _setLoading(false);
    }
  }
}