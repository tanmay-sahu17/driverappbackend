import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService.instance;
  
  Position? _currentPosition;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedBusNumber;
  Timer? _locationUpdateTimer;

  /// Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedBusNumber => _selectedBusNumber;
  bool get hasLocationPermission => _currentPosition != null || _isTracking;

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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set selected bus number
  void setBusNumber(String busNumber) {
    _selectedBusNumber = busNumber;
    notifyListeners();
  }

  /// Request location permission and get initial location
  Future<bool> initializeLocation() async {
    _setLoading(true);
    _setError(null);

    try {
      bool hasPermission = await _locationService.requestLocationPermission();
      
      if (!hasPermission) {
        _setError('Location permission is required for tracking');
        _setLoading(false);
        return false;
      }

      Position? position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        _currentPosition = position;
        notifyListeners();
      } else {
        _setError('Unable to get current location');
      }

      _setLoading(false);
      return position != null;
    } catch (e) {
      _setError('Failed to initialize location services');
      _setLoading(false);
      return false;
    }
  }

  /// Start GPS tracking and send location updates to backend
  Future<bool> startTracking({String? driverId}) async {
    if (_isTracking) return true;
    
    if (_selectedBusNumber == null) {
      _setError('🚌 Please select your assigned bus first before starting GPS tracking');
      return false;
    }

    if (driverId == null) {
      _setError('🔐 Driver authentication required for tracking');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Check tracking time validation first
      print('🕐 Checking tracking time validation...');
      final trackingStatus = await ApiService.getTrackingStatus(driverId);
      
      if (trackingStatus == null || trackingStatus['success'] != true) {
        _setError('❌ Failed to check tracking status. Please try again.');
        _setLoading(false);
        return false;
      }
      
      final canStartTracking = trackingStatus['data']['canStartTracking'] ?? false;
      if (!canStartTracking) {
        final reason = trackingStatus['data']['reason'] ?? 'Tracking not allowed';
        final timeUntilStart = trackingStatus['data']['timeUntilStart'];
        final timeAfterEnd = trackingStatus['data']['timeAfterEnd'];
        
        String errorMessage = '⏰ $reason';
        if (timeUntilStart != null) {
          errorMessage = '⏰ Tracking starts later. Please wait $timeUntilStart';
        } else if (timeAfterEnd != null) {
          errorMessage = '⏰ Tracking window closed $timeAfterEnd ago. Contact administrator.';
        }
        
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
      
      print('✅ Time validation passed - starting location tracking');

      // First ensure we have location permission and get current location
      bool hasLocation = await initializeLocation();
      if (!hasLocation) {
        _setError('Unable to get location permission');
        _setLoading(false);
        return false;
      }

      bool started = await _locationService.startLocationTracking(
        onLocationUpdate: (Position position) {
          _currentPosition = position;
          notifyListeners();
          
          // Send location update to backend every time position changes
          if (driverId != null && _selectedBusNumber != null) {
            _sendLocationUpdateWithValidation(driverId, position);
          }
        },
      );

      if (started) {
        _isTracking = true;
        
        // Set up periodic location updates to backend (every 10 seconds)
        _locationUpdateTimer = Timer.periodic(
          const Duration(seconds: 10),
          (timer) {
            final now = DateTime.now();
            final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
            
            print('⏰ GPS UPDATE TIMER TRIGGERED at $timeString');
            print('🔄 Timer tick #${timer.tick}');
            
            if (_currentPosition != null && 
                driverId != null && 
                _selectedBusNumber != null) {
              print('📍 Sending location update to backend...');
              print('   Lat: ${_currentPosition!.latitude}');
              print('   Lng: ${_currentPosition!.longitude}');
              print('   Driver: $driverId');
              print('   Bus: $_selectedBusNumber');
              _sendLocationUpdate(driverId, _currentPosition!);
            } else {
              print('❌ Skipping update - Missing data:');
              print('   Position: ${_currentPosition != null ? 'Available' : 'Missing'}');
              print('   DriverID: ${driverId != null ? 'Available' : 'Missing'}');
              print('   BusNumber: ${_selectedBusNumber != null ? 'Available' : 'Missing'}');
            }
            print('==========================================');
          },
        );
      } else {
        _setError('Failed to start location tracking');
      }

      _setLoading(false);
      return started;
    } catch (e) {
      _setError('Error starting location tracking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Stop GPS tracking
  void stopTracking() {
    if (!_isTracking) return;

    _locationService.stopLocationTracking();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate(String driverId, Position position) async {
    try {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      print('🚀 SENDING GPS UPDATE at $timeString');
      print('📱 Driver: $driverId');
      print('🚌 Bus: $_selectedBusNumber');
      print('📍 Coordinates: ${position.latitude}, ${position.longitude}');
      
      bool success = await ApiService.updateLocation(
        driverId: driverId,
        busNumber: _selectedBusNumber!,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (success) {
        print('✅ GPS UPDATE SUCCESSFUL at $timeString');
      } else {
        print('❌ GPS UPDATE FAILED at $timeString');
      }
      print('==========================================');
    } catch (e) {
      print('🔥 GPS UPDATE ERROR: $e');
    }
  }

  /// Send location update with time validation
  Future<void> _sendLocationUpdateWithValidation(String driverId, Position position) async {
    try {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      print('🚀 SENDING VALIDATED GPS UPDATE at $timeString');
      print('📱 Driver: $driverId');
      print('🚌 Bus: $_selectedBusNumber');
      print('📍 Coordinates: ${position.latitude}, ${position.longitude}');
      
      final result = await ApiService.updateLocationWithValidation(
        driverId: driverId,
        busNumber: _selectedBusNumber!,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (result['success'] == true) {
        print('✅ VALIDATED GPS UPDATE SUCCESSFUL at $timeString');
      } else {
        print('❌ VALIDATED GPS UPDATE FAILED at $timeString');
        print('🔍 Reason: ${result['message']}');
        
        // Handle time validation failures
        if (result['code'] == 'TRACKING_NOT_ALLOWED') {
          print('⏰ Time validation failed - stopping tracking');
          stopTracking();
          _setError('⏰ ${result['message']} - Tracking stopped automatically.');
        }
      }
      print('==========================================');
    } catch (e) {
      print('🔥 VALIDATED GPS UPDATE ERROR: $e');
    }
  }

  /// Send SOS alert with current location
  Future<bool> sendSosAlert({
    required String driverId,
    String? emergencyMessage,
  }) async {
    if (_currentPosition == null) {
      _setError('Location not available for SOS alert');
      return false;
    }

    if (_selectedBusNumber == null) {
      _setError('Bus number not selected');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      bool success = await ApiService.sendSosAlert(
        driverId: driverId,
        busNumber: _selectedBusNumber!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        emergencyMessage: emergencyMessage,
      );

      if (!success) {
        _setError('Failed to send SOS alert');
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error sending SOS alert');
      _setLoading(false);
      return false;
    }
  }

  /// Calculate distance to a given location
  double? calculateDistanceTo({
    required double latitude,
    required double longitude,
  }) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      startLatitude: _currentPosition!.latitude,
      startLongitude: _currentPosition!.longitude,
      endLatitude: latitude,
      endLongitude: longitude,
    );
  }

  /// Calculate ETA to a given location
  Duration? calculateEtaTo({
    required double latitude,
    required double longitude,
    double averageSpeedKmh = 40.0,
  }) {
    double? distance = calculateDistanceTo(
      latitude: latitude,
      longitude: longitude,
    );

    if (distance == null) return null;

    return _locationService.calculateEta(
      distanceInMeters: distance,
      averageSpeedKmh: averageSpeedKmh,
    );
  }

  @override
  void dispose() {
    stopTracking();
    _locationService.dispose();
    super.dispose();
  }
}