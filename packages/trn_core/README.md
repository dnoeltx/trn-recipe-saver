# trn_core

The recipe domain for TRN Recipe Saver, in pure Dart: the recipe document, the counter, the
structural validator, exact quantities, and the Tabular Recipe Notation table layout.

Nothing in this package may import Flutter. CI enforces that with `tool/check_core_purity.ps1`,
so everything here is testable in milliseconds without a device. See
`specs/001-manual-recipe-library/research.md` R8.
