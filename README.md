# new_project

A 3D Flutter game — landscape only. Android + iOS.

This repo currently holds the **empty scaffold**: project config, a placeholder
home screen with the landscape lock already in place, and the GitHub Actions
workflow that builds the release APK. The game itself is built from the PRD.

## Structure

```
lib/main.dart              placeholder app + landscape/orientation lock
test/widget_test.dart      smoke test for the placeholder screen
.github/workflows/         build-apk.yml — builds app-release.apk on every push
pubspec.yaml               package config
```

## Running locally

```bash
flutter pub get
flutter create . --platforms=ios   # android/ and ios/ are generated, not committed
flutter run
```

The `android/` folder is deliberately **not** committed: the workflow generates
it in a throwaway project and copies only that folder in, so our own `lib/` and
`pubspec.yaml` can never be overwritten by `flutter create`.

## APK

Every push to `main` builds a release APK (Actions → Build APK → artifact
`release-apk`). Run the workflow manually (Actions → Build APK → Run workflow)
or push a `v*` tag to get the APK attached to a GitHub Release.
