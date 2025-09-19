import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isTracking = false;

  /// Get current location
  Position? get currentPosition => _currentPosition;
  
  /// Check if location tracking is active
  bool get isTracking => _isTracking;

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking({
    required Function(Position) onLocationUpdate,
    int intervalSeconds = 5,
  }) async {
    try {
      if (_isTracking) {
        return true;
      }

      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return false;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update only if moved at least 10 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );

      _isTracking = true;
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate ETA based on distance and average speed
  Duration calculateEta({
    required double distanceInMeters,
    double averageSpeedKmh = 40.0, // Average bus speed
  }) {
    if (distanceInMeters <= 0) {
      return Duration.zero;
    }

    double distanceInKm = distanceInMeters / 1000;
    double timeInHours = distanceInKm / averageSpeedKmh;
    return Duration(milliseconds: (timeInHours * 60 * 60 * 1000).round());
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}