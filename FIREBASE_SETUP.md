# Firebase Setup Instructions

## 📱 **Flutter Firebase Configuration**

To complete Firebase setup in your Flutter app, you need to get the correct `google-services.json` file from Firebase Console.

### **Step 1: Download google-services.json**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `trackmyride123`
3. Click the **Android icon** to add Android app
4. Enter package name: `com.example.driver_app`
5. Click **Register app**
6. **Download google-services.json**

### **Step 2: Replace Configuration File**

1. Replace the placeholder file at:
   ```
   frontend/android/app/google-services.json
   ```
2. Use the real file you downloaded from Firebase Console

### **Step 3: Enable Firebase Services**

In Firebase Console, enable these services:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable Email/Password

2. **Firestore Database**
   - Go to Firestore Database
   - Create database in production mode

3. **Realtime Database**
   - Go to Realtime Database
   - Create database

### **Step 4: Test Flutter Firebase**

1. Run your Flutter app:
   ```bash
   cd frontend
   flutter run
   ```

2. Go to Settings → API Debug
3. Click "Test Firebase" button
4. Should show: ✅ Firebase initialized (trackmyride123)

### **Current Status**

- ✅ Firebase dependencies added to pubspec.yaml
- ✅ Firebase initialization enabled in main.dart
- ✅ Android build configuration updated
- ⚠️ Need real google-services.json file
- ✅ Firebase test added to debug screen

### **Next Steps**

1. Download real google-services.json from Firebase Console
2. Replace placeholder file
3. Test Firebase connection
4. Start end-to-end testing

---

**Important**: The current google-services.json is a placeholder. You must replace it with the real file from Firebase Console for authentication to work.