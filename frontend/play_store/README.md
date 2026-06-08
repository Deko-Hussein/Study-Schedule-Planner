# Play Store Setup

Brand defaults in this repo:

- App name: `Study Planner`
- Bundle ID / Application ID: `com.studyplanner.app`
- Android release keystore path: `frontend/android/app/upload-keystore.jks`
- Android key properties file: `frontend/android/key.properties`

Generated store assets:

- App icon source: `frontend/assets/icon/icon.png`
- Adaptive foreground: `frontend/assets/branding/launcher_foreground.png`
- Splash icon: `frontend/assets/branding/splash_icon.png`
- Play Store icon: `frontend/play_store/play_store_icon_512.png`
- Feature graphic: `frontend/play_store/feature_graphic.png`
- Splash previews: `frontend/play_store/previews/`

Screenshots:

- Put real device screenshots in `frontend/play_store/screenshots/phone/`
- Recommended phone screenshots: at least 2, ideally 4 to 8
- Use actual app screens only; avoid mock screenshots for Play Store upload

Useful commands:

```powershell
cd frontend
dart run rename setAppName --targets android,ios,web,windows,macos --value "Study Planner"
dart run rename setBundleId --targets android,ios,macos --value "com.studyplanner.app"
powershell -ExecutionPolicy Bypass -File .\tool\generate_brand_assets.ps1
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build appbundle --release
```

Before release:

1. Replace `frontend/android/key.properties` with your private production values if needed.
2. Keep `upload-keystore.jks` backed up in a safe place.
3. Capture real screenshots from a physical device or emulator.
4. Upload the generated `.aab` from `frontend/build/app/outputs/bundle/release/`.
