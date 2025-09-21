import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class TrackingStatusWidget extends StatefulWidget {
  const TrackingStatusWidget({super.key});

  @override
  State<TrackingStatusWidget> createState() => _TrackingStatusWidgetState();
}

class _TrackingStatusWidgetState extends State<TrackingStatusWidget> {
  Map<String, dynamic>? _trackingStatus;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverId = authProvider.driverProfile?['driverId'];
    
    if (driverId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await ApiService.getTrackingStatus(driverId);
      setState(() {
        _trackingStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Checking tracking status...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              IconButton(
                onPressed: _checkTrackingStatus,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }

    if (_trackingStatus == null || _trackingStatus!['success'] != true) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Unable to check tracking status'),
        ),
      );
    }

    final data = _trackingStatus!['data'];
    final canStartTracking = data['canStartTracking'] ?? false;
    final reason = data['reason'] ?? '';
    final trackingWindow = data['trackingWindow'];
    final currentTime = data['currentTime'] ?? '';
    final timeUntilStart = data['timeUntilStart'];
    final timeAfterEnd = data['timeAfterEnd'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canStartTracking ? Icons.schedule : Icons.schedule_outlined,
                  color: canStartTracking ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tracking Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _checkTrackingStatus,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Current status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canStartTracking ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canStartTracking ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canStartTracking ? Icons.check_circle : Icons.access_time,
                    color: canStartTracking ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: canStartTracking ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tracking window info
            if (trackingWindow != null) ...[
              Text(
                'Tracking Window',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${trackingWindow['startTime']} - ${trackingWindow['endTime']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Duration: ${trackingWindow['duration']}'),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Current time
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Current Time: $currentTime',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            // Additional time info
            if (timeUntilStart != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Starts in: $timeUntilStart',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ],
            
            if (timeAfterEnd != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.hourglass_bottom, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Ended $timeAfterEnd ago',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}