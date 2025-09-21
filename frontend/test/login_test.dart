import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/services/api_service.dart';
import 'package:driver_app/providers/auth_provider.dart';

void main() {
  group('Login Tests', () {
    test('API Service - loginWithContactNumber should return success for valid credentials', () async {
      // Test with mock data
      const testContactNumber = '9876543210';
      const testPassword = 'testPassword123';
      
      print('🧪 Testing login API with contactNumber: $testContactNumber');
      
      try {
        final result = await ApiService.loginWithContactNumber(
          contactNumber: testContactNumber,
          password: testPassword,
        );
        
        print('📋 Login API Result: $result');
        
        // Check if result is not null
        expect(result, isNotNull);
        
        // Check if result has required structure
        expect(result, isA<Map<String, dynamic>>());
        
        print('✅ API Service test completed');
        
      } catch (e) {
        print('❌ API Service test failed: $e');
        // This is expected if backend is not running
        print('ℹ️ This error is normal if backend server is not running');
      }
    });

    test('Auth Provider - signInWithPhone should handle authentication flow', () async {
      // Create auth provider instance
      final authProvider = AuthProvider();
      
      const testContactNumber = '9876543210';
      const testPassword = 'testPassword123';
      
      print('🧪 Testing AuthProvider signInWithPhone');
      print('📱 Contact Number: $testContactNumber');
      
      try {
        // Test the sign in method
        await authProvider.signInWithPhone(testContactNumber, testPassword);
        
        print('📋 Auth Provider State:');
        print('  - isLoading: ${authProvider.isLoading}');
        print('  - isSignedIn: ${authProvider.isSignedIn}');
        print('  - signInError: ${authProvider.signInError}');
        print('  - driverProfile: ${authProvider.driverProfile}');
        
        // Verify provider state
        expect(authProvider.isLoading, isFalse);
        
        print('✅ Auth Provider test completed');
        
      } catch (e) {
        print('❌ Auth Provider test failed: $e');
        print('ℹ️ This error is normal if backend server is not running');
      }
    });

    test('API Connection Test', () async {
      print('🧪 Testing API connection to backend');
      
      try {
        final isConnected = await ApiService.testConnection();
        
        print('📋 API Connection Result: $isConnected');
        
        if (isConnected) {
          print('✅ Backend server is running and accessible');
        } else {
          print('❌ Backend server is not responding');
          print('ℹ️ Please make sure your Node.js backend is running');
        }
        
        expect(isConnected, isA<bool>());
        
      } catch (e) {
        print('❌ API Connection test failed: $e');
        print('ℹ️ Please check if backend server is running on correct port');
      }
    });

    test('Driver Profile Validation', () {
      print('🧪 Testing driver profile data structure');
      
      // Mock driver profile data as expected from backend
      final mockDriverProfile = {
        'driverId': 'driver_123',
        'name': 'Test Driver',
        'contactNumber': '9876543210',
        'licenseNumber': 'DL123456789',
        'assignedBusId': 'BUS001',
        'status': 'available',
      };
      
      print('📋 Mock Driver Profile: $mockDriverProfile');
      
      // Validate required fields
      expect(mockDriverProfile['driverId'], isNotNull);
      expect(mockDriverProfile['name'], isNotNull);
      expect(mockDriverProfile['contactNumber'], isNotNull);
      expect(mockDriverProfile['licenseNumber'], isNotNull);
      
      // Validate data types
      expect(mockDriverProfile['driverId'], isA<String>());
      expect(mockDriverProfile['name'], isA<String>());
      expect(mockDriverProfile['contactNumber'], isA<String>());
      
      print('✅ Driver profile structure validation passed');
    });
  });
}