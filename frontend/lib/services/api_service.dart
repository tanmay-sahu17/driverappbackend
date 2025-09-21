import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL for the backend API - Your Node.js backend
  // Use your computer's IP address for real device testing
  // static const String baseUrl = 'http://10.27.245.57:3000/api';
  // For emulator testing (10.0.2.2 maps to host machine's localhost): 
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://10.31.15.1:3000/api';
  
  // Headers for all API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Update driver's location to the backend
  static Future<bool> updateLocation({
    required String driverId,
    required String busNumber,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: headers,
        body: jsonEncode({
          'driverId': driverId,
          'busNumber': busNumber,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': 10.0,
          'speed': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('Location update response: ${response.statusCode}');
      print('Location update body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Location update failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  /// Send SOS alert with driver details and location
  static Future<bool> sendSosAlert({
    required String driverId,
    required String busNumber,
    required double latitude,
    required double longitude,
    String? emergencyMessage,
  }) async {
    try {
      final requestBody = {
        'driverId': driverId,
        'busNumber': busNumber,
        'latitude': latitude,
        'longitude': longitude,
        'emergencyMessage': emergencyMessage ?? 'Emergency SOS Alert',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Sending SOS Alert to: $baseUrl/sos/alert');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/sos/alert'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('SOS alert response status: ${response.statusCode}');
      print('SOS alert response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SOS alert sent successfully');
        return true;
      } else {
        print('SOS alert failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SOS alert: $e');
      return false;
    }
  }

  /// Register driver with the backend
  static Future<bool> registerDriver({
    required String password,
    required String driverName,
    required String phoneNumber,
    required String licenseNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'password': password,
          'driverName': driverName,
          'phoneNumber': phoneNumber,
          'licenseNumber': licenseNumber,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error registering driver: $e');
      return false;
    }
  }

  /// Get available buses
  static Future<List<Map<String, dynamic>>> getBusList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bus/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> buses = responseData['data'];
        return buses.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching bus list: $e');
      return [];
    }
  }

  /// Assign driver to bus
  static Future<bool> assignBus({
    required String driverId,
    required String busNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bus/assign'),
        headers: headers,
        body: jsonEncode({
          'driverId': driverId,
          'busNumber': busNumber,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning bus: $e');
      return false;
    }
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl/health');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );

      print('Health check response: ${response.statusCode}');
      print('Health check body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error testing API connection: $e');
      return false;
    }
  }

  /// Get email by phone number for login
  static Future<String?> getEmailByPhone(String phoneNumber) async {
    try {
      print('Getting email for phone: $phoneNumber');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/get-email-by-phone'),
        headers: headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
        }),
      );

      print('Get email response: ${response.statusCode}');
      print('Get email body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'];
      } else {
        print('Failed to get email: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting email by phone: $e');
      return null;
    }
  }

  /// Sign in with email and password
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting sign in for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Sign in response: ${response.statusCode}');
      print('Sign in body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Sign in failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  /// Register new driver account
  static Future<Map<String, dynamic>?> signUp({
    required String password,
    required String driverName,
    required String phoneNumber,
    required String licenseNumber,
  }) async {
    try {
      print('Attempting sign up for phone: $phoneNumber');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'password': password,
          'driverName': driverName,
          'phoneNumber': phoneNumber,
          'licenseNumber': licenseNumber,
        }),
      );

      print('Sign up response: ${response.statusCode}');
      print('Sign up body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Sign up failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }
}