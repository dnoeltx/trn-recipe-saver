# Quickstart: Validating Spec 001

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

How to prove the feature works, mapped to the spec's success criteria. Commands assume the layout
in [plan.md](plan.md) (a Dart pub workspace with `app/` and `packages/trn_core/`).

## Prerequisites

- Flutter **3.47.6** (Dart 3.13.5), per [research.md](research.md) R1. `flutter --version` must
  report it; `flutter doctor` shows no errors for the Android toolchain.
- The Android SDK already installed for the series' earlier apps.
- The Galaxy S24 with USB debugging on; `adb devices` lists it. `adb` is at
  `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe` (not on PATH).
- iOS checks need a hosted macOS CI run and the milestone iPhone session (Principle VIII); they are
  not part of the everyday loop.

## Setup

```powershell
flutter pub get                              # resolves the whole workspace from the root
cd app; dart run build_runner build; cd ..   # generates drift code from the .drift files
```

## Automated checks (also what CI's "Build & test" runs)

```powershell
flutter analyze                                    # zero warnings (R13)
cd packages/trn_core; dart test; cd ../..          # core: validator fixtures, layout invariants, counter
cd app; flutter test --exclude-tags golden; cd ..  # app widget tests on an in-memory database
```

Golden image tests run on the Linux CI runner only (R11): `flutter test --tags golden`.

| Criterion | Proven by |
|---|---|
| SC-002 reference recipes render as drawn by hand | layout tests on the five reference fixtures, plus goldens; the owner compares goldens with the hand-drawn tables once, then the goldens hold the line |
| SC-003 no complete recipe violates a rule | validator fixture suite ([contracts/validation.md](contracts/validation.md)); property test that `status` equals `validate(doc).isEmpty` after every save |
| SC-004 search under 1 second at 500 recipes | app test seeding 500 generated recipes and timing queries |

## On the S24

```powershell
cd app
flutter run -d <S24 device id>
flutter test integration_test -d <S24 device id>
```

| Criterion | Check |
|---|---|
| SC-001 typical recipe in under 10 minutes | owner enters a real 10-ingredient, 6-step recipe cold, timed |
| SC-005 airplane mode | integration flows run with airplane mode on |
| SC-006 readable upright, default and largest text | open the 15 by 10 reference recipe at default and at the largest standard text size; nothing cut off without a way to read it |
| SC-007 20 force-close cycles | integration test kills the app mid-entry 20 times; saved recipes compare equal |
| SC-008 backup restore | `adb shell bmgr backupnow <package>`, uninstall, reinstall, `adb shell bmgr restore`; every recipe present and equal ([research.md](research.md) R4) |

## At the iOS milestone

The everyday macOS workflow builds without signing, which proves the code compiles for iOS but
cannot be installed. Installing on the iPhone needs a signed build delivered through TestFlight,
which needs the Apple Developer Program membership; that setup is its own task before the first
iOS milestone. Then install on the iPhone and walk the same S24 table with the iOS
checklist: text size (Settings, Accessibility, Larger Text), backup location under Application
Support, and SC-006.
