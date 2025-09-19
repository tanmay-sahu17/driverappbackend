import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class DebugApiScreen extends StatefulWidget {
  const DebugApiScreen({Key? key}) : super(key: key);

  @override
  State<DebugApiScreen> createState() => _DebugApiScreenState();
}

class _DebugApiScreenState extends State<DebugApiScreen> {
  String _connectionStatus = 'Not tested';
  String _firebaseStatus = 'Not tested';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
        backgroundColor: const Color(0xFF4A9B8E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('API Status: $_connectionStatus'),
                    Text('Firebase Status: $_firebaseStatus'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9B8E),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Endpoints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Base URL: http://10.31.15.146:3000/api'),
                    const SizedBox(height: 4),
                    const Text('Health: /health'),
                    const SizedBox(height: 4),
                    const Text('Auth: /auth/register, /auth/verify'),
                    const SizedBox(height: 4),
                    const Text('Location: /location/update'),
                    const SizedBox(height: 4),
                    const Text('SOS: /sos/alert'),
                    const SizedBox(height: 4),
                    const Text('Bus: /bus/list, /bus/assign'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Firebase'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testLocationUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6CB5A8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Location Update'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testSosAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test SOS Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing...';
    });

    try {
      bool connected = await ApiService.testConnection();
      setState(() {
        _connectionStatus = connected 
            ? '✅ Connected successfully!' 
            : '❌ Connection failed';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFirebase() async {
    setState(() {
      _firebaseStatus = 'Testing...';
    });

    try {
      // Test Firebase Auth initialization
      FirebaseAuth auth = FirebaseAuth.instance;
      
      // Check if Firebase is initialized
      if (auth.app.options.projectId.isNotEmpty) {
        setState(() {
          _firebaseStatus = '✅ Firebase initialized (${auth.app.options.projectId})';
        });
      } else {
        setState(() {
          _firebaseStatus = '❌ Firebase not properly configured';
        });
      }
    } catch (e) {
      setState(() {
        _firebaseStatus = '❌ Firebase Error: $e';
      });
    }
  }

  Future<void> _testLocationUpdate() async {
    try {
      bool success = await ApiService.updateLocation(
        driverId: 'test_driver_001',
        busNumber: 'BUS001',
        latitude: 28.6139,
        longitude: 77.2090,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '✅ Location update successful!' 
              : '❌ Location update failed - Check debug console'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Location update error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _testSosAlert() async {
    try {
      bool success = await ApiService.sendSosAlert(
        driverId: 'test_driver_001',
        busNumber: 'BUS001',
        latitude: 28.6139,
        longitude: 77.2090,
        emergencyMessage: 'Test SOS alert from debug screen',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '✅ SOS alert sent successfully!' 
              : '❌ SOS alert failed - Check debug console'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ SOS alert error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}