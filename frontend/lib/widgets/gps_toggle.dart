import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';

class GpsToggle extends StatefulWidget {
  const GpsToggle({super.key});

  @override
  State<GpsToggle> createState() => _GpsToggleState();
}

class _GpsToggleState extends State<GpsToggle> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize location when widget is first built
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.initializeLocation();
    });
  }

  void _toggleGpsTracking() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (locationProvider.isTracking) {
      // Stop tracking
      locationProvider.stopTracking();
      _showSnackbar('GPS tracking stopped', isError: false);
    } else {
      // Check if bus is selected before starting tracking
      if (locationProvider.selectedBusNumber == null) {
        _showBusSelectionDialog();
        return;
      }

      // Start tracking
      bool success = await locationProvider.startTracking(
        driverId: authProvider.user?.uid,
      );
      
      if (success) {
        _showSnackbar('GPS tracking started', isError: false);
      } else {
        _showSnackbar(
          locationProvider.errorMessage ?? 'Failed to start GPS tracking',
          isError: true,
        );
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Card(
          elevation: 2,
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: locationProvider.isTracking 
                          ? (isDarkMode ? const Color(0xFF4CAF50) : Colors.green[600])
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPS Tracking',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Status Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: locationProvider.isTracking 
                        ? (isDarkMode 
                            ? const Color(0xFF0D4F3C).withOpacity(0.3)
                            : Colors.green[50])
                        : (isDarkMode 
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: locationProvider.isTracking 
                          ? (isDarkMode 
                              ? const Color(0xFF4CAF50).withOpacity(0.5)
                              : Colors.green[200]!)
                          : (isDarkMode 
                              ? Colors.grey[600]!
                              : Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: locationProvider.isTracking 
                              ? (isDarkMode ? const Color(0xFF4CAF50) : Colors.green[600])
                              : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationProvider.isTracking 
                                  ? 'Tracking Active' 
                                  : 'Tracking Inactive',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: locationProvider.isTracking 
                                    ? Colors.green[700] 
                                    : Colors.grey[700],
                              ),
                            ),
                            if (locationProvider.isTracking) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Location updates being sent',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // GPS Info (simplified)
                if (locationProvider.currentPosition != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location, 
                                 color: isDarkMode ? const Color(0xFF6CB5A8) : Colors.green[600], 
                                 size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${locationProvider.currentPosition!.latitude.toStringAsFixed(4)}, ${locationProvider.currentPosition!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Acc: ${locationProvider.currentPosition!.accuracy.toStringAsFixed(0)}m',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${locationProvider.currentPosition!.speed.toStringAsFixed(1)} m/s',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Toggle Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: locationProvider.isLoading 
                        ? null 
                        : _toggleGpsTracking,
                    icon: locationProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            locationProvider.isTracking 
                                ? Icons.stop 
                                : Icons.play_arrow,
                          ),
                    label: Text(
                      locationProvider.isTracking 
                          ? 'Stop Tracking' 
                          : 'Start Tracking',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: locationProvider.isTracking 
                          ? Colors.red[600] 
                          : Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                // Error Message
                if (locationProvider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, 
                             color: Colors.red[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationProvider.errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBusSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blue),
              SizedBox(width: 8),
              Text('Select Bus'),
            ],
          ),
          content: const Text(
            'Please select your assigned bus before starting GPS tracking.\n\nYou can select a bus from the dashboard or bus selection screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to bus selection screen
                Navigator.pushNamed(context, '/bus-selection');
              },
              child: const Text('Select Bus'),
            ),
          ],
        );
      },
    );
  }
}
