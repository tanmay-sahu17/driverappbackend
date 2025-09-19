import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/bus_model.dart';
import '../services/api_service.dart';

class BusSelector extends StatefulWidget {
  const BusSelector({super.key});

  @override
  State<BusSelector> createState() => _BusSelectorState();
}

class _BusSelectorState extends State<BusSelector> {
  String? selectedBusNumber;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allBuses = [];
  List<Map<String, dynamic>> filteredBuses = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBuses);
    _loadBuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('🚌 Loading buses from API...');
      final buses = await ApiService.getBusList();
      
      print('📋 Received ${buses.length} buses from API');
      buses.forEach((bus) {
        print('🚌 Bus: ${bus['busNumber']} - ${bus['model'] ?? 'Unknown Model'}');
      });

      setState(() {
        allBuses = buses;
        filteredBuses = buses;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading buses: $e');
      setState(() {
        errorMessage = 'Failed to load buses: $e';
        isLoading = false;
        // Fallback to mock data if API fails
        final mockBusNumbers = MockBusData.getAllBusNumbers();
        allBuses = mockBusNumbers.map((busNumber) => {
          'id': busNumber.toLowerCase(),
          'busNumber': busNumber,
          'model': 'Mock Bus',
          'capacity': 40,
          'busType': 'AC'
        }).toList();
        filteredBuses = allBuses;
      });
    }
  }

  void _filterBuses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredBuses = allBuses;
      } else {
        filteredBuses = allBuses
            .where((bus) => bus['busNumber'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _selectBus(String busNumber) {
    setState(() {
      selectedBusNumber = busNumber;
      _searchController.text = busNumber;
    });
    
    // Update the location provider with selected bus
    Provider.of<LocationProvider>(context, listen: false)
        .setBusNumber(busNumber);
    
    // Close the dropdown
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                  Icons.directions_bus,
                  color: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Bus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _loadBuses,
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E),
                    ),
                    tooltip: 'Refresh bus list',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bus Selection
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
              child: TextFormField(
                controller: _searchController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Bus Number',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  hintText: 'BUS001, BUS002...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: selectedBusNumber != null
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              selectedBusNumber = null;
                              _searchController.clear();
                            });
                            Provider.of<LocationProvider>(context, listen: false)
                                .setBusNumber('');
                          },
                        )
                      : Icon(
                          Icons.keyboard_arrow_down,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E), 
                      width: 2
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                readOnly: false,
                onTap: () {
                  _showBusSelectionModal();
                },
              ),
            ),
            
            if (selectedBusNumber != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF0D4F3C).withOpacity(0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode 
                        ? const Color(0xFF4CAF50).withOpacity(0.5)
                        : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      color: isDarkMode ? const Color(0xFF4CAF50) : Colors.green[600], 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned: $selectedBusNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? const Color(0xFF4CAF50) : Colors.green[700],
                            ),
                          ),
                          Text(
                            _getBusRoute(selectedBusNumber!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
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
  }

  String _getBusRoute(String busNumber) {
    try {
      final bus = allBuses.firstWhere((b) => b['busNumber'] == busNumber);
      final model = bus['model'] ?? 'Unknown Model';
      final busType = bus['busType'] ?? 'Standard';
      final capacity = bus['capacity'] ?? 'N/A';
      return '$model - $busType ($capacity seats)';
    } catch (e) {
      // Fallback to mock data
      Bus? mockBus = MockBusData.getBusByNumber(busNumber);
      return mockBus?.route ?? 'Route information not available';
    }
  }

  void _showBusSelectionModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Text(
                        'Select Bus',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (!isLoading && allBuses.isNotEmpty)
                        Text(
                          '${allBuses.length} buses',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Error message
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Using demo data. $errorMessage',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Bus List
                  Flexible(
                    child: isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : filteredBuses.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('No buses found'),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredBuses.length,
                                itemBuilder: (context, index) {
                                  final bus = filteredBuses[index];
                                  final busNumber = bus['busNumber'].toString();
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                    title: Text(
                                      busNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${bus['model'] ?? 'Unknown Model'}'),
                                        Text(
                                          '${bus['busType'] ?? 'Standard'} • ${bus['capacity'] ?? 'N/A'} seats',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: selectedBusNumber == busNumber
                                        ? Icon(Icons.check, color: Colors.green[600])
                                        : null,
                                    onTap: () {
                                      _selectBus(busNumber);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
