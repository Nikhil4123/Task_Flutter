# TaskManager Firebase Production Deployment Guide

## 🚀 Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Enter project name: `task-manager-production`
4. Choose whether to enable Google Analytics
5. Click "Create project"

### 2. Configure Firebase Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:
   - Email/Password ✅
   - Anonymous ✅
3. Configure authorized domains for production

### 3. Set up Cloud Firestore
1. Go to **Firestore Database** → **Create database**
2. Choose **Start in production mode**
3. Select your preferred location
4. Set up the following security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read/write their own tasks
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### 4. Configure Firebase Cloud Messaging (FCM)
1. Go to **Project Settings** → **Cloud Messaging**
2. Generate Web Push certificate (for web notifications)
3. Download service account key for server-side notifications

## 📱 Platform Configuration

### Android Setup
1. In Firebase Console, click **Add app** → **Android**
2. Enter Android package name: `com.nikh.taskmanager`
3. Download `google-services.json`
4. Place file in `android/app/`
5. Ensure `android/app/build.gradle.kts` has:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### iOS Setup
1. In Firebase Console, click **Add app** → **iOS**
2. Enter iOS bundle ID: `com.nikh.taskmanager`
3. Download `GoogleService-Info.plist`
4. Add to iOS project in Xcode
5. Update iOS configuration for push notifications

### Web Setup
1. In Firebase Console, click **Add app** → **Web**
2. Enter app nickname: `TaskManager Web`
3. Copy configuration and update `firebase_options.dart`

## 🔑 Firebase Configuration

Update `lib/firebase_options.dart` with your actual Firebase project credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_ANDROID_API_KEY',
  appId: 'YOUR_ACTUAL_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_MESSAGING_SENDER_ID',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

## 🏗️ Build Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

### Production Builds

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

#### iOS (requires Xcode and Apple Developer Account)
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## 📦 Deployment

### Android - Google Play Store
1. Build app bundle: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Complete store listing
4. Submit for review

### iOS - App Store
1. Build iOS app: `flutter build ios --release`
2. Open in Xcode and configure signing
3. Archive and upload to App Store Connect
4. Complete store listing
5. Submit for review

### Web - Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase hosting
firebase init hosting

# Build web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## 🔒 Security Best Practices

### 1. Environment Variables
- Store sensitive keys in environment variables
- Use different Firebase projects for dev/staging/production
- Never commit API keys to version control

### 2. Firestore Security Rules
- Implement strict read/write permissions
- Validate data structure and types
- Use authentication-based access control

### 3. Authentication Security
- Enable email verification for production
- Implement proper password policies
- Use secure session management

## 📊 Monitoring & Analytics

### Firebase Analytics
1. Enable Google Analytics in Firebase Console
2. Track user engagement and app performance
3. Set up custom events for task operations

### Crashlytics
1. Add Firebase Crashlytics to `pubspec.yaml`
2. Initialize in main.dart
3. Monitor app stability in production

### Performance Monitoring
1. Enable Performance Monitoring in Firebase Console
2. Track app startup time and network requests
3. Monitor slow operations

## 🔄 CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.x'
    
    - run: flutter pub get
    - run: flutter test
    - run: flutter build web --release
    
    - name: Deploy to Firebase Hosting
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        projectId: your-project-id
```

## 🧪 Testing in Production

### Pre-deployment Checklist
- [ ] All Firebase services configured
- [ ] Security rules tested
- [ ] Authentication flows working
- [ ] Push notifications functional
- [ ] Data persistence verified
- [ ] Offline capabilities tested
- [ ] Performance optimized
- [ ] Error handling implemented

### Testing Scenarios
1. **User Registration & Login**
   - Email/password registration
   - Anonymous sign-in
   - Password reset functionality

2. **Task Management**
   - Create, read, update, delete tasks
   - Task filtering and searching
   - Real-time data synchronization

3. **Push Notifications**
   - Task reminder notifications
   - Background notification handling
   - Notification tap actions

## 📈 Post-deployment Monitoring

### Key Metrics to Track
- Daily/Monthly Active Users
- Task creation/completion rates
- App crash rate
- User retention
- Performance metrics

### Support & Maintenance
- Monitor Firebase usage quotas
- Regular security updates
- User feedback integration
- Feature usage analytics

---

## 🆘 Troubleshooting

### Common Issues
1. **Firebase initialization errors**: Check `firebase_options.dart` configuration
2. **Authentication failures**: Verify Firebase Auth setup and rules
3. **Data not syncing**: Check Firestore security rules and network connectivity
4. **Push notifications not working**: Verify FCM configuration and permissions

### Debug Commands
```bash
# Check Flutter doctor
flutter doctor

# Analyze code
flutter analyze

# Run tests
flutter test

# Check dependencies
flutter pub deps
```

For more help, check the [Firebase Documentation](https://firebase.google.com/docs) or create an issue in the repository.