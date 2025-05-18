# Ride Sharing App (Flutter)
A user-friendly ride-sharing mobile application built using Flutter and backed by Firebase.
The app enables users to either offer rides or search for available rides heading toward a desired destination. It emphasizes simplicity, user safety, and real-time interaction.


# Features
- User Signup/Login
- Immutable Profile Fields: Name, Email, Gender, ID Proof
- Offer a Ride: Set location, time, co-passenger prefs
- Get a Ride: Search and request rides
- Emergency Call & Contact Developer
- Post-ride Rating System
- Firebase Firestore for real-time data

# Tech Stack
- Flutter (Frontend)
- Firebase (Firestore, Auth, Storage)
- Google Maps API (optional)


---
## 🔧 Initial Setup

### Prerequisites

- Flutter SDK installed
- Android Studio or VS Code
- Firebase Console access
- Device/emulator for testing

### Firebase Configuration

1. Create a Firebase Project
2. Add your Android app and download `google-services.json`
3. Place the file inside `android/app/`
4. Enable Authentication, Firestore, and Storage
5. Configure Android build settings for Firebase integration

### Location Permissions

- Add location permissions in Android `AndroidManifest.xml`
- add API keys in  `AndroidManifest.xml`
- Request runtime location access using Flutter packages

---

### Run the App

```bash
flutter pub get
flutter run
```
---
You can [download the latest APK here](https://drive.google.com/file/d/1J7JYM6QQZUBI_fG_UZQTzmSFffTcYGH1/view?usp=sharing).

