# TRN Recipe Saver Constitution

## Core Principles

### I. The Model Suggests, the Validator Decides

A language model turns imported text or photos into a structured recipe. Its output is a proposal,
never a result.

- No model output is saved as a valid recipe until deterministic code has checked it against the
  conversion schema and the TRN structural rules: every ingredient is used, every step input
  exists, and the merges form a valid tree.
- On validation failure the pipeline MAY retry once with the validation errors, and MAY escalate
  to a larger model. Every retry and escalation is counted and recorded (see Principle III).
- If validation still fails, the parsed content opens in the editor clearly marked as needing
  review. It MUST NOT be saved as a valid recipe until it passes the same validation.
- The validator is ordinary code, owned by this repository and covered by tests. It does not call
  a model.

Rationale: a model is fast and usually right, and "usually" is not a property a user's library can
rest on. Deterministic validation turns the model from an authority into an assistant.

### II. Conversion Quality Is Measured

- A fixed test set of varied recipes is maintained, including known hard cases (split and
  recombined components, discarded ingredients, pre-steps, handwritten cards, ambiguous grouping).
- Any change to the prompt, the model, the schema, or the validator MUST be run against the full
  test set before merging, with the scores recorded in the pull request.
- A regression in the scores blocks the merge unless the pull request justifies it explicitly.
- The production model is the least expensive one that meets the recorded quality bar.

Rationale: without a fixed measuring stick, every prompt tweak is judged by the last example
someone happened to try.

### III. Cost Is Tracked

- The cost of every conversion (tokens in and out, retries, escalations, cache hits) is recorded.
- Hard spending limits at the provider and per-user usage limits in the backend MUST exist before
  the import feature is available to anyone other than the owner.
- Conversions are cached by normalized source, so the same recipe is not paid for twice.
- Any pull request that changes the pipeline reports its expected effect on cost per conversion.

Rationale: an unbounded per-call cost on a public endpoint is a liability. Measured cost is a
design input, not an invoice surprise.

### IV. The Structure Is the Recipe

- A recipe is stored as structured data: ingredients, steps, and the inputs each step combines.
  The TRN table is always rendered from that data and never stored as an image.
- Manual entry and editing MUST satisfy the same structural rules as an imported recipe. A
  hand-entered recipe cannot be structurally invalid either.
- Scaling, editing, and display all operate on the structure, never on rendered output.

Rationale: one source of truth means editing and scaling just work, and one rule set means a
recipe is valid no matter how it entered the library.

### V. Works Without AI

- Manual entry, the library, search, viewing, editing, scaling, and personal notes work fully
  offline and without any model call.
- Only importing (from a URL or a photo) requires the network.

Rationale: the library is the product. AI import is a convenience on top of it, and a dropped
connection or an unavailable provider must never cost the user access to their own recipes.

### VI. Respect the Source

- Every imported recipe keeps a reference to its source (URL, or that it came from a photo).
- The library is private to the user. The app does not republish recipe text or photos.
- Michael Chu is credited inside the app as the creator of Tabular Recipe Notation.
- Copyrighted or personal test inputs (cookbook pages, family recipe cards) are never committed to
  this repository; only the test harness and its scored results are.

Rationale: recipe authors and the format's creator deserve credit, and a public repository is
publishing.

### VII. The User Owns Their Data

- The recipe library is stored on the device.
- User content leaves the device by only two paths:
  - an import the user starts, sending only what that import needs (the URL or the photo). The
    app tells the user this, and the model provider's data retention and training terms are
    verified and disclosed before release;
  - the platform's own user-controlled device backup (Android backup to the user's Google
    account, iCloud backup), which the app participates in so a replaced phone restores the
    library.
- Crash reports (below) MUST NOT contain recipe content.
- No API key or other secret is ever included in the app or the repository. Provider keys live
  only in the backend.
- An anonymous identity used only for usage limits and abuse prevention is allowed. User accounts,
  sign-in, and sync require an amendment to this constitution first.
- Anonymous crash reports are allowed, disclosed in the privacy policy. Usage analytics are not.

### VIII. One Codebase, Both Platforms

- Android and iOS are built from one codebase. Platform-specific code (share targets, camera,
  file access) is limited to what each platform requires and sits behind an interface.
- Day-to-day development and testing happen on Android. iOS is verified on a real iPhone at each
  milestone, from a checklist of platform-specific behaviors.
- An iOS milestone is reached before any build is given to anyone other than the owner. Each
  milestone's iOS checklist is kept in the specification that reaches it.
- Every numbered specification ends with a successful unsigned iOS build from hosted macOS CI, so
  code that does not compile for iOS is found within one specification even between milestones.
- No release goes to either store without having been verified on a real device of that platform.

Rationale: iOS access is limited to scheduled sessions. Batching iOS verification at milestones
keeps it deliberate rather than skipped.

### IX. Test-First

- Tests are written before the code they cover, everywhere in the codebase, and are seen to fail
  before the implementation makes them pass.
- Code that is hard to test directly (network calls, the model provider, platform services) MUST
  sit behind interfaces so the logic around it can still be developed test-first.
- Where a test genuinely cannot precede the code, the pull request MUST state why and describe
  how the behavior was verified instead. Silent exceptions are not permitted.
- Tests MUST be shown to be non-vacuous: deliberately breaking the behavior a test guards MUST
  make it fail.

### X. Spec Before Code

- No feature is implemented without a specification that has passed the Spec Kit workflow gates
  (specify, clarify, plan, tasks, analyze).
- Ideas that emerge during development go to the backlog and become their own numbered
  specification. They MUST NOT be folded into the feature in progress.
- Scope changes to an in-progress feature require updating its spec first, then the plan and
  tasks, before the code changes.

### XI. Evidence Over Assumption

- Claims about platforms, library versions, APIs, store policies, and model pricing MUST be
  verified against a primary source or measured before a design depends on them.
- Thresholds and tuning values (quality bars, usage limits, cost targets) MUST come from data,
  with the evidence and reasoning written down.
- A partial or degraded result MUST fail loudly rather than be presented as complete.

## Constraints

- **Framework.** Flutter, one codebase for Android and iOS.
- **Backend.** Managed serverless functions only. No self-managed servers and no self-hosted
  models; the model runs at a provider, called from the backend.
- **No iOS build machine is owned.** iOS builds run on hosted macOS CI. Plans MUST account for
  this.
- **Offline core.** Everything listed in Principle V works with no network connection.
- **Public repository.** Private planning notes and private test inputs are kept out of version
  control by `.gitignore`, and nothing committed may contain secrets.

## Development Workflow and Quality Gates

- All work happens on a branch (`feature/`, `fix/`, `chore/`, `docs/`) and reaches `main` only by
  pull request. `main` is protected; force pushes and deletion are disabled.
- Once CI exists, its build and test check is required on `main`, enabled in the same pull
  request that introduces CI.
- Commit messages follow Conventional Commits.
- The project owner runs all git and GitHub commands personally; AI assistance advises and
  prepares, it does not execute repository operations on the owner's behalf.
- AI-generated code, claims, and version numbers are held to Principle XI like any other input.
- Significant decisions and their reasoning are recorded in the README or the relevant spec, not
  only in conversation.
- Every plan phase includes a Constitution Check against these principles, and every pull request
  confirms compliance or documents a justified exception.

## Governance

- This constitution supersedes other practices in this repository. Where a spec, plan, or task
  conflicts with it, the constitution wins until it is amended.
- Amendments are made by pull request, with the rationale in the description, and require a
  version bump:
  - MAJOR: a principle removed or redefined in a backward-incompatible way.
  - MINOR: a principle or section added, or guidance materially expanded.
  - PATCH: clarifications and wording that do not change meaning.
- Existing specs and plans are re-checked against an amended constitution before further work on
  them proceeds.

**Version**: 1.2.0 | **Ratified**: 2026-10-08 | **Last Amended**: 2026-10-08
