class DriverModel {
  final String name;
  final String licenseNumber;
  final String contactNumber;
  final String dob;
  final String emergencyContactNumber;
  final String driverId;
  final String password;
  final String aadharCardNumber;
  final String joiningDate;
  final String experience;
  final String address;
  final String city;
  final String state;
  final String? assignedBusId;
  final DriverStatus status;

  DriverModel({
    required this.name,
    required this.licenseNumber,
    required this.contactNumber,
    required this.dob,
    required this.emergencyContactNumber,
    required this.driverId,
    required this.password,
    required this.aadharCardNumber,
    required this.joiningDate,
    required this.experience,
    required this.address,
    required this.city,
    required this.state,
    this.assignedBusId,
    this.status = DriverStatus.available,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      name: json['name'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      dob: json['dob'] ?? '',
      emergencyContactNumber: json['emergencyContactNumber'] ?? '',
      driverId: json['driverId'] ?? '',
      password: json['password'] ?? '',
      aadharCardNumber: json['aadharCardNumber'] ?? '',
      joiningDate: json['joiningDate'] ?? '',
      experience: json['experience'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      assignedBusId: json['assignedBusId'],
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'licenseNumber': licenseNumber,
      'contactNumber': contactNumber,
      'dob': dob,
      'emergencyContactNumber': emergencyContactNumber,
      'driverId': driverId,
      'password': password,
      'aadharCardNumber': aadharCardNumber,
      'joiningDate': joiningDate,
      'experience': experience,
      'address': address,
      'city': city,
      'state': state,
      'assignedBusId': assignedBusId,
      'status': status.name,
    };
  }

  static DriverStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return DriverStatus.available;
      case 'on-duty':
        return DriverStatus.onDuty;
      case 'off-duty':
        return DriverStatus.offDuty;
      default:
        return DriverStatus.available;
    }
  }

  DriverModel copyWith({
    String? name,
    String? licenseNumber,
    String? contactNumber,
    String? dob,
    String? emergencyContactNumber,
    String? driverId,
    String? password,
    String? aadharCardNumber,
    String? joiningDate,
    String? experience,
    String? address,
    String? city,
    String? state,
    String? assignedBusId,
    DriverStatus? status,
  }) {
    return DriverModel(
      name: name ?? this.name,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      dob: dob ?? this.dob,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      driverId: driverId ?? this.driverId,
      password: password ?? this.password,
      aadharCardNumber: aadharCardNumber ?? this.aadharCardNumber,
      joiningDate: joiningDate ?? this.joiningDate,
      experience: experience ?? this.experience,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      status: status ?? this.status,
    );
  }
}

enum DriverStatus {
  available,
  onDuty,
  offDuty,
}

extension DriverStatusExtension on DriverStatus {
  String get displayName {
    switch (this) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.onDuty:
        return 'On Duty';
      case DriverStatus.offDuty:
        return 'Off Duty';
    }
  }
}