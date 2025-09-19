import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/bus_model.dart';
import '../services/api_service.dart';

class EtaDisplay extends StatefulWidget {
  const EtaDisplay({super.key});

  @override
  State<EtaDisplay> createState() => _EtaDisplayState();
}

class _EtaDisplayState extends State<EtaDisplay> {
  BusStop? _nextStop;
  String? _etaText;
  String? _distanceText;
  bool _isLoading = false;
  DateTime? _lastCalculated;
  static const Duration _cooldownDuration = Duration(seconds: 30); // Prevent spam requests

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateEta();
    });
  }

  bool _canCalculateEta() {
    if (_lastCalculated == null) return true;
    return DateTime.now().difference(_lastCalculated!) > _cooldownDuration;
  }

  void _calculateEta() async {
    // Prevent spam requests
    if (!_canCalculateEta()) {
      print('🗺️ ETA Debug: Cooldown active, skipping calculation');
      return;
    }

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    print('🗺️ ETA Debug: selectedBusNumber = ${locationProvider.selectedBusNumber}');
    print('🗺️ ETA Debug: currentPosition = ${locationProvider.currentPosition}');
    
    if (locationProvider.selectedBusNumber == null) {
      print('🗺️ ETA Debug: No bus selected');
      setState(() {
        _nextStop = null;
        _etaText = null;
        _distanceText = null;
        _isLoading = false;
      });
      return;
    }
    
    if (locationProvider.currentPosition == null) {
      print('🗺️ ETA Debug: No location available, trying to initialize...');
      // Try to initialize location if not available
      await locationProvider.initializeLocation();
      if (locationProvider.currentPosition == null) {
        print('🗺️ ETA Debug: Still no location after initialization');
        setState(() {
          _nextStop = null;
          _etaText = null;
          _distanceText = null;
          _isLoading = false;
        });
        return;
      }
    }

    // Set last calculated time to prevent spam
    _lastCalculated = DateTime.now();

    Bus? bus = MockBusData.getBusByNumber(locationProvider.selectedBusNumber!);
    if (bus == null || bus.stops.isEmpty) {
      print('🗺️ ETA Debug: No mock bus found for ${locationProvider.selectedBusNumber}, using default stops');
      // If no mock bus found, create a default bus with stops for real bus numbers
      BusStop defaultStop = BusStop(
        id: 'default_stop',
        name: 'Next Stop (Raipur)',
        latitude: 21.2514, // Raipur coordinates  
        longitude: 81.6296,
        sequence: 1,
      );
      
      setState(() {
        _isLoading = true;
        _nextStop = defaultStop;
      });
    } else {
      // Find the next stop (for demo, we'll use the first stop)
      // In a real app, this would be determined by route progress
      BusStop nextStop = bus.stops.first;
      
      setState(() {
        _isLoading = true;
        _nextStop = nextStop;
      });
    }

    try {
      // Call real ETA API using the next stop we found
      final etaData = await ApiService.getEtaInfo(
        fromLatitude: locationProvider.currentPosition!.latitude,
        fromLongitude: locationProvider.currentPosition!.longitude,
        toLatitude: _nextStop!.latitude,
        toLongitude: _nextStop!.longitude,
        averageSpeed: 35.0, // Bus average speed in city
      );

      if (etaData != null && mounted) {
        setState(() {
          _etaText = etaData['eta']['formatted'] ?? '${etaData['eta']['minutes']}m';
          _distanceText = '${etaData['distance']['kilometers']} km';
          _isLoading = false;
        });
      } else {
        // Fallback to mock data if API fails
        setState(() {
          _etaText = '~12m';
          _distanceText = '~3.2 km';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ETA calculation error: $e');
      // Fallback to mock data
      setState(() {
        _etaText = '~12m';
        _distanceText = '~3.2 km';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Only recalculate ETA when manually triggered, not on every location change
        // to prevent spam requests
        
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
                      Icons.schedule,
                      color: isDarkMode ? const Color(0xFF6CB5A8) : Colors.green[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Stop ETA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_nextStop != null) ...[
                  // Next Stop Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode 
                            ? [
                                const Color(0xFF1E1E1E),
                                const Color(0xFF2A2A2A),
                              ]
                            : [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nextStop!.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stop ${_nextStop!.sequence}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              color: Colors.green[600],
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // ETA and Distance Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ETA',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_isLoading)
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    Text(
                                      _etaText ?? '--',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _distanceText ?? '--',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // No location or bus selected state
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locationProvider.selectedBusNumber == null
                              ? 'Please select a bus first'
                              : 'Location not available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Refresh Button
                Center(
                  child: TextButton.icon(
                    onPressed: _calculateEta,
                    icon: Icon(
                      Icons.refresh,
                      color: isDarkMode ? const Color(0xFF6CB5A8) : Colors.green[600],
                    ),
                    label: Text(
                      'Refresh ETA',
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFF6CB5A8) : Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}