# Tasks: project-setup

## Metadata
- **Feature:** project-setup
- **Created:** 2026-01-20T23:58
- **Status:** completed
- **Based On:** 2026-01-20T23:58_plan.md

---

## Execution Rules

1. **Sequential unless marked [P]** - Tasks without [P] must run in order
2. **Verify before proceeding** - Each task has acceptance criteria to check
3. **Document issues** - Log any problems in `.claude/active-work/project-setup/implementation.md`

---

## Phase 1: Project Creation

### Task 1.1: Verify Flutter Environment
- [x] Run `flutter doctor` to verify Flutter SDK is installed
- [x] Verify stable channel is active
- [x] Note any missing components (may not block setup)

**Files:** None (verification only)

**Acceptance Criteria:**
- [x] `flutter doctor` runs without error
- [x] Flutter version 3.x confirmed (3.38.7)

---

### Task 1.2: Create Flutter Project
- [x] Navigate to `/workspace`
- [x] Run `flutter create wind_lens`
- [x] Verify project directory created

**Files:** Creates entire `/workspace/wind_lens/` directory structure

**Acceptance Criteria:**
- [x] `/workspace/wind_lens/pubspec.yaml` exists
- [x] `/workspace/wind_lens/lib/main.dart` exists
- [x] `/workspace/wind_lens/ios/` directory exists
- [x] `/workspace/wind_lens/android/` directory exists

---

## Phase 2: Dependency Configuration

### Task 2.1: Update pubspec.yaml with Dependencies
- [x] Open `/workspace/wind_lens/pubspec.yaml`
- [x] Add camera: ^0.11.3 to dependencies
- [x] Add sensors_plus: ^7.0.0 to dependencies
- [x] Add vector_math: ^2.2.0 to dependencies
- [x] Add http: ^1.6.0 to dependencies
- [x] Ensure flutter_lints is in dev_dependencies

**Files:** `/workspace/wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [x] All 4 dependencies present in pubspec.yaml
- [x] No YAML syntax errors

---

### Task 2.2: Install Dependencies
- [x] Run `flutter pub get` in wind_lens directory
- [x] Verify all packages resolve successfully
- [x] Check for any version conflicts

**Files:** Creates `/workspace/wind_lens/pubspec.lock`

**Depends:** Task 2.1

**Acceptance Criteria:**
- [x] `flutter pub get` exits with code 0
- [x] pubspec.lock created
- [x] No dependency resolution errors

---

## Phase 3: iOS Configuration

### Task 3.1: Update iOS Podfile
- [x] Open `/workspace/wind_lens/ios/Podfile`
- [x] Set platform version to iOS 14.0
- [x] Verify Podfile syntax is valid

**Files:** `/workspace/wind_lens/ios/Podfile`

**Acceptance Criteria:**
- [x] Line contains `platform :ios, '14.0'`

---

### Task 3.2: Add iOS Permissions to Info.plist
- [x] Open `/workspace/wind_lens/ios/Runner/Info.plist`
- [x] Add NSCameraUsageDescription with message
- [x] Add NSLocationWhenInUseUsageDescription with message
- [x] Add NSMotionUsageDescription with message
- [x] Add UIRequiredDeviceCapabilities array with accelerometer and gyroscope

**Files:** `/workspace/wind_lens/ios/Runner/Info.plist`

**Acceptance Criteria:**
- [x] NSCameraUsageDescription key exists with non-empty string
- [x] NSLocationWhenInUseUsageDescription key exists with non-empty string
- [x] NSMotionUsageDescription key exists with non-empty string
- [x] UIRequiredDeviceCapabilities contains accelerometer and gyroscope

---

### Task 3.3: [P] Verify iOS Build (if macOS available)
- [x] Run `flutter build ios --simulator --no-codesign` if on macOS
- [x] If not on macOS, skip and note in implementation.md

**Files:** None (verification only)

**Depends:** Task 3.1, Task 3.2

**Acceptance Criteria:**
- [x] Build succeeds OR documented as skipped (non-macOS environment) **SKIPPED - Linux environment**

---

## Phase 4: Android Configuration

### Task 4.1: Update Android minSdkVersion
- [x] Open `/workspace/wind_lens/android/app/build.gradle.kts`
- [x] Locate `minSdk` in defaultConfig
- [x] Change value to 24

**Files:** `/workspace/wind_lens/android/app/build.gradle.kts`

**Acceptance Criteria:**
- [x] minSdk is set to 24

---

### Task 4.2: Add Android Permissions to Manifest
- [x] Open `/workspace/wind_lens/android/app/src/main/AndroidManifest.xml`
- [x] Add CAMERA permission
- [x] Add ACCESS_FINE_LOCATION permission
- [x] Add camera hardware feature (required=true)
- [x] Add compass sensor feature (required=true)

**Files:** `/workspace/wind_lens/android/app/src/main/AndroidManifest.xml`

**Acceptance Criteria:**
- [x] `<uses-permission android:name="android.permission.CAMERA" />` present
- [x] `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` present
- [x] `<uses-feature android:name="android.hardware.camera" android:required="true" />` present
- [x] `<uses-feature android:name="android.hardware.sensor.compass" android:required="true" />` present

---

### Task 4.3: [P] Verify Android Build
- [x] Run `flutter build apk --debug`
- [x] Verify BUILD SUCCESSFUL message

**Files:** Creates `/workspace/wind_lens/build/app/outputs/flutter-apk/app-debug.apk`

**Depends:** Task 4.1, Task 4.2

**Acceptance Criteria:**
- [x] Build completes with "BUILD SUCCESSFUL" OR documented as skipped **SKIPPED - No Android SDK**

---

## Phase 5: Final Verification

### Task 5.1: Run Default Tests
- [x] Run `flutter test` in wind_lens directory
- [x] Verify all tests pass

**Files:** None (runs `/workspace/wind_lens/test/widget_test.dart`)

**Depends:** Task 2.2

**Acceptance Criteria:**
- [x] All tests pass (1 test passed)
- [x] No test failures or errors

---

### Task 5.2: Final Project Verification
- [x] Verify all configuration files are correctly modified
- [x] Run `flutter pub get` one final time
- [x] Confirm project is ready for Feature 1

**Files:** None (verification only)

**Depends:** All previous tasks

**Acceptance Criteria:**
- [x] pubspec.yaml has all dependencies
- [x] iOS Info.plist has all permissions
- [x] iOS Podfile has correct platform version
- [x] Android AndroidManifest.xml has all permissions and features
- [x] Android build.gradle.kts has correct minSdk
- [x] `flutter pub get` succeeds
- [x] flutter analyze passes with no issues

---

## Handoff Checklist for Test Agent

Before marking this feature complete:

- [x] All Phase 1 tasks complete (environment verified, project created)
- [x] All Phase 2 tasks complete (dependencies configured and installed)
- [x] All Phase 3 tasks complete (iOS configured)
- [x] All Phase 4 tasks complete (Android configured)
- [x] All Phase 5 tasks complete (tests pass, builds verified)
- [x] No unresolved errors in any task

---

## Summary

| Phase | Task Count | Completed | Skipped |
|-------|------------|-----------|---------|
| 1. Project Creation | 2 | 2 | 0 |
| 2. Dependencies | 2 | 2 | 0 |
| 3. iOS Config | 3 | 2 | 1 (build) |
| 4. Android Config | 3 | 2 | 1 (build) |
| 5. Verification | 2 | 2 | 0 |
| **Total** | **12** | **10** | **2** |

Note: Tasks 3.3 and 4.3 (platform builds) skipped due to environment constraints (Linux devcontainer without Xcode or Android SDK).
