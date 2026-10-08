# Research: Manual Recipe Library with TRN Table View

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-08

Every version and platform fact below was taken from a primary source on 2026-10-08 (constitution
Principle XI): release feeds, package registry APIs, the GitHub releases API, or official platform
documentation. Sources are named in each entry. Re-verify before relying on a version later.

## R1. Toolchain: Flutter and Dart

- **Decision**: Flutter **3.47.6** (stable), which bundles Dart **3.13.5**. `pubspec.yaml` declares
  `sdk: ^3.13.0`. CI pins the same Flutter version.
- **Source**: Flutter release feed `releases_windows.json` (current stable hash resolves to 3.47.6,
  released 2026-10-01, `dart_sdk_version` 3.13.5).
- **Alternatives considered**: tracking the `stable` channel unpinned. Rejected: an unpinned SDK
  makes a build from last month unreproducible, and CI and the owner's machine could disagree.

## R2. Supported platform versions

- **Decision**: keep the minimums `flutter create` generates for 3.47, which Flutter documents as
  Android **24 to 37** and iOS **15 to 27**. Do not raise them without a reason recorded here.
- **Source**: docs.flutter.dev "Supported deployment platforms", last updated 2026-09-22, stating
  it reflects Flutter 3.47.
- **Note**: the owner's Galaxy S24 and the iPhone available for milestone checks are both well
  inside these ranges.

## R3. Local storage: drift over SQLite, written in SQL

- **Decision**: **drift 2.35.x** with **drift_flutter 0.3.1** and **drift_dev 2.35.x** /
  **build_runner 2.16.x** for code generation. Schema and queries are written as SQL in `.drift`
  files; drift generates typed Dart from them.
- **Rationale**: the data is relational (recipe, ingredient, portion, step, step input) and the
  integrity rules are relational (an exclusive arc, ownership cascades). Writing the schema as real
  SQL keeps those rules in DDL, where they can be reviewed as such, rather than in an ORM's
  annotations. drift also provides schema versioning and migration tests, which the series already
  treats as a deliverable (ChecklistV1's data-preserving migration).
- **Finding worth recording**: `sqlite3_flutter_libs` is now published as `0.6.0+eol` with the
  description "Not used anymore, update to version 3.x of package:sqlite3 instead". Older drift
  tutorials still tell you to add it. The current drift setup page lists only `drift`,
  `drift_flutter`, and `path_provider`, and `drift_flutter` brings `sqlite3` 3.x itself. Do **not**
  add `sqlite3_flutter_libs` directly.
- **Sources**: pub.dev package API for `drift` (2.35.2, published 2026-10-07), `drift_dev`
  (2.35.1), `drift_flutter` (0.3.1), `sqlite3` (3.7.0), `sqlite3_flutter_libs` (0.6.0+eol),
  `build_runner` (2.16.2); drift.simonbinder.eu setup page.
- **Version note**: drift 2.35.2 was one day old at research time. The constraint `^2.35.0` admits
  it; if a regression appears, pin 2.35.1.
- **Alternatives considered**: `sqflite` (raw SQL strings, no generated types, no migration test
  support); a document store such as Hive or Isar (the data is relational and the rules are
  relational; a document store would move integrity checks into application code). Rejected.

## R4. Where the database lives, and platform backup (FR-026, SC-008)

- **Decision**: store the database in the platform **application support** directory
  (`getApplicationSupportDirectory`), passed to `driftDatabase(databaseDirectory: ...)`. Declare
  `android:allowBackup="true"` explicitly and provide `android:dataExtractionRules` with cloud
  backup and device transfer both enabled for the database. Do not mark anything excluded on iOS.
- **Android facts** (developer.android.com "Back up user data with Auto Backup", updated
  2026-02-26): apps targeting API 23+ participate automatically; `allowBackup` defaults to `true`
  but Google recommends setting it explicitly; included by default are files under `getFilesDir()`
  and `getDatabasePath()`; excluded are cache, code cache, and no-backup directories; the limit is
  **25 MB per app**; backup is end-to-end encrypted on Android 9+ when the user has a screen lock;
  apps targeting Android 12+ control rules through `dataExtractionRules`, with separate sections
  for cloud backup and device-to-device transfer.
- **iOS facts** (Apple File System Programming Guide, Tables 1-1 and 1-3): `Library/Application
  Support` is backed up by iCloud; `Library/Caches` and `tmp` are not. This is archived Apple
  documentation; the current page could not be read as text. It is to be confirmed on a real
  iPhone at the first iOS milestone (Principle VIII).
- **Why application support rather than documents**: `drift_flutter` defaults to the documents
  directory. On iOS, documents can be exposed to the user in the Files app, where a database file
  can be moved or deleted by hand. Application support is backed up the same way and is private to
  the app. The drift setup page's own example uses application support.
- **Size check**: a text-only recipe is a few kilobytes, so 25 MB holds thousands of recipes. Photos
  are out of scope for 001; when photo import arrives (spec 005), images must not go into this
  budget unexamined.
- **Verification**: SC-008 on Android uses `adb shell bmgr backupnow <package>`, uninstall,
  reinstall, and restore; on iOS it is a manual milestone check.

## R5. TRN table layout: how the table is actually drawn

This is the most important finding of the research, and it changes two requirements in the spec.

- **What the spec says now**: FR-012 places steps as columns in the recipe's step order, and FR-016
  draws preparation steps as full-height columns at their position.
- **What Tabular Recipe Notation actually does**: the HTML of Michael Chu's own tables on
  cookingforengineers.com (Simple Tiramisu, recipe 26; Avocado Pork Stuffed Peppers, recipe 12) was
  downloaded and its cell spans parsed. It shows:
  1. **Columns are by combining depth, not by step.** Independent steps share a column. In the
     tiramisu, "mix & chill" (espresso, coffee), "whisk to stiff peaks" (cream) and "mix"
     (mascarpone, sugar, rum) all sit in the same second column, in different rows.
  2. **A step sits one column to the right of its deepest input.** Shallower inputs are padded with
     empty cells. Lady's fingers are padded by one empty cell so that "dip" lines up to the right
     of "mix & chill"; cocoa powder is padded across two columns to reach "layer & spread twice".
  3. **Preparation steps are full-width rows at the top**, not full-height columns: "Preheat oven
     to 350 F" is a single row spanning all seven columns above the ingredients.
- **Why it matters here**: the table's width becomes the depth of the recipe, not its number of
  steps. The tiramisu has 8 steps but is 5 columns wide. That directly serves FR-014, FR-028 and
  SC-006 (readable upright, at large text sizes). It also makes the app's tables look like the
  format people already know.
- **Decision (approved by the owner 2026-10-08; spec amended first, Principle X)**: amend FR-012, FR-016, US1
  scenario 4 and US2 scenario 3 to the depth-based layout described in
  [contracts/layout.md](contracts/layout.md). Step order is still stored, still used for editing,
  and still breaks ties in row order; the table simply does not spend a column per step.
- **Alternatives considered**: one column per step, as currently specified. Simpler to draw but
  wider than necessary, unlike the original format, and in conflict with the readability goals.

## R6. Row order algorithm (FR-013)

- **Decision**: build the tree from the final step. Order each step's inputs by the earliest
  ingredient entry position found beneath them, then read the leaves depth-first. Every step's
  inputs are then adjacent by construction, and entry order is kept wherever the tree allows.
- **Rationale**: a depth-first leaf order of any tree makes every subtree a contiguous run of rows,
  which is exactly FR-013. Sorting children by earliest entry position is a deterministic tie
  rule the cook can predict.
- **Alternatives considered**: searching for the arrangement closest to entry order by some
  distance measure. Rejected: more complex, and no clearer to the cook.

## R7. State management and navigation

- **Decision**: **flutter_riverpod 3.4.x** for state, without code generation. Flutter's built-in
  `Navigator` for navigation (about five screens; a routing package is not yet earned).
- **Rationale**: Riverpod's provider overrides let widget tests swap the real database for an
  in-memory one without a dependency injection framework, which is what test-first UI work needs
  (Principle IX). Skipping its code generator keeps one generator (drift's) in the build.
- **Sources**: pub.dev API, `flutter_riverpod` 3.4.3 (2026-09-03, requires Dart ^3.12.0);
  `go_router` 18.0.2 considered and deferred.
- **Alternatives considered**: plain `ChangeNotifier` (workable, but test overrides become manual
  plumbing); Bloc (more ceremony than five screens justify).

## R8. Pure Dart core, and one rule set across two runtimes later

- **Decision**: the recipe model, the counter, the structural validator, quantity arithmetic, and
  the layout algorithm live in a **pure Dart package** (`packages/trn_core`) with no Flutter import.
  CI fails if one appears. The validator's rules are also expressed as a shared fixture suite:
  JSON recipe documents ([contracts/recipe-document.schema.json](contracts/recipe-document.schema.json))
  paired with the exact violations expected ([contracts/validation.md](contracts/validation.md)).
- **Rationale**: the core is tested in milliseconds without a device, the same pattern as
  CustomBinauralBeats' `:core` module. Looking ahead, spec 004 needs validation on the backend,
  which will not run Dart. Principle I and FR-011 demand **one** rule set. The fixture suite is how
  two implementations can be held to the same rules: both must pass every fixture. Whether spec 004
  reuses the Dart code compiled for the server or writes a second implementation is spec 004's
  decision; the fixtures make either one checkable.

## R9. Quantities: exact fractions

- **Decision**: store quantities as an exact rational (integer numerator and denominator) plus the
  form the cook typed it in (whole, fraction, mixed number, or decimal). Arithmetic for FR-008's
  add-up check is exact.
- **Rationale**: "1/3 cup" split into thirds must add up exactly; floating point cannot represent
  1/3. Keeping the entered form satisfies FR-002 ("preserve fractions as entered") and gives spec
  002's scaling exact arithmetic for free.

## R10. Text scaling (FR-028)

- **Decision**: never fix text size. Read the system scale through Flutter's `TextScaler` (the
  older `textScaleFactor` is documented as kept "only for backward compatibility" and slated for
  removal). Table cell sizes are computed from measured text, never from fixed pixel heights.
- **Verification**: widget and golden tests render the reference tables at scale 1.0 and at the
  largest standard setting; SC-006 is checked by hand on the S24 at both settings.
- **Source**: api.flutter.dev, `TextScaler` class.

## R11. Testing approach

- **Core** (`packages/trn_core`): `package:test`; written first; includes the validation fixture
  suite and property-style tests (for example, every generated valid tree lays out with adjacent
  inputs).
- **App**: `flutter_test` widget tests against an in-memory drift database; **golden image tests**
  for the table renderer using the SC-002 reference recipes. Goldens are generated and compared on
  the Linux CI runner only, because font rendering differs across operating systems; locally they
  are run with the same tag excluded.
- **Device**: `integration_test` flows run on the S24 for SC-005 (airplane mode), SC-007
  (force-close cycles) and SC-008 (backup restore).
- **Non-vacuous tests**: each validator rule has a fixture that violates only that rule, so
  breaking any one rule's check fails exactly one fixture.

## R12. Continuous integration

- **Decision**: GitHub Actions, job named **`Build & test`** (the same name as the series' other
  repositories, so branch protection is configured the same way). Ubuntu runner: analyze, core
  tests, app tests, goldens, debug Android build. A separate **manually triggered** macOS workflow
  builds iOS without signing, run at milestones (Principle VIII; hosted macOS minutes are not
  spent on every push).
- **Versions** (GitHub releases API): `actions/checkout` v7.0.1, `subosito/flutter-action` v2.23.0
  (2026-03-25), `actions/upload-artifact` v7.0.2 (2026-10-07; one day old, so pin v7.0.1 if it
  misbehaves).
- **Enabling the required check**: in the same pull request that introduces CI (constitution
  workflow section).

## R13. Lints

- **Decision**: `flutter_lints` 6.0.0 (what `flutter create` generates) plus the analyzer's strict
  modes `strict-casts`, `strict-inference`, `strict-raw-types`. Warnings fail CI.
- **Alternatives considered**: `very_good_analysis` 11.0.0. Stricter, but many of its rules are
  style preferences; reconsider once there is code to measure against.

## R14. Is the notation free to use? (open, not a blocker for 001)

- **Finding**: the cookingforengineers.com footer still reads "Tabular Recipe Notation Patent
  Pending (Michael Chu)". Forum posts on that site from 2005 and 2006 say an application was filed.
  No granted patent or application number was found in a search on 2026-10-08.
- **Reasoning, not a legal opinion**: a US utility patent runs at most 20 years from filing, so an
  application filed around 2004 to 2006 could not still be in force in 2026 even if it had been
  granted. A "pending" label on a page last designed years ago does not show a live application.
- **Action**: before anyone other than the owner uses the app, search the USPTO Patent Center by
  inventor name and record the result here. The in-app credit (FR-025) is required regardless.
- **Sources**: cookingforengineers.com page footer; cookingforengineers.com forum topic "Patent
  Pending?" (t=240).

## R15. Localization

- **Decision**: English only in 001. All user-visible strings go through Flutter's localization
  mechanism from the start, so adding languages later means adding translation files, not
  rewriting screens. Quantities and temperatures are shown as entered (no locale conversion).

## R16. Application id

- **Decision**: `io.github.dnoeltx.recipes` as the Android application id and the iOS bundle id.
- **Rationale**: changing an application id later makes the platforms treat the app as a different
  app, so it is effectively permanent. A neutral id that does not contain the product name leaves
  the name free to change ("TRN Recipe Saver" is a working name). The `io.github.<user>` prefix is
  a common convention for projects without their own domain.
- **Approved** by the owner 2026-10-08.
