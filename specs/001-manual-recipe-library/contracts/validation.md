# Contract: Structural Validation

**Implements**: FR-011, FR-017, FR-018, SC-003; constitution Principles I and IV.

The validator takes a recipe document ([recipe-document.schema.json](recipe-document.schema.json))
and returns a list of violations. An empty list means the recipe is complete. It never calls a
model, never touches storage, and never changes the recipe: it only reports.

Every implementation of these rules, now or later (spec 004's backend), MUST pass the shared
fixture suite described at the end of this file.

## Violation shape

| Field | Meaning |
|---|---|
| `code` | stable identifier from the table below; tests assert on it |
| `subjects` | the portions or steps involved, by their document ids |
| `message` | plain language naming those items, for the cook (FR-011) |

Messages are produced from the code and subjects, so wording can improve without breaking tests.

## Rules

| # | Code | Violated when | Example message |
|---|---|---|---|
| 1 | `portion_unused` | a portion is used by no step | "Butter (for the topping) isn't used by any step yet." |
| 1 | `portion_reused` | a portion is used by more than one step | "Flour is used by both step 2 and step 4." |
| 2 | `result_unused` | a combine step's result is used by no later step and it is not the final result | "Nothing uses the result of step 3, 'whisk'." |
| 2 | `result_reused` | a step's result is used by more than one step | "The result of step 2 is used by step 4 and step 5." |
| 3 | `input_missing` | an input refers to a portion or step that does not exist in this recipe | "Step 4 uses something that is no longer in the recipe." |
| 3 | `input_not_earlier` | a step uses the result of itself or of a later step | "Step 3 can't use the result of step 5, which comes after it." |
| 3 | `combine_without_inputs` | a combine step has no inputs | "Step 6, 'bake', doesn't use anything yet." |
| 4 | `preparation_has_inputs` | a preparation step has inputs | "'Preheat oven' is a preparation step and can't use ingredients." |
| 4 | `preparation_result_used` | a preparation step's result is used | "Step 5 uses 'preheat oven', which is a preparation step." |
| 5 | `no_final_result` | the recipe has no combine step | "Add a step that combines your ingredients." |
| 5 | `multiple_final_results` | more than one item remains on the counter | "Three things are still on the counter: ..., ..., ...." |
| 6 | `split_does_not_add_up` | a split numeric ingredient's portions do not sum exactly to it | "Butter's portions add up to 3/4 cup, not 1 cup." |
| 6 | `split_portion_not_numeric` | the ingredient is numeric but a portion has no quantity, or vice versa | "Give each portion of the sugar an amount." |

Notes:

- `portion_reused` and `result_reused` cannot occur in stored data because of the database's
  `UNIQUE` constraints ([../data-model.md](../data-model.md)). The validator still checks them,
  because later imports arrive as documents that have never been near the database (Principle I).
- When there are no combine steps, `no_final_result` is reported instead of one `portion_unused`
  per ingredient, so a brand new draft gets one helpful message rather than a list.

## Fixture suite

Location: `packages/trn_core/test/fixtures/validation/`. Each fixture is a pair:

- `<name>.recipe.json`: a document valid against the schema
- `<name>.expected.json`: the exact multiset of `{code, subjects}` expected (messages excluded)

Required fixtures:

- one **valid** recipe for each SC-002 reference shape (split ingredient, preparation step,
  two-component dish, single-input step, 15+ ingredients), each expecting `[]`
- for **every code** in the table, one fixture that violates that rule and nothing else

The second set is what makes the suite non-vacuous (Principle IX): disable any one rule's check
and exactly one fixture fails.
