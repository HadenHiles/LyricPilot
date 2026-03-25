# App Store Release Guide

This guide covers the steps to release **Lyric Pilot** to the Apple App Store (iOS) and Google Play Store (Android).

## Version Information

Current version is managed in `pubspec.yaml`:
- **Version**: 1.0.0+1 (format: `major.minor.patch+buildNumber`)

To update the version:
```yaml
version: 1.0.0+1  # Update both version string and build number
```

---

## Android Release (Google Play Store)

### Prerequisites

1. **Google Play Developer Account** - $25 one-time registration fee
2. **Keystore for signing** - A keystore file to sign your release builds

### Step 1: Create a Keystore

If you don't have a keystore yet, create one:

```bash
cd android
keytool -genkey -v -keystore ~/lyric-pilot-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lyric-pilot-key
```

**Important**: Keep your keystore file and passwords secure! If you lose them, you cannot update your app.

### Step 2: Configure Signing

1. Copy `android/key.properties.template` to `android/key.properties`:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` with your keystore details:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=lyric-pilot-key
   storeFile=/absolute/path/to/lyric-pilot-release.jks
   ```

   **Note**: Use absolute path for `storeFile` or path relative to `android/app` directory.

3. The `key.properties` file is already in `.gitignore` and will not be committed to git.

### Step 3: Build Release APK/AAB

Build an Android App Bundle (recommended for Play Store):

```bash
flutter build appbundle --release
```

Or build an APK:

```bash
flutter build apk --release --split-per-abi
```

The output files will be in:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-*-release.apk`

### Step 4: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app or select your app
3. Complete the store listing:
   - App name: **Lyric Pilot**
   - Short description (80 chars max)
   - Full description (4000 chars max)
   - Screenshots (phone, tablet, etc.)
   - App icon
   - Feature graphic
   - Category: Music & Audio
4. Upload your AAB file under "Release" → "Production"
5. Complete content rating questionnaire
6. Set up pricing & distribution
7. Submit for review

### App Details for Google Play

- **Application ID**: `com.lyricpilot.lyric_pilot`
- **Package Name**: Same as Application ID
- **Category**: Music & Audio
- **Content Rating**: Everyone (pending questionnaire)

---

## Alternative Android Distribution (Direct APK)

If you want to distribute outside of Google Play Store (to avoid the 20-user testing requirement), you can distribute the APK directly:

### Distribution Methods

1. **Direct Download from Website**
   - Host the APK on your own website or file hosting service
   - Provide a download link to users
   - Example services: GitHub Releases, Firebase App Distribution, Dropbox, Google Drive

2. **GitHub Releases** (Recommended)
   - Go to your repository on GitHub
   - Click "Releases" → "Create a new release"
   - Tag version (e.g., `v1.0.0`)
   - Upload `app-release.apk` as an asset
   - Publish release
   - Users can download directly from GitHub

3. **Firebase App Distribution**
   - Free service from Google
   - Invite testers via email
   - Automatic notifications for new releases
   - Visit: https://firebase.google.com/products/app-distribution

4. **Third-Party App Stores**
   - Amazon Appstore (requires separate submission)
   - Samsung Galaxy Store
   - F-Droid (for open-source apps)
   - APKPure, APKMirror (user-uploaded)

### Important: Installation Instructions for Users

When users download your APK, they'll need to:

1. **Enable "Unknown Sources" or "Install Unknown Apps"**:
   - Settings → Security → Unknown Sources (Android 7 and older)
   - Settings → Apps → Special Access → Install Unknown Apps (Android 8+)
   - Select the browser/app used to download and enable installation

2. **Download the APK** to their device

3. **Open the APK file** from Downloads or notification

4. **Tap "Install"** and follow prompts

### Security Warning Notice

Always inform users that your app is safe. Consider providing:
- SHA-256 hash of the APK for verification
- Clear instructions on where to download from
- Warning not to download from unofficial sources

### APK Location

After building, your signed release APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

You can also build split APKs per ABI (smaller file sizes):
```bash
flutter build apk --release --split-per-abi
```

This creates:
- `app-armeabi-v7a-release.apk` (older 32-bit devices)
- `app-arm64-v8a-release.apk` (modern 64-bit devices, most common)
- `app-x86_64-release.apk` (emulators, some tablets)

---

## iOS Release (Apple App Store)

### Prerequisites

1. **Apple Developer Account** - $99/year
2. **Development Team ID**: Already configured as `A3T2KUV3B5`
3. **Xcode** installed on macOS
4. **Valid distribution certificate and provisioning profile**

### Step 1: Configure App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app:
   - **Platform**: iOS
   - **Name**: Lyric Pilot
   - **Primary Language**: English
   - **Bundle ID**: `com.lyricpilot.lyricPilot` (already configured)
   - **SKU**: Create a unique identifier (e.g., `lyric-pilot-001`)
3. Complete app information:
   - Category: Music
   - Subcategory: Optional
   - Age rating
   - Content rights

### Step 2: Configure Code Signing in Xcode

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the **Runner** project in the navigator
3. Select the **Runner** target
4. Go to **Signing & Capabilities** tab
5. Ensure:
   - **Automatically manage signing** is checked (or)
   - **Manually manage signing** with:
     - **Team**: Select your team (A3T2KUV3B5 is already configured)
     - **Provisioning Profile**: Select "App Store" profile
     - **Signing Certificate**: "Apple Distribution"

6. Select **Product** → **Archive** to create an archive
   - Or use command line (see Step 3)

### Step 3: Build Release IPA

Build the iOS release from command line:

```bash
flutter build ipa --release
```

The IPA will be created in:
- `build/ios/archive/Runner.xcarchive`
- `build/ios/ipa/lyric_pilot.ipa`

### Step 4: Upload to App Store Connect

Using Xcode:
1. Open **Xcode** → **Window** → **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Choose **App Store Connect**
5. Follow the prompts to upload

Using command line (with Transporter or `xcrun altool`):
```bash
# This requires your archive to be exported first
xcrun altool --upload-app --type ios --file "build/ios/ipa/lyric_pilot.ipa" \
  --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

Or use [Transporter app](https://apps.apple.com/us/app/transporter/id1450874784) (GUI tool from Apple).

### Step 5: Submit for Review

1. In App Store Connect, go to your app
2. Select the version you uploaded
3. Complete all required metadata:
   - App Preview and Screenshots (various device sizes)
   - Description
   - Keywords
   - Support URL
   - Marketing URL (optional)
   - Privacy Policy URL
4. Add build to the version
5. Complete **App Review Information**:
   - Contact information
   - Demo account (if login required)
   - Notes for review
6. Click **Submit for Review**

### App Details for App Store

- **Bundle ID**: `com.lyricpilot.lyricPilot`
- **Display Name**: Lyric Pilot
- **Category**: Music
- **Target**: iOS 13.0+
- **Devices**: iPhone, iPad

---

## Testing Before Release

### Android

Test the release build locally:

```bash
flutter build apk --release
flutter install
```

Or use internal testing in Google Play Console:
1. Upload AAB to "Internal testing" track
2. Add test users
3. Test the release version

### iOS

Test with TestFlight:

1. Upload build to App Store Connect
2. Create a TestFlight group
3. Add internal testers (up to 100)
4. Testers install via TestFlight app
5. Gather feedback before public release

---

## Post-Release Checklist

- [ ] Monitor crash reports (Firebase Crashlytics, Play Console, App Store Connect)
- [ ] Respond to user reviews
- [ ] Track analytics and user engagement
- [ ] Plan next version features
- [ ] Update version number in `pubspec.yaml` for next release

---

## Common Issues

### Android

**Issue**: "keystore not found" error
- **Solution**: Check that `storeFile` path in `key.properties` is correct (absolute path)

**Issue**: Build fails with ProGuard errors
- **Solution**: Update `proguard-rules.pro` to keep necessary classes

### iOS

**Issue**: "No valid code signing identity found"
- **Solution**: Ensure you have a valid distribution certificate installed and selected

**Issue**: "Provisioning profile doesn't match"
- **Solution**: Regenerate provisioning profile in Apple Developer portal

---

## Resources

- [Flutter Deployment Docs](https://flutter.dev/docs/deployment)
- [Android: Sign your app](https://developer.android.com/studio/publish/app-signing)
- [iOS: Distribute an app through the App Store](https://developer.apple.com/ios/submit/)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)

---

## Version History

- **1.0.0+1** - Initial release (current)
