class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence; // Order in the route

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      sequence: json['sequence'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
    };
  }
}

class Bus {
  final String number;
  final String route;
  final List<BusStop> stops;

  Bus({
    required this.number,
    required this.route,
    required this.stops,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      number: json['number'] as String,
      route: json['route'] as String,
      stops: (json['stops'] as List<dynamic>)
          .map((stop) => BusStop.fromJson(stop as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'route': route,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }
}

/// Mock bus data for development
class MockBusData {
  static final List<Bus> buses = [
    Bus(
      number: 'BUS001',
      route: 'City Center - Airport',
      stops: [
        BusStop(
          id: 'stop1',
          name: 'City Center',
          latitude: 37.4220, // Near current location (Google HQ)
          longitude: -122.0840,
          sequence: 1,
        ),
        BusStop(
          id: 'stop2',
          name: 'Metro Station',
          latitude: 37.4250, // 3km north
          longitude: -122.0820,
          sequence: 2,
        ),
        BusStop(
          id: 'stop3',
          name: 'Business District',
          latitude: 37.4280, // 6km north
          longitude: -122.0800,
          sequence: 3,
        ),
        BusStop(
          id: 'stop4',
          name: 'Airport',
          latitude: 37.4320, // 10km north
          longitude: -122.0780,
          sequence: 4,
        ),
      ],
    ),
    Bus(
      number: 'BUS002',
      route: 'University - Mall',
      stops: [
        BusStop(
          id: 'stop5',
          name: 'University Gate',
          latitude: 37.4350, // California coordinates
          longitude: -122.0760,
          sequence: 1,
        ),
        BusStop(
          id: 'stop6',
          name: 'Central Library',
          latitude: 37.4380,
          longitude: -122.0740,
          sequence: 2,
        ),
        BusStop(
          id: 'stop7',
          name: 'Shopping Mall',
          latitude: 37.4410,
          longitude: -122.0720,
          sequence: 3,
        ),
      ],
    ),
    Bus(
      number: 'BUS003',
      route: 'Hospital - Railway Station',
      stops: [
        BusStop(
          id: 'stop8',
          name: 'General Hospital',
          latitude: 37.4180, // South of current location
          longitude: -122.0860,
          sequence: 1,
        ),
        BusStop(
          id: 'stop9',
          name: 'Market Square',
          latitude: 37.4150,
          longitude: -122.0880,
          sequence: 2,
        ),
        BusStop(
          id: 'stop10',
          name: 'Railway Station',
          latitude: 37.4120,
          longitude: -122.0900,
          sequence: 3,
        ),
      ],
    ),
  ];

  static Bus? getBusByNumber(String busNumber) {
    try {
      return buses.firstWhere((bus) => bus.number == busNumber);
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllBusNumbers() {
    return buses.map((bus) => bus.number).toList();
  }
}