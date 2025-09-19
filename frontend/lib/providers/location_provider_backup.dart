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

  /// Set bus number
  void setBusNumber(String busNumber) {
    _selectedBusNumber = busNumber;
    notifyListeners();
  }

  /// Initialize location services
  Future<void> initializeLocation() async {
    try {
      _setLoading(true);
      _setError(null);
      
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        _setError(null);
      } else {
        _setError('Failed to get location');
      }
    } catch (e) {
      _setError('Location error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Start location tracking
  Future<bool> startTracking({String? driverId}) async {
    try {
      _setLoading(true);
      _setError(null);

      bool success = await _locationService.startLocationTracking(
        onLocationUpdate: (Position position) {
          _currentPosition = position;
          notifyListeners();
          
          // Log location update for debugging
          print('📍 GPS UPDATE RECEIVED:');
          print('📍 Lat: ${position.latitude}');
          print('📍 Lng: ${position.longitude}'); 
          print('🎯 Accuracy: ${position.accuracy}m');
          print('⚡ Speed: ${position.speed} m/s');
          print('🕒 Time: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp!.millisecondsSinceEpoch)}');
          print('=====================');

          // Send to backend API (if needed)
          _sendLocationUpdate(position, driverId);
        },
      );

      if (success) {
        _isTracking = true;
        _setError(null);
        
        // Start periodic location updates to backend
        _startLocationUpdateTimer(driverId);
      } else {
        _setError('Failed to start location tracking');
      }

      return success;
    } catch (e) {
      _setError('Error starting tracking: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _locationService.stopLocationTracking();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    _setError(null);
    notifyListeners();
  }

  /// Start periodic location updates
  void _startLocationUpdateTimer(String? driverId) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null && _isTracking) {
        _sendLocationUpdate(_currentPosition!, driverId);
      }
    });
  }

  /// Send location update to backend
  void _sendLocationUpdate(Position position, String? driverId) async {
    try {
      await ApiService.updateLocation(
        driverId: driverId ?? 'default_driver',
        busNumber: _selectedBusNumber ?? 'BUS001',
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      print('Error updating location: $e');
      // Don't set error for API failures as GPS is still working
    }
  }

  /// Calculate distance to a destination
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

  /// Calculate ETA to a destination
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