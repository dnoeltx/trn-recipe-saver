# TRN Recipe Saver (working name)

**Status: in development. No release yet, and nothing here runs so far.** The repository
currently holds the Spec Kit scaffold; the constitution and first specification come next.

A phone app that imports a recipe (from a web page, a photo of a cookbook page, or typed
in by hand) and keeps it in a personal library as a **Tabular Recipe Notation** table:
ingredients run down the left, steps run left to right, and each step's cell spans
everything it combines. One glance shows what goes together and when.

Tabular Recipe Notation was created by **Michael Chu** at
[Cooking for Engineers](https://www.cookingforengineers.com/) in 2004. This project is
not affiliated with him; it builds on a format he made freely available.

## Why this repository looks the way it does

This is the fourth in a series of apps built with Claude Code, each one deliberately
escalating the *development process*:

1. [ChecklistV1](https://github.com/dnoeltx/ChecklistV1): built ad hoc. CI, tests, a real
   database migration that preserved user data across an upgrade.
2. [historical-marker-alerts](https://github.com/dnoeltx/historical-marker-alerts):
   planned up front, offline-first, with a data pipeline and an architecture-arguing
   README.
3. [custom-binaural-beats](https://github.com/dnoeltx/custom-binaural-beats):
   specification-driven, using [GitHub Spec Kit](https://github.com/github/spec-kit).
4. **This one**: also Spec Kit, and the first in the series that is
   - **cross-platform**, Android and iOS from one Flutter codebase
   - backed by a **server-side function**, so no secret ever ships inside the app
   - built around a **language model**, held behind engineering controls: one model call
     per import, checked by deterministic validation before anything is saved, and
     measured against a fixed test set whenever the prompt or model changes

The process is part of the deliverable. Decisions are written down with their reasons,
and claims are checked against primary sources rather than asserted from memory.

## Rights

Source visible for review; all rights reserved. See [LICENSE](LICENSE).
