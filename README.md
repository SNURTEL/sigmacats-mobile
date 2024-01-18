## Quickstart guide

### Prerequisites
- You will need Dart & Flutter to run the app. Check the installation guide [here](https://docs.flutter.dev/get-started/install.) Dart SDK should be installed along with Flutter SDK.
- If you are using Android Studio, you may need to manually setup SDK paths. Find the Flutter SDK install path by `flutter doctor -v` and set it as **both** Dart and Flutter SDK path in IDE settings.
- Before running the app, you will need to copy `.env.sample` to `.env`. You may want to configure backend URL and upload port in the envfile.
- \[Android\] [Android Studio](https://developer.android.com/studio) or [Android SDK standalone](https://developer.android.com/tools) (not recommended)
- \[iOS\] [Xcode](https://developer.apple.com/xcode/) and [iOS SDK](https://developer.apple.com/ios/)

### Install requirements

```shell
flutter pub get
```

### Build the app

```shell
# Android
flutter build apk 

# iOS
flutter build ipa
```

### Install on an Android device
```shell
adb install <path/to/apk>
```

### Install on an iOS device

Use Xcode or refer to [guides](https://forums.developer.apple.com/forums/thread/124115)

### NOTE

Please kindly ignore the "LICENSE VALIDATION ERROR" toast on app startup. This app uses a non-free [flutter_background_geolocation](https://pub.dev/packages/flutter_background_geolocation) plugin which requires a license in Android release builds - despite that, it shows the toast in debug builds as well.