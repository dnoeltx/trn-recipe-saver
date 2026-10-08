# Contract: TRN Table Layout

**Implements**: FR-012, FR-013, FR-014, FR-016 (as amended after
[../research.md](../research.md) R5), FR-028.

The layout is a pure function from a **complete** recipe document to a grid. It knows nothing about
pixels or fonts; the renderer turns the grid into widgets and measures text. Drafts are never laid
out (FR-018).

## Definitions

- **Height** of a portion is 0. Height of a combine step is 1 + the greatest height among its
  inputs. The final step has the greatest height, **H**.
- The grid has **H + 1 columns**: column 0 holds portions, column *h* holds the steps of height *h*.

## Rows (FR-013)

1. Start at the final step.
2. Order each step's inputs by the smallest ingredient entry position found anywhere beneath that
   input (ties broken by portion position, then by step position).
3. Read portions depth-first in that order. That sequence is the row order.

Every step's inputs then occupy a contiguous run of rows, because a depth-first reading of any tree
keeps each subtree together.

## Cells

- **Portion cell**: row *r*, column 0, one row tall. Shows quantity, unit, name, preparation note,
  and the portion's label when split.
- **Step cell**: column = the step's height; rows = all portion rows beneath it; one column wide.
  Shows the action and, when present, time (with range and note) and temperature (FR-015).
- **Filler cell**: where an input's height is less than its step's height minus one, the gap
  between them in those rows is one empty cell spanning the missing columns, so the step still
  sits immediately right of what it combines. (Chu's tiramisu pads lady's fingers by one column
  before "dip".)
- **Preparation steps**: each is a row **above** the portion rows, spanning all H + 1 columns, in
  step order (Chu's "Preheat oven to 350 F" row).

## Output shape

```
TableGrid
  columns: int                          // H + 1
  preparationRows: [StepRef]            // top full-width rows, in step order
  rows: [PortionRef]                    // in row order
  cells: [Cell]                         // portion, step, and filler cells
Cell
  kind: portion | step | filler
  ref: PortionRef | StepRef | none
  row: int, rowSpan: int                // relative to the portion rows
  column: int, columnSpan: int
```

## Invariants (tested on every reference recipe and on generated trees)

1. Every (row, column) position below the preparation rows is covered by exactly one cell.
2. Every step cell's rows are exactly the portions beneath it, and are contiguous.
3. Every step cell is in a column greater than every cell it combines.
4. Laying out the same document twice gives the same grid (deterministic).
5. Width is H + 1, never the number of steps.
