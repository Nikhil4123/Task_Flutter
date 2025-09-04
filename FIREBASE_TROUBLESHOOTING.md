# 🔥 Firebase Configuration Troubleshooting

## ⚠️ **Current Issue: CONFIGURATION_NOT_FOUND**

The error you're seeing is related to Firebase Authentication configuration. Here's how to fix it:

### 📋 **Step-by-Step Fix**

#### **1. Firebase Console Configuration**

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. **Select your project: `todo-78efd`**
3. **Navigate to Authentication → Settings**

#### **2. Configure Authentication Providers**

**Email/Password Provider:**
1. Go to **Authentication → Sign-in method**
2. Click **Email/Password**
3. **Enable** the provider
4. **Enable** "Email link (passwordless sign-in)" if needed
5. Click **Save**

**Anonymous Provider:**
1. Still in **Sign-in method**
2. Click **Anonymous**
3. **Enable** the provider
4. Click **Save**

#### **3. Configure Authorized Domains**

1. In **Authentication → Settings**
2. Go to **Authorized domains**
3. Add these domains:
   ```
   localhost
   127.0.0.1
   todo-78efd.firebaseapp.com
   ```

#### **4. App Check Configuration (Important!)**

1. Go to **App Check** in Firebase Console
2. Click **Get started**
3. For **Android**:
   - Select your Android app
   - Choose **Play Integrity** or **SafetyNet**
   - Follow the setup instructions
4. For **Web** (if testing on web):
   - Select your web app
   - Choose **reCAPTCHA v3**
   - Add your domain

#### **5. reCAPTCHA Configuration**

1. Go to **Authentication → Settings**
2. Scroll to **App verification**
3. For **Phone number sign-in**:
   - Configure reCAPTCHA settings
   - Add your app's SHA-256 fingerprint

### 🔧 **Alternative Solutions**

#### **Option 1: Use Anonymous Authentication (Temporary)**

The app now includes a fallback to anonymous authentication. If email registration fails, it will automatically sign you in as a guest user.

#### **Option 2: Disable App Check (Development Only)**

**⚠️ Only for development/testing:**

1. In Firebase Console → App Check
2. Temporarily disable enforcement
3. **Remember to re-enable for production!**

#### **Option 3: Update Firebase Configuration**

Run this command to regenerate Firebase configuration:

```bash
flutterfire configure --project=todo-78efd
```

### 📱 **Testing the Fix**

1. **Try Anonymous Login First:**
   - Open the app
   - Click "Continue as Guest"
   - This should work immediately

2. **Try Email Registration:**
   - Use a test email like `test@example.com`
   - If it fails, you'll automatically be signed in as guest

3. **Check Firebase Console:**
   - Go to Authentication → Users
   - You should see your user account

### 🐛 **Common Error Messages & Solutions**

#### **"CONFIGURATION_NOT_FOUND"**
- **Cause**: App Check not configured or reCAPTCHA settings missing
- **Fix**: Follow App Check configuration above

#### **"No AppCheckProvider installed"**
- **Cause**: App Check not initialized
- **Fix**: Configure App Check in Firebase Console

#### **"X-Firebase-Locale header null"**
- **Cause**: Language setting issue
- **Fix**: Already handled in code with `setLanguageCode('en')`

### 🎯 **Quick Test Commands**

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Test on emulator
flutter run

# Build for phone
flutter build apk --release
```

### 📞 **If Still Having Issues**

1. **Check Firebase Console Logs:**
   - Go to your Firebase project
   - Check the logs for specific error details

2. **Verify Project ID:**
   - Ensure `todo-78efd` is correct in `firebase_options.dart`

3. **Check Network:**
   - Ensure internet connection is working
   - Try on different networks

4. **Use Anonymous Authentication:**
   - The app will fall back to guest mode automatically
   - You can still create and manage tasks

### ✅ **Success Indicators**

- **App loads without errors**
- **Can sign in anonymously**
- **Can create and view tasks**
- **Data syncs to Firebase**

The app is designed to work even with configuration issues by falling back to anonymous authentication. All core functionality (task management, real-time sync) will work perfectly!

---

**Need more help?** Check the Firebase Console documentation or the app logs for specific error details.