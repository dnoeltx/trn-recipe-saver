---

description: "Task list for spec 001: manual recipe library with TRN table view"
---

# Tasks: Manual Recipe Library with TRN Table View

**Input**: Design documents from `specs/001-manual-recipe-library/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: REQUIRED. Constitution Principle IX makes test-first mandatory everywhere. In every
phase, a test task precedes the implementation it covers and MUST be run and seen to fail before
that implementation starts. Where a test genuinely cannot come first, the pull request says why.

**Organization**: grouped by user story so each story can be built and checked on its own.

**Owner tasks**: tasks marked **(owner)** are run by the project owner personally: installs, git
and GitHub commands, purchases, and judgments only the owner can make (constitution workflow
section). Everything else may be prepared by AI assistance.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: the user story the task serves (US1 to US4)
- Paths are relative to the repository root, per the structure in [plan.md](plan.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: toolchain, workspace, lints, CI.

- [ ] T001 (owner) Install Flutter 3.47.6 (research R1); confirm `flutter --version` reports Flutter 3.47.6 and Dart 3.13.5, and `flutter doctor` reports no Android toolchain errors
- [ ] T002 (owner) Measure the S24's largest standard text size: set Settings, Display, Font size to its maximum standard step, run `adb shell settings get system font_scale` (adb at `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`), record the value in research R10, then restore your usual setting
- [ ] T003 Create the workspace root `pubspec.yaml`: `name: trn_workspace`, `publish_to: none`, `environment: sdk: ^3.13.0`, `workspace: [app, packages/trn_core]`
- [ ] T004 Create the Flutter app with `flutter create --org io.github.dnoeltx --project-name recipes --platforms android,ios app`; then in `app/pubspec.yaml` set `resolution: workspace` and `sdk: ^3.13.0`; confirm `applicationId` is `io.github.dnoeltx.recipes` in `app/android/app/build.gradle.kts` and `PRODUCT_BUNDLE_IDENTIFIER` is `io.github.dnoeltx.recipes` in `app/ios/Runner.xcodeproj/project.pbxproj` (research R16)
- [ ] T005 Create the pure Dart package with `dart create -t package packages/trn_core`; set `resolution: workspace`, `sdk: ^3.13.0`, and dev dependency `test`; remove the generated sample code in `packages/trn_core/lib/` and `packages/trn_core/test/`
- [ ] T006 [P] Add app dependencies in `app/pubspec.yaml`: `drift: ^2.35.0`, `drift_flutter: ^0.3.1`, `path_provider: ^2.1.6`, `flutter_riverpod: ^3.4.3`, `flutter_localizations` (sdk), and dev dependencies `drift_dev: ^2.35.0`, `build_runner: ^2.16.1`, `integration_test` (sdk). Do NOT add `sqlite3_flutter_libs` (research R3: published as `0.6.0+eol`). Run `flutter pub get` at the root and confirm one `pubspec.lock` at the root
- [ ] T007 [P] Configure lints: `app/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`; `packages/trn_core/analysis_options.yaml` includes `package:lints/recommended.yaml`; both enable `strict-casts`, `strict-inference`, `strict-raw-types` (research R13). `flutter analyze` at the root reports no issues
- [ ] T008 [P] Extend `.gitignore` for the workspace: `.dart_tool/`, `build/`, generated `*.g.dart`; keep `drift_schemas/` tracked (research R3, data-model Migrations)
- [ ] T009 [P] Set up English localization: `app/l10n.yaml`, `app/lib/l10n/app_en.arb`, and `generate: true` in `app/pubspec.yaml` (research R15)
- [ ] T010 Write the core purity check as `tool/check_core_purity.ps1` and an equivalent shell step for CI: fail if `packages/trn_core/pubspec.yaml` depends on `flutter` or any file under `packages/trn_core/` imports `package:flutter`. Prove it is not vacuous: add a temporary `import 'package:flutter/widgets.dart';` to a core file, confirm the check fails, then remove it (research R8)
- [ ] T011 Write the no-network check `tool/check_no_network.ps1` and an equivalent CI shell step: fail if `app/android/app/src/main/AndroidManifest.xml` requests `android.permission.INTERNET`, or if any Dart file under `app/lib/` or `packages/trn_core/lib/` imports `package:http`, `package:dio`, or uses `HttpClient` (FR-023, Principle VII). First record which manifests `flutter create` adds that permission to (debug and profile builds need it for development tooling; the main manifest must not have it). Prove it is not vacuous: add the permission to the main manifest temporarily, confirm the check fails, then remove it
- [ ] T012 Create `.github/workflows/ci.yml` with one job named exactly `Build & test` on `ubuntu-latest`: `actions/checkout@v7.0.1`, `subosito/flutter-action@v2.23.0` with `flutter-version: 3.47.6`, `flutter pub get`, `dart run build_runner build` in `app/`, `flutter analyze`, the core purity check, the no-network check, `dart test` in `packages/trn_core/`, `flutter test` in `app/` (golden tests included on Linux), `flutter build apk --debug` in `app/` (research R12)
- [ ] T013 [P] Create `.github/workflows/ios-build.yml`, triggered only by `workflow_dispatch`, on a hosted macOS runner (confirm the current runner label at task time), running `flutter build ios --no-codesign` in `app/` (research R12, Principle VIII)
- [ ] T014 (owner) After the first CI run passes on this branch's pull request, require the `Build & test` check on `main` with `strict: true`, in the same pull request that introduces CI (constitution workflow section)

**Checkpoint**: the workspace builds, analyzes clean, and CI is green on an empty app.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the recipe document, exact quantities, the structural validator, storage, and the app
shell. Every user story needs all of them.

**⚠️ CRITICAL**: no user story work begins until this phase is complete.

### Quantities and the recipe document (packages/trn_core)

- [ ] T015 [P] Write failing tests in `packages/trn_core/test/quantity_test.dart`: `Quantity.parse` accepts `2`, `0.5`, `1/3`, `1 1/2` and rejects `abc`, `1/0`, empty; arithmetic is exact (`1/3 + 1/3 + 1/3 == 1`); `format()` returns the form entered (`whole`, `fraction`, `mixed`, `decimal`) (FR-002, research R9)
- [ ] T016 Implement `Quantity` as an exact rational with entered form in `packages/trn_core/lib/src/quantity.dart` until T015 passes
- [ ] T017 [P] Write failing tests in `packages/trn_core/test/document_test.dart` for the recipe document and its JSON form per `specs/001-manual-recipe-library/contracts/recipe-document.schema.json`: `schemaVersion` is `1`; ids match `^[a-z][a-z0-9_]*$`; `origin` is one of `manual`, `url`, `photo`; step `kind` is `combine` or `preparation`; each input has exactly one of `portion` or `step`; `time.maxSeconds` requires `time.seconds`; `temperature.unit` is `F` or `C`; an ingredient cannot have both `quantity` and `quantityText`; every ingredient has at least one portion; JSON round-trips to an equal document
- [ ] T018 Implement the document model and `fromJson`/`toJson` in `packages/trn_core/lib/src/document.dart` until T017 passes; export it from `packages/trn_core/lib/trn_core.dart`

### Reference recipes and validation fixtures

- [ ] T019 (owner) Choose five reference recipes covering the SC-002 shapes (a split ingredient, a preparation step, a two-component dish, a single-input step, and one with at least 15 ingredients); write their steps in the owner's own words so they can be committed (Principle VI); draw each as a TRN table by hand using the depth-based layout (FR-012)
- [ ] T020 Encode the five reference recipes as documents in `packages/trn_core/test/fixtures/reference/*.recipe.json`, each with an `*.expected.json` of `[]` (valid); keep the owner's drawings next to them only if the owner chooses to publish them, otherwise in `testdata/private/reference-drawings/`
- [ ] T021 [P] Write one violation fixture per code in `specs/001-manual-recipe-library/contracts/validation.md` in `packages/trn_core/test/fixtures/validation/`: `portion_unused`, `portion_reused`, `result_unused`, `result_reused`, `input_missing`, `input_not_earlier`, `combine_without_inputs`, `preparation_has_inputs`, `preparation_result_used`, `no_final_result`, `multiple_final_results`, `split_does_not_add_up`, `split_portion_not_numeric`. Each `<name>.recipe.json` violates that rule and no other; each `<name>.expected.json` lists the exact `{code, subjects}` multiset
- [ ] T022 Write the failing fixture runner `packages/trn_core/test/validation_fixtures_test.dart`: loads every pair under `fixtures/validation/` and `fixtures/reference/`, runs `validate()`, compares `{code, subjects}` as a multiset (messages excluded); plus `packages/trn_core/test/validation_messages_test.dart` asserting every violation's message names its subjects in plain language (FR-011)
- [ ] T023 Implement `validate(doc) -> List<Violation>` in `packages/trn_core/lib/src/validation.dart` with the codes and rules of `contracts/validation.md`, including reporting `no_final_result` instead of per-ingredient `portion_unused` when there are no combine steps, until T022 passes. It MUST NOT call a model or touch storage (Principle I)
- [ ] T024 Prove the fixture suite is not vacuous: disable each rule's check in turn and confirm exactly one fixture fails each time; record the result for the pull request description (Principle IX)

### Storage (app/lib/data)

- [ ] T025 [P] Write failing tests in `app/test/data/schema_test.dart` against an in-memory database, one per constraint in `specs/001-manual-recipe-library/data-model.md`: `PRAGMA foreign_keys` is on; `recipe.title` rejects blank (`trim(title) <> ''`); `recipe.status` only `IN ('complete','draft')`; `recipe.origin` only `IN ('manual','url','photo')`; `servings` `> 0`; ingredient `qty_num`, `qty_den` and `qty_form` all null or all present, `qty_den > 0`, `qty_form IN ('whole','fraction','mixed','decimal')`, `qty_text` null whenever `qty_num` is present; `step.kind IN ('combine','preparation')`; `dur_max_s` requires `dur_s` and `dur_max_s > dur_s`; `temp_unit IN ('F','C')` and null exactly when `temp_value` is null; `step_input` exclusive arc `CHECK ((portion_id IS NULL) <> (input_step_id IS NULL))` rejects both and neither; `UNIQUE` on `portion_id` and on `input_step_id` rejects a second use; `UNIQUE (recipe_id, position)` on ingredient and step; deleting a recipe cascades to all children; deleting a step deletes its own input rows and the later input row that used its result
- [ ] T026 Implement the schema in SQL in `app/lib/data/schema.drift` exactly as `data-model.md` specifies, and `app/lib/data/database.dart` with schema version 1, `PRAGMA foreign_keys = ON` on every open, and the database file in `getApplicationSupportDirectory()` passed to `driftDatabase(databaseDirectory: ...)` (research R4); run `dart run build_runner build` in `app/` until T025 passes
- [ ] T027 Export the version 1 schema to `app/drift_schemas/` with drift's schema export tool (confirm the current command in the drift documentation at task time) and commit it
- [ ] T028 [P] Write failing tests in `app/test/data/recipe_repository_test.dart`: every fixture document from T020 and T021 round-trips through save and load to an equal document; save sets `recipe.status` to `complete` exactly when `validate()` is empty, otherwise `draft` (FR-018, SC-003); a save that fails partway leaves the previously saved version intact (whole-recipe save in one transaction); delete removes the recipe and all its rows
- [ ] T029 Implement `app/lib/data/recipe_repository.dart` (`save`, `load`, `delete`, row and document mapping) until T028 passes

### App shell

- [ ] T030 [P] Write a failing widget test in `app/test/app_test.dart`: the app starts inside a `ProviderScope` with the database provider overridden by an in-memory database and shows the library screen's title from the English localization file
- [ ] T031 Implement `app/lib/main.dart` and `app/lib/state/providers.dart` (database and repository providers, overridable in tests), `MaterialApp` with localization delegates and `Navigator`, until T030 passes

**Checkpoint**: core rules proven by fixtures, storage proven by constraint tests, app launches.

---

## Phase 3: User Story 1 - Enter a recipe and see it as a TRN table (Priority: P1) 🎯 MVP

**Goal**: the cook enters ingredients, adds steps from the counter, saves, and sees the table.

**Independent Test**: enter the pancakes reference recipe on the S24 and compare the table with
the owner's drawing (spec US1).

### Tests for User Story 1 (write first, see them fail)

- [ ] T032 [P] [US1] Write failing tests in `packages/trn_core/test/counter_test.dart` for: `addIngredient` creates one whole portion that appears in `available()`; `addStep` at the end removes its inputs from the counter and adds its result; `addStep` with an input not on the counter returns a refusal naming the item (not an exception); `isComplete` is true exactly when one item remains and `validate()` is empty (FR-006, FR-007, FR-010)
- [ ] T033 [P] [US1] Write failing tests in `packages/trn_core/test/layout_test.dart` for combine-only recipes per `specs/001-manual-recipe-library/contracts/layout.md`: column count is H + 1; a step sits one column right of its deepest input; independent steps share a column; filler cells pad shallower inputs; row order follows the earliest-entry rule (FR-013); all five invariants hold on the combine-only reference fixtures and on randomly generated valid trees; laying out twice gives an equal grid
- [ ] T034 [P] [US1] Write failing widget tests in `app/test/ui/table/trn_table_test.dart`: cells are placed with the row and column spans of the grid; the ingredient column stays visible while scrolling horizontally (FR-014); step cells show action, time (with range and note) and temperature (FR-015); a step cell wraps to four lines and then ends with an ellipsis, and tapping it opens a sheet with the full text, time and temperature, returning to the same scroll position on close (FR-015, research R17); no overflow at text scale 1.0 and at the largest standard factor recorded in research R10 (FR-028)
- [ ] T035 [P] [US1] Write golden tests tagged `golden` in `app/test/ui/table/trn_table_golden_test.dart` for the combine-only reference recipes at text scale 1.0 and the largest standard factor recorded in research R10 (research R11)
- [ ] T036 [P] [US1] Write failing widget tests in `app/test/ui/editor/editor_screen_test.dart`: entering title and servings; adding ingredients shows them on the counter; the add-step picker offers only counter items (FR-007); after a step, its inputs leave the counter and its result appears; the completeness indicator lists unused items (FR-010); saving an incomplete recipe stores a draft and returns to the library (US1 scenario 7); saving a complete recipe opens its table; leaving with unsaved changes asks before discarding; invalid quantity text shows an error

- [ ] T037 [P] [US1] Write failing widget tests in `app/test/ui/table/recipe_screen_test.dart`: opening a complete recipe shows its title and table; a draft is never rendered as a table and opens the editor with its violations listed instead (FR-017, FR-018)

### Implementation for User Story 1

- [ ] T038 [US1] Implement `addIngredient`, `available`, `addStep` (end of order), `setInputs`, `isComplete` and refusal values in `packages/trn_core/lib/src/counter.dart` until T032 passes
- [ ] T039 [US1] Implement `layout(doc) -> TableGrid` for combine steps in `packages/trn_core/lib/src/layout.dart` (heights, earliest-entry row order, step and filler cells) until T033 passes
- [ ] T040 [US1] Implement the table renderer in `app/lib/ui/table/trn_table.dart`, sizing cells from measured text with the system `TextScaler`, never fixed heights (research R10), with the four-line wrap and full-text sheet (research R17), until T034 passes; generate and review the goldens of T035 on the Linux CI runner
- [ ] T041 [US1] Implement the recipe screen in `app/lib/ui/table/recipe_screen.dart`, opening a complete recipe to its table and sending a draft to the editor, until T037 passes
- [ ] T042 [US1] Implement the editor in `app/lib/ui/editor/editor_screen.dart`, `app/lib/ui/editor/ingredient_form.dart`, `app/lib/ui/editor/step_form.dart` (time as seconds, optional longer duration that must exceed it, optional note; temperature with F or C) and `app/lib/ui/editor/step_input_picker.dart`, with strings in `app/lib/l10n/app_en.arb`, until T036 passes
- [ ] T043 [US1] (owner) On the S24, enter the pancakes reference recipe and compare the table with the drawing; note anything that surprised you for the pull request

**Checkpoint**: MVP. A recipe can be entered, saved, and read as a TRN table.

---

## Phase 4: User Story 2 - Recipes that are not a simple chain (Priority: P2)

**Goal**: split ingredients and preparation steps.

**Independent Test**: enter the two-component reference recipe (split butter, preheat) and compare
with the drawing (spec US2).

### Tests for User Story 2 (write first, see them fail)

- [ ] T044 [P] [US2] Write failing tests in `packages/trn_core/test/counter_split_test.dart`: `splitPortion` replaces a counter portion with two or more; numeric portions must sum exactly to the original or the split is refused with the reason (FR-008); fewer than two parts is refused; a portion not on the counter is refused; a non-numeric ingredient ("salt, to taste") can be split into labeled portions; separated ingredients are not a split (spec Clarifications: entered as separate ingredients)
- [ ] T045 [P] [US2] Write failing tests in `packages/trn_core/test/counter_preparation_test.dart`: adding a preparation step leaves the counter unchanged; a preparation step cannot be given inputs (FR-009, US2 scenarios 1 and 4)
- [ ] T046 [P] [US2] Extend `packages/trn_core/test/layout_test.dart` with failing tests: preparation steps become full-width rows above the portion rows, in step order (FR-016); each split portion is its own row adjacent to the step that uses it (US2 scenario 2); all invariants hold on the split, preparation and two-component reference fixtures
- [ ] T047 [P] [US2] Write failing widget tests in `app/test/ui/editor/editor_split_test.dart` and extend `app/test/ui/table/trn_table_test.dart` and `trn_table_golden_test.dart`: the split action in the editor, the preparation step option, preparation rows and portion labels in the rendered table

### Implementation for User Story 2

- [ ] T048 [US2] Implement `splitPortion` and preparation steps in `packages/trn_core/lib/src/counter.dart` until T044 and T045 pass
- [ ] T049 [US2] Extend `packages/trn_core/lib/src/layout.dart` with preparation rows and split portions until T046 passes
- [ ] T050 [US2] Add the split action and preparation step option to the editor in `app/lib/ui/editor/`, and preparation rows and portion labels to `app/lib/ui/table/trn_table.dart`, until T047 passes
- [ ] T051 [US2] (owner) On the S24, enter the two-component reference recipe and compare with the drawing

**Checkpoint**: US1 and US2 both work; ordinary recipes with frostings, toppings and ovens fit.

---

## Phase 5: User Story 3 - Find a recipe in the library (Priority: P3)

**Goal**: list, search, open.

**Independent Test**: with saved recipes, search by a title word and by an ingredient, in airplane
mode (spec US3).

### Tests for User Story 3 (write first, see them fail)

- [ ] T052 [P] [US3] Write failing tests in `app/test/data/search_test.dart`: matches any part of a title or any ingredient name; case-insensitive; `%`, `_` and `\` in the search term are matched literally; results ordered by `title COLLATE NOCASE`; drafts are included with their status (FR-019, FR-020)
- [ ] T053 [P] [US3] Write a failing performance test in `app/test/data/search_performance_test.dart`: with 500 generated recipes stored, each search returns within 1 second (SC-004)
- [ ] T054 [P] [US3] Write failing widget tests in `app/test/ui/library/library_screen_test.dart`: lists recipes by title; drafts show a "needs review" marker; results narrow as the cook types; no match shows a message rather than a blank list; a complete recipe opens to its table and a draft opens in the editor (US3 scenarios 1 to 3, FR-019)

- [ ] T055 [P] [US3] Write `app/integration_test/search_performance_test.dart`: seeds 500 generated recipes, types a search term one character at a time, and fails if any keystroke takes longer than 1 second to show updated results; (owner) run it on the S24 (SC-004 measured from keystroke to results on the phone, not only the query)

### Implementation for User Story 3

- [ ] T056 [US3] Add the search query from `data-model.md` to `app/lib/data/schema.drift` and expose it in `app/lib/data/recipe_repository.dart`, escaping `%`, `_` and `\`, until T052 and T053 pass
- [ ] T057 [US3] Implement `app/lib/ui/library/library_screen.dart` with search-as-you-type, until T054 passes

**Checkpoint**: the library is usable; US1 to US3 work.

---

## Phase 6: User Story 4 - Change or remove a recipe (Priority: P4)

**Goal**: edit anything, insert and move steps, delete.

**Independent Test**: edit a quantity, a step's text and its inputs; insert "sift flour"; try an
illegal move; delete a recipe and restart (spec US4).

### Tests for User Story 4 (write first, see them fail)

- [ ] T058 [P] [US4] Write failing tests in `packages/trn_core/test/counter_edit_test.dart`: `available(doc, atPosition)` returns unused items plus items used only by later steps; inserting a step that takes an item from a later step makes that later step use the new result instead (the "sift flour" case, FR-027, US4 scenario 5); `moveStep` refuses, naming the step, a move before a step whose result it uses or after a step that uses its result (US4 scenario 6); `removeStep` returns its inputs to the counter and removes its result from the later step; `removeIngredient` removes its portions from the steps that used them
- [ ] T059 [P] [US4] Write failing widget tests in `app/test/ui/editor/editor_edit_test.dart`: editing a saved recipe's quantity and step text updates the table; changing inputs so the recipe breaks shows the specific violation and saves as a draft (US4 scenario 2, FR-017); inserting a step at a position; a blocked move shows its reason; delete asks for confirmation, cancel deletes nothing, confirm removes the recipe (US4 scenarios 3 and 4, FR-022)

### Implementation for User Story 4

- [ ] T060 [US4] Implement positional `available`, `addStep(atPosition)` with rewiring, `moveStep`, `removeStep` and `removeIngredient` in `packages/trn_core/lib/src/counter.dart` until T058 passes
- [ ] T061 [US4] Add edit entry, step insertion, step reordering with refusal messages, and delete with confirmation to `app/lib/ui/editor/` and `app/lib/ui/table/recipe_screen.dart`, until T059 passes

**Checkpoint**: all four stories work independently.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: credit, backup, device verification, documentation, iOS milestone.

- [ ] T062 [P] Write a failing widget test in `app/test/ui/about/about_screen_test.dart`: the About screen is reachable from the library and credits Michael Chu and Cooking for Engineers as the creator of Tabular Recipe Notation (FR-025, Principle VI)
- [ ] T063 Implement `app/lib/ui/about/about_screen.dart` and the library's link to it until T062 passes
- [ ] T064 Configure platform backup: set `android:allowBackup="true"` explicitly and `android:dataExtractionRules="@xml/data_extraction_rules"` in `app/android/app/src/main/AndroidManifest.xml`, with `app/android/app/src/main/res/xml/data_extraction_rules.xml` including the database in both `<cloud-backup>` and `<device-transfer>` (research R4, FR-026). Exception to test-first, to be stated in the pull request: backup is verified on the device by T067, not by an automated test
- [ ] T065 [P] Write `app/integration_test/app_flows_test.dart` covering US1 to US4's main flows on a device; (owner) run it on the S24 with airplane mode on (SC-005)
- [ ] T066 [P] Write `tool/force_close_cycles.ps1`: 20 times, start entry, kill the app with `adb shell am force-stop io.github.dnoeltx.recipes`, restart, and compare saved recipes; then reboot the device once with `adb reboot` and compare again (FR-024); (owner) run it on the S24 (SC-007). `adb` is at `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`
- [ ] T067 (owner) Verify backup on the S24 per quickstart: `adb shell bmgr backupnow io.github.dnoeltx.recipes`, uninstall, reinstall, restore, and confirm every recipe is present and unchanged (SC-008)
- [ ] T068 (owner) Timed trial: enter a real 10-ingredient, 6-step recipe cold on the S24 in under 10 minutes (SC-001)
- [ ] T069 (owner) Read the 15 by 10 reference table on the S24 held upright at the default and the largest standard text size; nothing cut off without a way to read it, no zooming (SC-006)
- [ ] T070 (owner) Compare every committed golden with its hand-drawn reference once; from then on the goldens hold the line (SC-002)
- [ ] T071 [P] Update `README.md`: status, how to build and test (from quickstart), and the design decisions worth knowing: the pure Dart core and its purity check, the depth-based layout found by parsing Chu's own tables, the validator fixture suite, the database enforcing "at most once", and backup
- [ ] T072 (owner) Trigger `.github/workflows/ios-build.yml` and confirm the unsigned iOS build succeeds; every numbered spec ends with this (constitution Principle VIII as amended to v1.2.0)
- [ ] T073 Record in the pull request that the on-device iPhone check is not due in 001: under constitution Principle VIII (v1.2.0) an iOS milestone is reached before any build is given to anyone other than the owner. List the iOS items it will cover (text size, backup location under Application Support, SC-006) in `specs/001-manual-recipe-library/quickstart.md`
- [ ] T074 Run every step of `specs/001-manual-recipe-library/quickstart.md` and record the results in the pull request description, including the T024 non-vacuous check and any test-first exceptions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first (no Flutter, no build); T002 needs only the S24 and adb; T003 to T005 in order; the rest of the
  phase in parallel; T014 after the first green CI run.
- **Foundational (Phase 2)**: depends on Setup. Blocks every user story.
  - T015 to T018 (quantity, document) before the fixtures T020 to T022.
  - T019 (owner) before T020.
  - T023 after T022; T024 after T023.
  - T025 to T029 (storage) after T018; T028 also needs T020 and T021.
  - T030 and T031 after T026.
- **User stories (Phases 3 to 6)**: depend on Foundational. Recommended order is by priority.
- **Polish (Phase 7)**: after the stories it verifies; T062, T063, T064 and T071 can start any time
  after Foundational.

### User Story Dependencies

- **US1 (P1)**: needs only Foundational.
- **US2 (P2)**: extends files US1 creates (`counter.dart`, `layout.dart`, the editor, the
  renderer), so it follows US1 in practice; its behavior is tested on its own.
- **US3 (P3)**: needs only Foundational; it is testable with fixture recipes saved directly
  through the repository, without the editor.
- **US4 (P4)**: extends US1's counter and editor; follows US1.

### Within Each User Story

- Tests are written, run, and seen to fail before the implementation that makes them pass.
- `trn_core` behavior before the screens that call it.
- The story's checkpoint before moving on.

### Parallel Opportunities

- Setup: T006, T007, T008, T009, T013 together.
- Foundational: T015 and T017 together; T021 alongside T020; T025 and T028 test-writing alongside
  core work once T018 is done.
- Within each story: all of its test tasks marked [P] together.
- US3 can proceed alongside US2 once Foundational is complete.

---

## Parallel Example: User Story 1

```text
# Write all US1 tests together, then watch them fail:
Task: "T032 counter tests in packages/trn_core/test/counter_test.dart"
Task: "T033 layout tests in packages/trn_core/test/layout_test.dart"
Task: "T034 table widget tests in app/test/ui/table/trn_table_test.dart"
Task: "T035 golden tests in app/test/ui/table/trn_table_golden_test.dart"
Task: "T036 editor widget tests in app/test/ui/editor/editor_screen_test.dart"
Task: "T037 recipe screen widget tests in app/test/ui/table/recipe_screen_test.dart"

# Then core implementations in parallel (different files):
Task: "T038 counter in packages/trn_core/lib/src/counter.dart"
Task: "T039 layout in packages/trn_core/lib/src/layout.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup, with CI green and required.
2. Phase 2: Foundational (blocks everything).
3. Phase 3: User Story 1.
4. **Stop and check** on the S24 (T043).

### Incremental Delivery

1. Setup + Foundational: rules proven, storage proven.
2. US1: the MVP.
3. US2: real recipes fit.
4. US3: a library worth having.
5. US4: editing and the landing place for later imports.
6. Polish: backup, device checks, README, iOS milestone.

Each phase ends at a checkpoint and can be its own pull request, so `main` never holds a half-built
story.

---

## Notes

- [P] tasks touch different files and do not depend on incomplete tasks.
- (owner) tasks are never executed by AI assistance.
- Commit after each task or logical group; the owner runs every git command.
- Versions in this file come from research.md; re-verify any that are older than a few weeks when
  the task is reached (Principle XI).
