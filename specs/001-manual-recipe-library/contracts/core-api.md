# Contract: trn_core Operations

**Package**: `packages/trn_core` (pure Dart, no Flutter import; see [../research.md](../research.md) R8).

The operations the app's screens call. All are pure: each takes a recipe document and returns a
new one (or a result), so every behavior below is testable without a device. Names are
indicative; the tests written from this contract fix the final signatures.

## Counter and entry (FR-006 to FR-010, FR-027)

| Operation | Behavior | Refuses when |
|---|---|---|
| `addIngredient(doc, ingredient)` | appends; creates its single whole portion; it appears on the counter | name empty |
| `splitPortion(doc, portion, quantities)` | replaces one portion with two or more | numeric amounts do not sum exactly; fewer than two parts; the portion is not on the counter |
| `available(doc, atPosition)` | the counter at a point in step order: items unused, plus items used only by steps at or after that point | |
| `addStep(doc, step, inputs, atPosition?)` | inserts at the end or at a position; inputs must come from `available` there; an input taken from a later step is replaced in that step by the new step's result | an input is not available there |
| `setInputs(doc, step, inputs)` | changes what a step combines | an input is not available to that step |
| `moveStep(doc, step, toPosition)` | reorders | the step would come before a step whose result it uses, or after a step that uses its result (returns which) |
| `removeStep(doc, step)` | its inputs return to the counter; a later step using its result loses that input | |
| `removeIngredient(doc, ingredient)` | its portions leave the recipe; steps using them lose those inputs | |
| `isComplete(doc)` | `validate(doc)` is empty | |

Refusals are returned as values naming the reason, not thrown, so the screen can explain them
(FR-027's "blocked, with an explanation").

## Validation (FR-011)

`validate(doc) -> List<Violation>`, specified in [validation.md](validation.md).

## Layout (FR-012, FR-013, FR-016)

`layout(doc) -> TableGrid`, specified in [layout.md](layout.md). Requires `isComplete(doc)`.

## Quantities (FR-002, FR-008)

`Quantity.parse(text)` accepts `2`, `0.5`, `1/3`, `1 1/2`; keeps the form typed; arithmetic is exact
(rational). `Quantity.format()` returns it in the form it was entered.

## Conversion to and from storage

These live in the app's storage layer, not in `trn_core`, which knows nothing about storage.
`toDocument(rows)` and `toRows(doc)` map between the database tables
([../data-model.md](../data-model.md)) and the document
([recipe-document.schema.json](recipe-document.schema.json)). Round-tripping a document through
storage MUST return an equal document; that is tested for every fixture.
