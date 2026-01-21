# Tasks: camera-feed

## Metadata
- **Feature:** camera-feed
- **Created:** 2026-01-21T00:18
- **Status:** implementation-complete
- **Based On:** 2026-01-21T00:18_plan.md

---

## Execution Rules

1. **Complete tasks in order** - Dependencies are already resolved in ordering
2. **[P] = Parallelizable** - Tasks marked [P] can run in parallel with other [P] tasks in same phase
3. **TDD Order** - Write tests first in Phase 2, then implement in Phase 3
4. **Mark completion** - Check boxes as you complete each item
5. **One task at a time** - Only one task should be "in progress" at any moment

---

## Phase 1: Directory Setup

### Task 1.1: Create Widget Directory
- [x] Create `lib/widgets/` directory
- [x] Verify directory exists

**Files:** `lib/widgets/` (directory)

**Acceptance Criteria:**
- [x] Directory exists at `/workspace/wind_lens/lib/widgets/`

---

### Task 1.2: Create Screens Directory
- [x] Create `lib/screens/` directory
- [x] Verify directory exists

**Files:** `lib/screens/` (directory)

**Acceptance Criteria:**
- [x] Directory exists at `/workspace/wind_lens/lib/screens/`

---

### Task 1.3: Create Test Directories [P]
- [x] Create `test/widgets/` directory
- [x] Create `test/screens/` directory
- [x] Verify directories exist

**Files:** `test/widgets/`, `test/screens/` (directories)

**Acceptance Criteria:**
- [x] Both test directories exist

---

## Phase 2: Tests (TDD - Write Tests First)

### Task 2.1: Write CameraView Widget Tests
- [x] Create `test/widgets/camera_view_test.dart`
- [x] Write test: "CameraView shows loading indicator initially"
- [x] Write test: "CameraView shows error when no camera available"
- [x] Write test: "CameraView shows error on permission denied"
- [x] Run tests (expect compilation errors until implementation)

**Files:** `test/widgets/camera_view_test.dart`

**Test Code Pattern:**
```dart
testWidgets('CameraView shows loading indicator initially', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CameraView()));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

**Acceptance Criteria:**
- [x] Test file created with 4 test cases (3 + onFrame callback test)
- [x] Tests compile after CameraView implementation
- [x] All tests pass after implementation

---

### Task 2.2: Write ARViewScreen Tests [P]
- [x] Create `test/screens/ar_view_screen_test.dart`
- [x] Write test: "ARViewScreen renders without crashing"
- [x] Write test: "ARViewScreen has black background"
- [x] Run tests (expect compilation errors until implementation)

**Files:** `test/screens/ar_view_screen_test.dart`

**Acceptance Criteria:**
- [x] Test file created with 3 test cases (2 + CameraView containment test)
- [x] Tests compile after ARViewScreen implementation
- [x] All tests pass after implementation

---

## Phase 3: Core Implementation

### Task 3.1: Implement CameraView Widget
- [x] Create `lib/widgets/camera_view.dart`
- [x] Import required packages (camera, flutter/material)
- [x] Create CameraView StatefulWidget class
- [x] Add optional `onFrame` callback parameter
- [x] Implement `_CameraViewState` with WidgetsBindingObserver mixin
- [x] Add state variables: `_controller`, `_isInitialized`, `_errorMessage`
- [x] Implement `initState()` - start initialization, add observer
- [x] Implement `dispose()` - dispose controller, remove observer
- [x] Implement `didChangeAppLifecycleState()` - handle pause/resume
- [x] Implement `_initCamera()` async method:
  - [x] Call `availableCameras()`
  - [x] Handle empty camera list
  - [x] Find back camera (or use first)
  - [x] Create CameraController with ResolutionPreset.high, enableAudio: false
  - [x] Call `controller.initialize()` in try/catch
  - [x] Log resolution on success: `debugPrint('Camera initialized, resolution: ...')`
  - [x] Set error message on CameraException
  - [x] Call `setState()` on completion
- [x] Implement `_getErrorMessage()` helper for error codes
- [x] Implement `build()` method:
  - [x] Show CircularProgressIndicator while loading
  - [x] Show error message with icon if error
  - [x] Show CameraPreview when initialized
- [x] Run `flutter analyze` on file

**Files:** `lib/widgets/camera_view.dart`

**Acceptance Criteria:**
- [x] Widget compiles without errors
- [x] `flutter analyze` passes
- [x] CameraView tests pass

---

### Task 3.2: Implement ARViewScreen
- [x] Create `lib/screens/ar_view_screen.dart`
- [x] Import camera_view.dart and material
- [x] Create ARViewScreen StatelessWidget
- [x] Implement `build()` method:
  - [x] Return Scaffold with no AppBar
  - [x] Set backgroundColor to Colors.black
  - [x] Add CameraView as body
- [x] Run `flutter analyze` on file

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] Screen compiles without errors
- [x] `flutter analyze` passes
- [x] ARViewScreen tests pass

---

## Phase 4: Integration

### Task 4.1: Update main.dart
- [x] Open `lib/main.dart`
- [x] Remove MyHomePage and _MyHomePageState classes
- [x] Update MyApp (or rename to WindLensApp):
  - [x] Change title to 'Wind Lens'
  - [x] Set dark theme: `theme: ThemeData.dark()`
  - [x] Remove debug banner: `debugShowCheckedModeBanner: false`
  - [x] Set home to ARViewScreen
- [x] Add import for ar_view_screen.dart
- [x] Run `flutter analyze`

**Files:** `lib/main.dart`

**Acceptance Criteria:**
- [x] main.dart compiles without errors
- [x] `flutter analyze` passes
- [x] App builds successfully

---

## Phase 5: Verification

### Task 5.1: Run Static Analysis
- [x] Run `flutter analyze` on entire project
- [x] Fix any warnings or errors
- [x] Verify clean output

**Acceptance Criteria:**
- [x] `flutter analyze` reports no issues

---

### Task 5.2: Run Unit Tests
- [x] Run `flutter test`
- [x] Verify all tests pass
- [x] Fix any failing tests

**Acceptance Criteria:**
- [x] All unit tests pass (8 tests)

---

### Task 5.3: Verify Build
- [x] Run `flutter build web` (Android SDK not available in CI environment)
- [x] Verify build completes successfully

**Acceptance Criteria:**
- [x] App builds without errors (web build verified)

---

### Task 5.4: Document Real Device Testing [P]
- [x] Note in implementation.md that real device testing required
- [x] List manual verification steps:
  - Camera feed displays fullscreen
  - Console shows "Camera initialized, resolution: WxH"
  - Permission denied shows friendly error
  - App backgrounding/resuming works

**Acceptance Criteria:**
- [x] Real device testing requirements documented

---

## Handoff Checklist for Test Agent

Before marking feature complete, verify:

- [x] All tasks in Phases 1-4 completed
- [x] `flutter analyze` passes (Task 5.1)
- [x] `flutter test` passes (Task 5.2)
- [x] App builds successfully (Task 5.3)
- [x] Real device testing documented (Task 5.4)

**Files Created:**
- `lib/widgets/camera_view.dart`
- `lib/screens/ar_view_screen.dart`
- `test/widgets/camera_view_test.dart`
- `test/screens/ar_view_screen_test.dart`

**Files Modified:**
- `lib/main.dart`
- `test/widget_test.dart`

**Next Command:** `/test camera-feed`
