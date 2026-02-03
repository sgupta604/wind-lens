# Tasks: Compass Widget Bugs (BUG-008)

## Metadata

| Field | Value |
|-------|-------|
| Feature | compass-widget-bugs |
| Type | Bug Fix |
| Timestamp | 2026-02-03T19:57 |
| Status | complete |
| Based On | 2026-02-03T19:57_plan.md |

---

## Execution Rules

1. Complete tasks in order (dependencies exist between phases)
2. Tasks marked with `[P]` can run in parallel with other `[P]` tasks in same phase
3. Mark checkbox `[x]` when subtask complete
4. All 375 existing tests must pass before marking phase complete
5. Bug 2 investigation only proceeds if device testing confirms issue

---

## Phase 1: Setup

### Task 1.1: Verify Current State
- [x] Read current `ar_view_screen.dart` position code (line 260)
- [x] Confirm current offset is `bottomPadding + 76`
- [x] Note any recent changes to positioning

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] Current position code identified
- [x] Ready to proceed with fix

---

## Phase 2: Implementation

### Task 2.1: Fix Compass Position (Bug 1)
- [x] Change line 260 in `ar_view_screen.dart`
- [x] Update from `bottom: bottomPadding + 76` to `bottom: bottomPadding + 92`
- [x] Update comment to reflect new calculation
- [x] Run `flutter analyze lib/` to verify no issues

**Files:** `lib/screens/ar_view_screen.dart:260`

**Change:**
```dart
// Before:
bottom: bottomPadding + 76, // 16px margin + ~60px InfoBar height

// After:
bottom: bottomPadding + 92, // BUG-008: 16px margin + ~60px InfoBar height + 16px gap
```

**Acceptance Criteria:**
- [x] Offset changed to 92
- [x] Comment updated
- [x] No analyzer issues

---

## Phase 3: Verification

### Task 3.1: Run Test Suite [P]
- [x] Run `flutter test` in wind_lens directory
- [x] Verify all 375 tests pass
- [x] Document any failures

**Files:** All test files

**Acceptance Criteria:**
- [x] All 375 tests pass
- [x] No regressions

### Task 3.2: Static Analysis [P]
- [x] Run `flutter analyze lib/`
- [x] Verify no issues found
- [x] Document any warnings

**Files:** All lib files

**Acceptance Criteria:**
- [x] Zero analyzer issues
- [x] Zero warnings

---

## Phase 4: Bug 2 Investigation (Conditional)

> **Note:** Based on code analysis, the compass rotation IS working correctly.
> The screenshot shows correct rotation for heading 137.9 degrees.
> No fix needed for Bug 2.

### Task 4.1: Verify Heading Data Flow
- [x] Verified `_heading` variable declaration (line 49)
- [x] Verified compass subscription (line 99)
- [x] Verified `_onCompassUpdate` handler with setState (lines 113-127)
- [x] Verified heading passed to CompassWidget (line 261)
- [x] **RESULT:** Data flow is correct, compass rotation works as designed

**Files:** `lib/screens/ar_view_screen.dart`, `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] Data flow verified correct
- [x] Rotation logic verified correct (canvas.rotate applied)
- [x] shouldRepaint correctly compares heading values

---

## Phase 5: Ready for Test Agent

### Task 5.1: Final Verification
- [x] All tests passing (375)
- [x] No analyzer issues
- [x] Position fix implemented
- [x] Bug 2 status documented (working correctly per code analysis)

**Acceptance Criteria:**
- [x] Build succeeds
- [x] All tests pass
- [x] Ready for device testing

---

## Handoff Checklist

Before running `/test compass-widget-bugs`:

- [x] Phase 1 complete (setup)
- [x] Phase 2 complete (implementation)
- [x] Phase 3 complete (verification - tests + analysis)
- [x] Phase 4 documented (Bug 2 status - working correctly)
- [x] Phase 5 complete (final verification)

**Expected Test Results:**
- All 375 existing tests pass

**Manual Testing Required:**
1. Deploy to device
2. Verify compass has gap above InfoBar
3. Rotate device and verify compass rotates with heading
4. Screenshot comparison before/after

---

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| 1. Setup | 1 | complete |
| 2. Implementation | 1 | complete |
| 3. Verification | 2 | complete |
| 4. Bug 2 Investigation | 1 | complete (no fix needed) |
| 5. Ready | 1 | complete |

**Total Tasks:** 6 completed

**Implementation Time:** ~10 minutes

**Risk:** Low (isolated change, comprehensive tests passing)
