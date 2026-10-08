# Implementation Plan: Manual Recipe Library with TRN Table View

**Branch**: `feature/001-manual-recipe-library` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-manual-recipe-library/spec.md`

## Summary

A Flutter app, with no network and no AI, in which the cook builds a recipe through "the counter"
(ingredients go on, steps take items off and put their result back), saves it to an on-device
SQLite library, and sees it as a Tabular Recipe Notation table. The domain logic (counter,
structural validator, exact quantities, table layout) is a pure Dart package tested without a
device; the app is a thin layer of screens and storage over it. Research found that Michael Chu's
own tables are laid out by combining depth rather than one column per step; the spec was amended
to match before tasks were generated ([research.md](research.md) R5).

## Technical Context

**Language/Version**: Dart 3.13.5 with Flutter 3.47.6 stable (R1)

**Primary Dependencies**: drift 2.35.x, drift_flutter 0.3.1, path_provider 2.1.x (R3, R4);
flutter_riverpod 3.4.x (R7). Dev: drift_dev 2.35.x, build_runner 2.16.x, flutter_lints 6.0.0 (R13)

**Storage**: SQLite on the device through drift, schema written in SQL; database in the platform
application support directory, included in platform backup (R4, [data-model.md](data-model.md))

**Testing**: `package:test` for the core; `flutter_test` widget and golden tests;
`integration_test` on the Galaxy S24 (R11)

**Target Platform**: Android 24 to 37 and iOS 15 to 27, Flutter 3.47's documented range (R2)

**Project Type**: mobile app plus a pure Dart domain package, in one pub workspace

**Performance Goals**: search results within 1 second at 500 recipes (SC-004); editing and table
display feel immediate on the S24

**Constraints**: fully offline (FR-023); no data leaves the device except platform backup (FR-026,
Principle VII); follows system text size (FR-028); backup data under 25 MB (R4)

**Scale/Scope**: one user per device; hundreds of recipes; about five screens (library, recipe
table, editor, step input picker, about)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Checked against constitution **v1.1.0**.

| Principle | Status | How this plan complies |
|---|---|---|
| I. Model suggests, validator decides | Pass | No model in 001. The validator is built here as plain code with a fixture suite any later implementation must pass (R8, [contracts/validation.md](contracts/validation.md)); drafts give failed imports their landing place (FR-018). |
| II. Quality measured | N/A in 001 | No conversion yet. The SC-002 reference recipes and fixture format are the seed of the test set. |
| III. Cost tracked | N/A in 001 | No paid calls. |
| IV. Structure is the recipe | Pass | Table always derived by `layout()`; manual entry validated by the same rules imports will be (FR-005, FR-011). |
| V. Works without AI | Pass | Everything in 001 is offline and model-free (FR-023). |
| VI. Respect the source | Pass | `source_ref` stored; Chu credited (FR-025). Reference fixtures are written by the owner, not copied from cookbooks or Chu's site. R14 records the open notation question. |
| VII. User owns their data | Pass | On-device storage; only platform backup leaves, as v1.1.0 permits (R4); no secrets, no analytics; crash reporting is not added in 001. |
| VIII. One codebase, both platforms | Pass | One Flutter codebase; hosted macOS build on demand; first iOS milestone check at the end of 001 (quickstart). |
| IX. Test-first | Pass | Core is pure and test-first; storage tested in memory; renderer by goldens; device behavior by integration tests (R11). |
| X. Spec before code | Pass | R5 required changing FR-012, FR-016, US1 scenario 4 and US2 scenario 3. The owner approved and the spec was amended first (Clarifications, plan research session), before any task or code. |
| XI. Evidence over assumption | Pass | Every version and platform fact in research.md cites its source and date; iOS backup location is flagged for device confirmation. |

**Gate result**: passes. No violations requiring the Complexity Tracking table.

**Post-design re-check** (after data-model and contracts): unchanged. The design adds no network
access, no secret, and no storage outside the application support directory.

## Project Structure

### Documentation (this feature)

```text
specs/001-manual-recipe-library/
├── spec.md
├── plan.md              # this file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── core-api.md
│   ├── layout.md
│   ├── validation.md
│   └── recipe-document.schema.json
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2, created by /speckit-tasks
```

### Source Code (repository root)

```text
pubspec.yaml                     # pub workspace root: lists app and packages/trn_core
analysis_options.yaml            # flutter_lints + strict modes, shared (R13)

packages/trn_core/               # pure Dart; CI fails on any Flutter import (R8)
├── lib/
│   ├── trn_core.dart            # public exports
│   └── src/
│       ├── document.dart        # recipe document model
│       ├── quantity.dart        # exact rational quantities (R9)
│       ├── counter.dart         # available(), addStep(), moveStep(), splitPortion() ...
│       ├── validation.dart      # validate() and violation codes
│       └── layout.dart          # layout() -> TableGrid (R5, R6)
└── test/
    ├── fixtures/validation/     # *.recipe.json + *.expected.json pairs
    ├── fixtures/reference/      # the SC-002 reference recipes
    └── *_test.dart

app/                             # Flutter application
├── lib/
│   ├── main.dart
│   ├── data/
│   │   ├── schema.drift         # tables and queries, in SQL
│   │   ├── database.dart        # drift database, foreign_keys pragma, location (R4)
│   │   └── recipe_repository.dart  # whole-recipe save in one transaction; search
│   ├── state/                   # Riverpod providers
│   ├── ui/
│   │   ├── library/             # list and search
│   │   ├── table/               # TableGrid renderer
│   │   ├── editor/              # counter, steps, split, insert, move
│   │   └── about/               # Chu credit
│   └── l10n/                    # English strings (R15)
├── test/                        # widget tests, in-memory database, goldens (tag: golden)
├── integration_test/            # S24 flows: airplane mode, force close, backup
├── android/                     # allowBackup and dataExtractionRules (R4)
└── ios/

.github/workflows/
├── ci.yml                       # job "Build & test", Ubuntu (R12)
└── ios-build.yml                # manual, macOS, unsigned build
```

**Structure Decision**: a pub workspace with the Flutter app in `app/` and the domain in
`packages/trn_core/`. The split is the main architectural decision of this plan: the rules that
Principles I and IV care most about live where no screen, database or platform can reach them, and
where a future backend implementation can be held to the same fixtures.

## Owner decisions (2026-10-08)

1. **Layout correction (R5)**: approved; spec amended.
2. **Application id**: `io.github.dnoeltx.recipes` for Android, and the same for the iOS bundle id
   (R16).

## Complexity Tracking

No constitution violations to justify.
