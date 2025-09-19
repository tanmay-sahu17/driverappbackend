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
          print('🔥 GPS UPDATE RECEIVED:');
          print('📍 Lat: ${position.latitude}');
          print('📍 Lng: ${position.longitude}');
          print('🎯 Accuracy: ${position.accuracy}m');
          print('⚡ Speed: ${position.speed} m/s');
          print('🕒 Time: ${DateTime.now()}');
          print('=====================');
          notifyListeners();
          
          // Send location update to backend every time position changes
          if (driverId != null && _selectedBusNumber != null) {
            _sendLocationUpdate(driverId, position);
          }
        },
      );

      if (started) {
        _isTracking = true;
        
        // Set up periodic location updates to backend (every 10 seconds)
        _locationUpdateTimer = Timer.periodic(
          const Duration(seconds: 10),
          (timer) {
            if (_currentPosition != null && 
                driverId != null && 
                _selectedBusNumber != null) {
              _sendLocationUpdate(driverId, _currentPosition!);
            }
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
      await ApiService.updateLocation(
        driverId: driverId,
        busNumber: _selectedBusNumber!,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Failed to send location update: $e');
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