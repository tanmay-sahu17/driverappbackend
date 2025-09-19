# Driver App - Real-time Bus Tracking System

A professional Flutter application for bus drivers to enable real-time GPS tracking, emergency SOS alerts, and ETA calculations. Built for Smart India Hackathon with clean, production-ready UI.

## Features

### 🔐 Authentication
- Email/password login and signup
- Firebase Authentication integration
- Secure session management
- Profile management

### 📍 GPS Tracking
- Real-time location tracking using Geolocator
- Continuous location updates to backend API
- Location permission management
- Background location tracking

### 🚌 Bus Management
- Bus selection with searchable dropdown
- Route information display
- Bus assignment tracking
- Multiple bus support with mock data

### 🆘 Emergency SOS
- Large, prominent SOS button
- Immediate location transmission on emergency
- Confirmation dialogs for safety
- Real-time alert system

### ⏱️ ETA Calculation
- Real-time ETA to next bus stop
- Distance calculation using current GPS
- Route progress tracking
- Mock bus stop integration

### 🎨 UI/UX Design
- Clean, professional Material Design
- Subtle color palette (white, light gray, blue/green)
- No emojis - production-ready interface
- Responsive design with proper error handling
- Loading states and user feedback

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Authentication**: Firebase Auth
- **Location Services**: Geolocator package
- **HTTP Requests**: HTTP package
- **Maps**: Google Maps Flutter
- **State Management**: Provider pattern
- **UI**: Material Design 3

## Project Structure

```
lib/
├── main.dart                 # App entry point and initialization
├── models/
│   └── bus_model.dart       # Bus and BusStop data models
├── providers/
│   ├── auth_provider.dart   # Authentication state management
│   └── location_provider.dart # GPS and location state management
├── screens/
│   ├── login_screen.dart    # Login screen with form validation
│   ├── signup_screen.dart   # Registration screen
│   └── dashboard_screen.dart # Main dashboard after login
├── services/
│   ├── auth_service.dart    # Firebase authentication logic
│   ├── location_service.dart # GPS and location utilities
│   └── api_service.dart     # Backend API communication
└── widgets/
    ├── bus_selector.dart    # Bus selection widget
    ├── gps_toggle.dart      # GPS tracking toggle
    ├── sos_button.dart      # Emergency SOS button
    └── eta_display.dart     # ETA calculation display
```

## Getting Started

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.0.0 or higher
2. **Firebase Project**: Create a Firebase project for authentication
3. **Android Studio / VS Code**: IDE with Flutter plugins
4. **Device/Emulator**: Android device or emulator for testing

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd driverapp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional for development):
   - Create a Firebase project
   - Add Android/iOS apps to Firebase
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place config files in appropriate directories

4. **Configure permissions**:
   - Android permissions are already configured in `android/app/src/main/AndroidManifest.xml`
   - For iOS, add location permissions to `ios/Runner/Info.plist`

5. **Run the application**:
   ```bash
   flutter run
   ```

## Configuration

### API Endpoints

The app currently uses dummy API endpoints. Update the following in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://your-backend-api.com';
```

### Location Settings

Modify location accuracy and update intervals in `lib/services/location_service.dart`:

```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10, // Update every 10 meters
);
```

### Mock Data

Bus routes and stops are defined in `lib/models/bus_model.dart`. Update the `MockBusData` class with real bus information.

## Key Features Implementation

### GPS Tracking
- Uses `geolocator` package for real-time location
- Sends location updates every 30 seconds when tracking is enabled
- Handles location permissions and error states
- Background location tracking capability

### SOS Emergency System
- Large, accessible emergency button
- Confirmation dialog to prevent accidental activation
- Immediate location transmission to backend
- Visual and text feedback on success/failure

### ETA Calculation
- Calculates distance to next bus stop using GPS coordinates
- Estimates arrival time based on average bus speed (40 km/h)
- Updates in real-time as location changes
- Displays route progress information

### Authentication Flow
- Email/password authentication with Firebase
- Form validation and error handling
- Automatic route management based on auth state
- Secure sign-out with tracking cleanup

## Backend Integration

The app is designed to work with a Node.js/Express backend. Required API endpoints:

- `POST /updateLocation` - Receive driver location updates
- `POST /sos/alert` - Handle emergency SOS alerts
- `GET /eta/:busNumber` - Get ETA information
- `POST /drivers/register` - Register driver with bus assignment

## Performance Considerations

- Location updates are throttled to prevent excessive API calls
- GPS tracking can be toggled on/off to save battery
- Efficient state management using Provider pattern
- Optimized UI with minimal rebuilds

## Production Deployment

1. **Update API endpoints** in `api_service.dart`
2. **Configure Firebase** with production keys
3. **Update app signing** for release builds
4. **Test on real devices** with actual GPS movement
5. **Enable location permissions** in production builds

## Error Handling

The app includes comprehensive error handling for:
- Network connectivity issues
- Location permission denials
- Firebase authentication errors
- API request failures
- GPS hardware unavailability

## Contributing

1. Follow Flutter/Dart coding standards
2. Maintain the clean, professional UI design
3. Add tests for new features
4. Update documentation for any changes
5. Ensure proper error handling

## License

This project is developed for Smart India Hackathon. All rights reserved.

## Support

For development support or questions:
- Check Flutter documentation: https://flutter.dev/docs
- Firebase documentation: https://firebase.google.com/docs
- Geolocator package: https://pub.dev/packages/geolocator