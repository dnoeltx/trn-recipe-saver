# Data Model: Manual Recipe Library with TRN Table View

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-08

Two layers, deliberately kept apart:

- **Storage** (SQLite through drift, schema written as SQL): enforces what a database enforces
  cheaply and absolutely: types, nullability, ownership, the exclusive arc, and "used at most
  once".
- **Structural rules** (pure Dart, `packages/trn_core`): everything that needs the whole recipe to
  judge, such as "used at least once", "comes from an earlier step", and "exactly one final
  result". These are FR-011's rules and are documented in [contracts/validation.md](contracts/validation.md).

A recipe is edited as one in-memory document and **saved as a whole in a single transaction**
(its children are replaced). That makes reordering steps and portions simple under the position
uniqueness constraints, and it means a recipe on disk is always a state the cook chose to save,
never half of an edit.

## Tables

### recipe

| Column | Type | Null | Rule |
|---|---|---|---|
| id | INTEGER | no | primary key |
| title | TEXT | no | `trim(title) <> ''` |
| servings | INTEGER | yes | `> 0` when present |
| servings_note | TEXT | yes | free text such as "one 9 inch cake" |
| source_ref | TEXT | yes | free text: book, card, web address (FR-001, Principle VI) |
| origin | TEXT | no | `IN ('manual','url','photo')`; only `manual` is written in 001 |
| status | TEXT | no | `IN ('complete','draft')`; set by the validator on every save (FR-018) |
| created_at | INTEGER | no | UTC milliseconds |
| updated_at | INTEGER | no | UTC milliseconds |

`origin` admits `url` and `photo` now so specs 003 to 005 add rows, not a migration.

### ingredient

| Column | Type | Null | Rule |
|---|---|---|---|
| id | INTEGER | no | primary key |
| recipe_id | INTEGER | no | FK recipe, `ON DELETE CASCADE` |
| position | INTEGER | no | entry order; `UNIQUE (recipe_id, position)` |
| qty_num | INTEGER | yes | numerator of an exact quantity (R9) |
| qty_den | INTEGER | yes | denominator, `> 0` |
| qty_form | TEXT | yes | `IN ('whole','fraction','mixed','decimal')`: how to display it |
| qty_text | TEXT | yes | a non-numeric amount ("a few sprigs") |
| unit | TEXT | yes | free text as entered (no conversion in 001) |
| name | TEXT | no | `trim(name) <> ''` |
| prep_note | TEXT | yes | "sifted", "to taste", "room temperature" |

Checks: `qty_num`, `qty_den` and `qty_form` are all null or all present; `qty_text` is null
whenever `qty_num` is present.

### portion

The unit a step actually uses, and one row of the table. Every ingredient has at least one.

| Column | Type | Null | Rule |
|---|---|---|---|
| id | INTEGER | no | primary key |
| ingredient_id | INTEGER | no | FK ingredient, `ON DELETE CASCADE` |
| position | INTEGER | no | `UNIQUE (ingredient_id, position)` |
| qty_num, qty_den, qty_form | as ingredient | yes | null on an unsplit ingredient's single portion, meaning "all of it" |
| label | TEXT | yes | "for the topping"; shown in the row |

### step

| Column | Type | Null | Rule |
|---|---|---|---|
| id | INTEGER | no | primary key |
| recipe_id | INTEGER | no | FK recipe, `ON DELETE CASCADE` |
| position | INTEGER | no | the recipe's step order (FR-027); `UNIQUE (recipe_id, position)` |
| kind | TEXT | no | `IN ('combine','preparation')` |
| action | TEXT | no | `trim(action) <> ''` |
| result_label | TEXT | yes | "dry mix" (FR-004) |
| dur_s | INTEGER | yes | duration in seconds, `> 0` |
| dur_max_s | INTEGER | yes | upper end of a range; requires `dur_s`; `dur_max_s > dur_s` |
| time_note | TEXT | yes | "until golden brown" |
| temp_value | REAL | yes | |
| temp_unit | TEXT | yes | `IN ('F','C')`; null exactly when `temp_value` is null |

`kind` is stored, not inferred from "has no inputs", because a combine step in a draft may have no
inputs yet; only a preparation step is meant to have none.

### step_input

| Column | Type | Null | Rule |
|---|---|---|---|
| id | INTEGER | no | primary key |
| step_id | INTEGER | no | FK step, `ON DELETE CASCADE` |
| portion_id | INTEGER | yes | FK portion, `ON DELETE CASCADE`; **`UNIQUE`** |
| input_step_id | INTEGER | yes | FK step, `ON DELETE CASCADE`; **`UNIQUE`** |
| position | INTEGER | no | order within the step's inputs |

- **Exclusive arc**: `CHECK ((portion_id IS NULL) <> (input_step_id IS NULL))`.
- **At most once**: the two `UNIQUE` constraints mean no portion and no step result can be used by
  two steps. The database makes double use impossible; the validator only has to find *unused*
  items.
- **Cascades match the spec's edge cases**: deleting a step deletes its own input rows (so its
  inputs go back on the counter) and the input row in the later step that used its result (so that
  step reports a missing input, FR-017).
- `PRAGMA foreign_keys = ON` is set on every connection; SQLite leaves it off by default.

## Rules the database cannot see

Owned by the validator ([contracts/validation.md](contracts/validation.md)), applied on every save
to set `recipe.status`:

- every portion and every combine step's result is used (the "at least once" half)
- an input comes from the same recipe and from an earlier step in step order
- a preparation step has no inputs and its result is never used
- exactly one final result
- split portions add up to the ingredient when its quantity is numeric (exact rational arithmetic)

## State: draft and complete

```
          save, any rule violated
  (new) ──────────────────────────> draft ◀──┐
    │                                 │      │ save, a rule now violated
    │ save, all rules hold            │      │
    └──────────────────> complete <───┘      │
                            │  save, all rules hold
                            └────────────────┘
```

Status is never set by the user directly. It is a function of the structure, recomputed on every
save, so a recipe cannot be marked complete while invalid (SC-003).

## Derived, never stored

- **The counter**: portions and combine results not used by any step, computed from the in-memory
  document. For an inserted step it is computed at that point in the step order (FR-027).
- **The table**: computed by the layout ([contracts/layout.md](contracts/layout.md)) whenever a
  complete recipe is shown (FR-005, Principle IV).

## Search (FR-020)

```sql
SELECT DISTINCT r.id, r.title, r.status
FROM recipe r
LEFT JOIN ingredient i ON i.recipe_id = r.id
WHERE r.title LIKE :pattern ESCAPE '\' OR i.name LIKE :pattern ESCAPE '\'
ORDER BY r.title COLLATE NOCASE;
```

`:pattern` is `%term%` with `%`, `_` and `\` escaped. SQLite's `LIKE` is case-insensitive for
ASCII letters. A leading wildcard cannot use an index; at 500 recipes (SC-004) a scan is a few
thousand rows, so no full-text index is added until a measurement says otherwise (Principle XI).

## Migrations

Schema version 1. drift's schema export is committed from version 1, so every later migration is
tested against the real previous schema rather than written blind.
