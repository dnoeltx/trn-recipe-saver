# Feature Specification: Manual Recipe Library with TRN Table View

**Feature Branch**: `feature/001-manual-recipe-library`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "Spec 001: Manual recipe library with TRN table view (no AI, no backend, no network). The household cook can type in their own recipes, see each one as a Tabular Recipe Notation (TRN) table, and keep them in a personal on-device library."

## Background

Tabular Recipe Notation (TRN), created by Michael Chu at Cooking for Engineers in 2004, lays a
recipe out as a table: ingredients run down the left column, steps run left to right in order of
how much has been combined, and each step's cell spans every ingredient or earlier result it
combines. A recipe in TRN is therefore a
tree: ingredients are the leaves, each step joins some of what is on the counter into one new
thing, and the finished dish is the root.

An ordinary recipe lists ingredients and steps but does not say which things each step combines.
That missing link is what this feature asks the cook to supply, in a way that matches how a cook
already thinks: "what am I combining now?"

This is the first feature and the foundation for later ones. Later imports (from a web page or a
photo) will produce the same structure, be checked by the same structural rules, and open in the
same editor defined here.

## Clarifications

### Session 2026-10-08

- Q: If the phone is lost or replaced, should the recipe library come back through the phone's own
  backup (Google backup on Android, iCloud on iPhone)? → A: Yes. The library is included in the
  platform's own user-controlled backup; constitution Principle VII is to be amended to permit
  this explicitly before planning (FR-026).
- Q: When editing a saved recipe, can the cook insert a new step between existing steps, or move a
  step to a different position? → A: Both. Steps can be inserted anywhere and moved, but a move
  that would place a step before a step whose result it uses is blocked (FR-027).
- Q: How should ingredients that are separated into different things (eggs into yolks and whites)
  be handled, as opposed to divided by amount? → A: Entered as separate ingredients ("2 egg
  yolks", "2 egg whites"). Splitting remains quantity-only, with its add-up check (FR-008).
- Q: How should a step's cooking time be recorded? → A: Structured: a duration, an optional
  maximum duration for a range (25 to 30 minutes), and an optional free-text note ("until golden")
  (FR-003).
- Q: Should the table follow the phone's text-size setting? → A: Yes, everywhere including the
  table; SC-006 is also checked at the largest standard text size (FR-028).

### Session 2026-10-08 (plan research)

- Q: Should table columns follow step order, as first specified, or combining depth, as Michael
  Chu's own tables do (found by parsing his published tables; see research.md R5)? → A: Combining
  depth, as in the original format. Independent steps share a column, each step sits one column
  right of its deepest input, and preparation steps are full-width rows at the top (FR-012,
  FR-016, US1 scenario 4, US2 scenario 3 amended).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enter a recipe and see it as a TRN table (Priority: P1)

The cook creates a new recipe, gives it a title and servings, and enters its ingredients. Each
ingredient goes onto "the counter", a visible list of what is available to cook with. The cook then
adds steps one at a time. For each step they write what to do ("whisk together") and choose what
goes into it from what is currently on the counter. The chosen items leave the counter and the
step's result takes their place. When only one thing remains on the counter, the recipe is
complete, the cook saves it, and sees it rendered as a TRN table.

**Why this priority**: This is the product. Without structured entry and the table there is
nothing to store, search, or import into.

**Independent Test**: Enter a simple recipe (for example: pancakes, with dry ingredients whisked,
wet ingredients whisked, the two combined, then cooked) and confirm the saved table matches a
hand-drawn TRN reference for the same recipe.

**Acceptance Scenarios**:

1. **Given** a new recipe with five ingredients entered, **When** the cook adds a step, **Then**
   the step offers exactly those five ingredients as possible inputs.
2. **Given** a step that combined flour, sugar, and salt, **When** the cook adds the next step,
   **Then** flour, sugar, and salt are no longer offered and that step's result is offered instead.
3. **Given** more than one item still on the counter, **When** the cook looks at the recipe,
   **Then** the app shows that the recipe is not yet complete and which items are still unused.
4. **Given** a completed recipe, **When** it is saved and opened, **Then** the table shows each
   ingredient as a row on the left, each step one column to the right of the deepest thing it
   combines, steps that do not depend on each other sharing a column, and each step's cell
   spanning exactly the rows of what it combined.
5. **Given** ingredients entered in an order that would scatter a step's inputs across the table,
   **When** the table is shown, **Then** the rows are arranged so that every step's inputs sit in
   adjacent rows, without the cook rearranging anything.
6. **Given** a step with a time ("10 min") or temperature ("350 °F"), **When** the table is shown,
   **Then** the time and temperature appear in that step's cell.
7. **Given** a recipe only partly entered, **When** the cook saves it, **Then** it appears in the
   library marked "needs review", and opening it returns to the editor showing what remains,
   not to a table.

---

### User Story 2 - Recipes that are not a simple chain (Priority: P2)

Real recipes divide ingredients and include preparation that combines nothing. The cook can split
an ingredient on the counter into portions (half the butter for the dough, half for the topping),
each of which is used by a different step. The cook can also add a preparation step, such as
"preheat oven to 350 °F" or "grease a 9 inch pan", that uses nothing from the counter.

**Why this priority**: Without these, a large share of ordinary recipes (anything with a frosting,
a topping, a sauce, or an oven) cannot be entered faithfully, so the library would only hold easy
cases.

**Independent Test**: Enter a two-component recipe (for example: cake and frosting, with butter
divided between them, plus "preheat oven") and confirm the table matches a hand-drawn reference.

**Acceptance Scenarios**:

1. **Given** 1 cup of butter on the counter, **When** the cook splits it into 1/2 cup and 1/2 cup,
   **Then** the counter shows two butter portions in place of the original, and each can be chosen
   by a different step.
2. **Given** a split ingredient, **When** the table is shown, **Then** each portion appears as its
   own row next to the step that uses it.
3. **Given** a preparation step with no inputs, **When** the table is shown, **Then** that step
   appears as a row across the full width of the table, above the ingredients, in step order.
4. **Given** a preparation step, **When** the cook continues adding steps, **Then** the counter is
   unchanged by it: it consumes nothing and adds nothing.

---

### User Story 3 - Find a recipe in the library (Priority: P3)

The cook opens the app and sees their saved recipes. They type part of a title or an ingredient
("buttermilk") and the list narrows to matching recipes. Opening one shows its TRN table.

**Why this priority**: A library becomes useful once it holds more than a handful of recipes. It
depends on User Story 1 for content.

**Independent Test**: With a set of saved recipes, search by a title word and by an ingredient name
and confirm the right recipes appear; switch the device to airplane mode and repeat.

**Acceptance Scenarios**:

1. **Given** saved recipes, **When** the cook opens the app, **Then** the library lists them by
   title.
2. **Given** a search term matching part of a title, **When** it is typed, **Then** only recipes
   whose title or ingredients contain it are listed, regardless of letter case.
3. **Given** no recipe matches, **When** the cook searches, **Then** the app says nothing matched
   rather than showing an empty screen without explanation.
4. **Given** the device has no network connection, **When** the cook uses the library, **Then**
   everything in this story works the same way.

---

### User Story 4 - Change or remove a recipe (Priority: P4)

The cook fixes a typo, changes a quantity, rewrites a step, changes what a step combines, or
deletes a recipe they no longer want.

**Why this priority**: Entry mistakes are certain, and the same editor is where later imports will
land for review. It depends on User Story 1.

**Independent Test**: Edit a saved recipe's quantity, a step's text, and a step's inputs; confirm
the table updates correctly. Delete a recipe and confirm it is gone after restarting the app.

**Acceptance Scenarios**:

1. **Given** a saved recipe, **When** the cook changes an ingredient's quantity or a step's text,
   **Then** the table reflects the change after saving.
2. **Given** a saved recipe, **When** the cook changes a step's inputs or removes an ingredient so
   that the recipe no longer forms a single complete tree, **Then** the app shows exactly what is
   now wrong (for example, "butter is not used by any step") and how the recipe will be stored
   follows FR-018.
3. **Given** a saved recipe, **When** the cook deletes it and confirms, **Then** it no longer
   appears in the library, including after the app is restarted.
4. **Given** the cook starts deleting a recipe, **When** they cancel the confirmation, **Then**
   nothing is deleted.
5. **Given** a saved recipe where step 2 whisks flour and sugar, **When** the cook inserts "sift
   flour" before step 2, **Then** the new step is offered the flour, step 2 now uses the sifted
   flour instead, and the table shows the new column in its place.
6. **Given** step 3 uses the result of step 2, **When** the cook tries to move step 3 before step 2,
   **Then** the move is blocked and the app says why.

---

### Edge Cases

- A recipe with a single ingredient and a single step (for example, "toast bread") is complete and
  renders as a one-row table.
- A step that uses only one item (for example, "chill dough 1 hour") is valid and extends that
  item's row by one cell.
- A step whose inputs include both raw ingredients and earlier results renders with its cell
  spanning the rows of all of them, which are arranged to be adjacent (FR-012).
- Splitting an ingredient whose quantity is not a number ("salt, to taste") is allowed; the
  portions keep the unit-less description and the cook labels them.
- Deleting a step that later steps depend on: its inputs return to the counter and the later step
  loses that input, which the app reports per FR-017.
- A recipe whose only steps are preparation steps, with ingredients never combined, is incomplete:
  the ingredients are still on the counter.
- Very long step text does not get silently cut off: the full text is always reachable from the
  table.
- A recipe large enough that the table is wider or taller than the screen can still be read in
  full (FR-014).
- Leaving the editor with unsaved changes asks before discarding them.
- The app is closed or killed mid-entry: previously saved recipes are unaffected.

## Requirements *(mandatory)*

### Functional Requirements

**Recipe data**

- **FR-001**: The app MUST store each recipe with a title, a servings value, an optional free-text
  source reference (for example, a book title, "Grandma's card", or a web address), how it was
  created (manual for this feature), and its creation date.
- **FR-002**: The app MUST store each ingredient with an optional quantity, an optional unit, a
  name, and an optional preparation note (for example, "sifted", "room temperature"). Quantities
  MUST accept whole numbers, decimals, and fractions (for example, 1/3 and 1 1/2) and MUST
  preserve fractions as entered.
- **FR-003**: The app MUST store each step with its action text, an optional time, an optional
  temperature with its unit as entered, and the items it combines. A time is a duration (to the
  second, for steps like "whisk 30 seconds"), an optional longer duration when the recipe gives a
  range ("25 to 30 minutes"), and an optional free-text note ("until golden brown"). The longer
  duration, when present, MUST be greater than the first. A step may have a note with no duration.
- **FR-004**: An item a step combines MUST be either an ingredient portion or the result of an
  earlier step. A step MAY optionally give its result a short label (for example, "dry mix"); when
  it does not, the result is identified by the step's action text.
- **FR-005**: The recipe MUST be stored as this structure. The table MUST always be produced from
  the structure, never stored as an image or as a separate copy (constitution Principle IV).

**Entry (the counter)**

- **FR-006**: While entering or editing a recipe, the app MUST show "the counter": every ingredient
  portion and step result not yet used by any step.
- **FR-007**: When the cook adds or edits a step, the app MUST offer as inputs only the items on the
  counter (plus, when editing, the items that step already uses). Items already used by another
  step MUST NOT be offered.
- **FR-008**: The cook MUST be able to split any ingredient on the counter into two or more
  portions. When the quantity is numeric, the portions' quantities MUST add up to the original;
  the app MUST reject a split that does not.
- **FR-009**: The cook MUST be able to add a preparation step that uses no inputs and adds nothing
  to the counter.
- **FR-010**: The app MUST show at all times during entry whether the recipe is complete (exactly
  one item on the counter and every step valid) and, if not, what remains to be done.
- **FR-027**: The cook MUST be able to insert a new step at any position in the step order and to
  move an existing step to another position. A step inserted at a position MUST be offered the
  items available at that point in the order: those not used by any step, plus those used only by
  a later step. When the inserted step takes an item from a later step, that later step MUST use the
  inserted step's result in its place, so the recipe stays complete. The app MUST block, with an explanation, any
  move that would place a step before a step whose result it uses, or after a step that uses its
  result.

**Structural rules**

- **FR-011**: The app MUST check every recipe against one shared set of structural rules,
  regardless of how the recipe was created, and MUST report each violation in plain language that
  names the ingredient or step involved. The rules are:
  1. every ingredient portion is used by exactly one step;
  2. every step that has inputs has its result used by exactly one later step, except the final
     step, whose result is the finished dish;
  3. every input a step uses exists in the recipe and comes from an earlier step or an ingredient;
  4. preparation steps have no inputs and their results are not used by any step;
  5. exactly one final result exists;
  6. the portions of a split ingredient add up to the original when the quantity is numeric.

**Table view**

- **FR-012**: The app MUST render each recipe as a TRN table: ingredient portions as rows down the
  left and steps placed by combining depth: a step sits in the column immediately right of the
  deepest item it combines, steps that do not depend on each other share a column, and an input
  that is shallower than its step is padded with an empty cell so the step still sits beside it.
  Each step's cell spans exactly the rows of the items it combines (directly, or through the
  earlier results it combines). The table is therefore as wide as the recipe is deep, not as wide
  as it has steps. The recipe's step order is kept for editing and for tie-breaking row order
  (FR-013), but does not assign columns.
- **FR-013**: The app MUST arrange ingredient rows so that every step's inputs occupy adjacent rows,
  without the cook arranging them. Where several arrangements satisfy this, ingredients MUST keep
  the order in which they were entered as far as possible.
- **FR-014**: The table MUST be readable on a phone held upright: ingredient names stay visible
  while the cook moves across the steps, and every part of a table larger than the screen is
  reachable by scrolling.
- **FR-015**: Each step cell MUST show the step's action text and, when present, its time
  (including a range and note) and temperature. Text that does not fit MUST remain readable in full without leaving the table view.
- **FR-028**: All text in the app, including the table, MUST follow the phone's system text-size
  setting. At larger sizes the table grows and remains fully reachable by scrolling, with
  ingredient names still visible while moving across the steps (FR-014).
- **FR-016**: Preparation steps MUST render as rows spanning the full width of the table, above the
  ingredient rows, in step order.

**Incomplete and invalid recipes**

- **FR-017**: When an edit breaks a structural rule, the app MUST tell the cook which rule and which
  items, and MUST NOT present the recipe as a valid TRN table while the violation stands.
- **FR-018**: A recipe that does not satisfy every structural rule MAY be saved as a draft. A
  draft MUST be shown in the library marked "needs review", MUST open in the editor with its
  violations listed (FR-011), and MUST NOT be rendered as a TRN table until it satisfies every
  rule, at which point it becomes a complete recipe. This is the same state a later import that
  fails validation will be saved in (constitution Principle I).

**Library**

- **FR-019**: The app MUST list saved recipes by title, drafts included and marked as such, and
  open a complete recipe to its table view and a draft to the editor.
- **FR-020**: The app MUST search recipes by any part of the title or of any ingredient name, case
  insensitive, updating the results as the cook types.
- **FR-021**: The cook MUST be able to edit any saved recipe using the same entry flow as creation.
- **FR-022**: The cook MUST be able to delete a recipe, after confirming. Deletion removes the
  recipe and everything belonging to it.
- **FR-023**: Every capability in this feature MUST work with no network connection (constitution
  Principle V), and the app MUST NOT send any recipe data off the device (Principle VII),
  other than through the platform backup in FR-026.
- **FR-024**: Saved recipes MUST survive closing the app, killing it, and restarting the device.

**Credit**

- **FR-025**: The app MUST credit Michael Chu and Cooking for Engineers as the creator of Tabular
  Recipe Notation in a place the cook can find from the main screen, for example an About screen.

**Backup**

- **FR-026**: The recipe library MUST be included in the platform's own user-controlled device
  backup, so that restoring a backup to a new phone of the same platform restores the library.
  No other copy of the library leaves the device. This depends on the Principle VII amendment
  noted under Clarifications.

### Key Entities *(include if feature involves data)*

- **Recipe**: one dish the cook keeps. Title, servings, optional source reference, how it was
  created, creation date, and whether it is complete or a draft needing review. Owns its
  ingredients and steps.
- **Ingredient**: something the recipe calls for, as written: optional quantity, optional unit,
  name, optional preparation note.
- **Ingredient portion**: the unit a step actually uses. An unsplit ingredient has one portion equal
  to the whole; a split ingredient has two or more portions whose quantities add up to the whole.
  Each portion is a row in the table.
- **Step**: one thing the cook does. Action text, optional time (duration, optional upper bound of
  a range, optional note), optional temperature,
  optional result label, position in the step order. Either combines one or more inputs into a
  result, or is a preparation step with no inputs.
- **Step input**: a link from a step to one thing it combines: either an ingredient portion or the
  result of an earlier step, never both. These links are what make the table's cells span rows.
- **The counter**: not stored. The set of portions and results not yet used by any step, derived
  from the structure at any moment during entry.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The owner can enter a typical recipe of about 10 ingredients and 6 steps, from an
  empty recipe to a saved table, in under 10 minutes on a first attempt with no instructions.
- **SC-002**: A reference set of at least five hand-entered recipes, including a split ingredient,
  a preparation step, a two-component dish, a single-input step, and a recipe of at least 15
  ingredients, each renders identically to a TRN table drawn by hand for the same recipe.
- **SC-003**: Every recipe stored as complete passes all structural rules (FR-011); checking the
  whole library reports zero violations.
- **SC-004**: With 500 recipes stored, search results update within 1 second of each keystroke.
- **SC-005**: Every user story passes its acceptance scenarios with the device in airplane mode.
- **SC-006**: A table of 15 ingredients and 10 steps can be read in full on the owner's phone held
  upright, with no text cut off without a way to read it, and without zooming, both at the
  phone's default text size and at its largest standard text size setting.
- **SC-007**: No saved recipe is lost or altered across 20 cycles of force-closing the app during
  entry and restarting it.
- **SC-008**: After the app is uninstalled and the platform backup restored, every recipe that had
  been backed up is present and unchanged.

## Assumptions

- The first user is the owner, cooking at home, entering recipes they already know or have on paper.
  The app has one user per device and no sign-in.
- Steps keep the order the cook gives them (FR-027); the table never reorders steps on its own. A
  step can only use results of steps that come before it.
- A recipe ends in exactly one finished dish. A dish served "with" something (steak with sauce) ends
  in a final step that brings them together, such as "plate and serve".
- Discarded items (a marinade poured off, pasta water drained) are described in step text and
  consumed by the step that discards them; no separate "discard" concept is needed.
- An ingredient separated into different things (eggs into yolks and whites) is entered as
  separate ingredients, as printed recipes already do. Splitting (FR-008) only divides an
  ingredient by amount; there is no "separate into parts" action and no step produces two results.
- Only ingredients can be split in this feature. Dividing an intermediate result (for example,
  dividing batter between two pans that are then treated the same) is described in step text.
  Splitting intermediate results is a candidate for a later spec.
- Units are free text as entered ("cup", "g", "tbsp"); no unit conversion and no servings scaling in
  this feature (scaling is spec 002). Quantities are nonetheless stored as numbers where possible so
  that scaling can use them later.
- Temperatures are stored with the unit the cook entered (°F or °C); no conversion in this feature.
- Search covers titles and ingredient names only. Step text, notes, and tags are not searched in
  this feature.
- Notes, ratings, tags, cook log, and scaling (spec 002), import from a web page (specs 003 and
  004), photo import (spec 005), accounts, and sync are out of scope.
- Deletion is permanent after confirmation; there is no undo or trash in this feature.
- The entry and editing flow defined here is the same one later imports will open into for review
  (constitution Principle I).
