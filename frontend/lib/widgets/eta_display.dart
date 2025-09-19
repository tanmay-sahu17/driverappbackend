import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/bus_model.dart';

class EtaDisplay extends StatefulWidget {
  const EtaDisplay({super.key});

  @override
  State<EtaDisplay> createState() => _EtaDisplayState();
}

class _EtaDisplayState extends State<EtaDisplay> {
  BusStop? _nextStop;
  Duration? _eta;
  double? _distance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateEta();
    });
  }

  void _calculateEta() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    if (locationProvider.selectedBusNumber == null || 
        locationProvider.currentPosition == null) {
      return;
    }

    Bus? bus = MockBusData.getBusByNumber(locationProvider.selectedBusNumber!);
    if (bus == null || bus.stops.isEmpty) {
      return;
    }

    // Find the next stop (for demo, we'll use the first stop)
    // In a real app, this would be determined by route progress
    BusStop nextStop = bus.stops.first;
    
    double? distance = locationProvider.calculateDistanceTo(
      latitude: nextStop.latitude,
      longitude: nextStop.longitude,
    );

    Duration? eta = locationProvider.calculateEtaTo(
      latitude: nextStop.latitude,
      longitude: nextStop.longitude,
    );

    setState(() {
      _nextStop = nextStop;
      _distance = distance;
      _eta = eta;
    });
  }

  String _formatEta(Duration eta) {
    if (eta.inHours > 0) {
      return '${eta.inHours}h ${eta.inMinutes.remainder(60)}m';
    } else if (eta.inMinutes > 0) {
      return '${eta.inMinutes}m';
    } else {
      return '< 1m';
    }
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Recalculate ETA when location changes
        if (locationProvider.currentPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateEta();
          });
        }

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
                
                if (_nextStop != null && _eta != null && _distance != null) ...[
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
                          children: [
                            Icon(Icons.location_on, 
                                 color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nextStop!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // ETA
                        Row(
                          children: [
                            Icon(Icons.access_time, 
                                 color: Colors.green[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ETA: ${_formatEta(_eta!)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Distance
                        Row(
                          children: [
                            Icon(Icons.straighten, 
                                 color: Colors.green[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Distance: ${_formatDistance(_distance!)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Route Progress
                  if (locationProvider.selectedBusNumber != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? const Color(0xFF1E3A8A).withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode 
                              ? const Color(0xFF3B82F6).withOpacity(0.5)
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route, 
                                color: isDarkMode ? const Color(0xFF3B82F6) : Colors.blue[600], 
                                size: 16
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Route Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? const Color(0xFF3B82F6) : Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Progress bar (mock)
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? const Color(0xFF1E3A8A).withOpacity(0.5)
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.3, // Mock 30% progress
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF3B82F6) : Colors.blue[600],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          Text(
                            'Stop 1 of ${MockBusData.getBusByNumber(locationProvider.selectedBusNumber!)?.stops.length ?? 0}',
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFF3B82F6) : Colors.blue[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // No data available
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ETA Not Available',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationProvider.selectedBusNumber == null
                              ? 'Select a bus to view ETA'
                              : locationProvider.currentPosition == null
                                  ? 'Enable location to calculate ETA'
                                  : 'Route information not available',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Refresh Button
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _calculateEta,
                      icon: Icon(
                        Icons.refresh, 
                        size: 18,
                        color: isDarkMode ? const Color(0xFF6CB5A8) : null,
                      ),
                      label: Text(
                        'Refresh ETA',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF6CB5A8) : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        side: BorderSide(
                          color: isDarkMode 
                              ? const Color(0xFF6CB5A8).withOpacity(0.5)
                              : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
