# Driver App Frontend

Flutter mobile application for real-time bus tracking system.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Build APK**:
   ```bash
   flutter build apk --release
   ```

## 📱 Features

- **Teal Theme**: Consistent design with custom teal color scheme
- **Map Background**: Custom map image integration
- **Authentication**: Firebase Auth integration
- **Location Tracking**: Real-time GPS tracking
- **SOS Alerts**: Emergency alert system
- **Bus Management**: Bus assignment and tracking

## 🏗️ Project Structure

```
lib/
├── main.dart              # App entry point
├── models/               # Data models
├── providers/            # State management (Provider)
├── screens/              # UI screens
├── services/             # API and Firebase services
└── widgets/              # Reusable UI components
```

## 🎨 Theme

The app uses a custom teal color scheme:
- Primary: `#4A9B8E`
- Primary Light: `#6CB5A8`
- Primary Dark: `#3B8B7E`

## 🔧 Configuration

### Firebase Setup
1. Add your `google-services.json` to `android/app/`
2. Configure Firebase project in the backend
3. Update API endpoints in services

### API Integration
- Base URL: Configure in services/api_service.dart
- Endpoints: Authentication, Location, SOS, Bus management

## 📦 Dependencies

Key packages:
- `firebase_auth`: Authentication
- `provider`: State management
- `geolocator`: Location services
- `permission_handler`: Permissions
- `http`: API calls

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📱 Build & Deploy

### Android
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS
flutter build ios --release
```

## 🔧 Development

### Adding New Screens
1. Create screen in `lib/screens/`
2. Add to navigation in `main.dart`
3. Update state management if needed

### State Management
Using Provider pattern:
- Create provider in `lib/providers/`
- Add to main.dart providers list
- Use Consumer/Provider.of in widgets

### API Integration
- Add endpoints in `lib/services/api_service.dart`
- Handle responses and errors
- Update models as needed

## 🎯 Performance

- Optimized for smooth 60fps
- Efficient state management
- Lazy loading for large lists
- Proper memory management

## 📝 Notes

- Uses Material Design 3
- Supports dark/light themes
- Responsive design for different screen sizes
- Accessibility features included