# Code Style

## Why this document exists

The analyzer tells us "do / don't" but never *why*. To trust a rule in an
edge case, you need the reasoning behind it — otherwise the next similar
decision is made blindly and the rule is quietly violated.

This document records the **reasoning**, not the rule itself. The rule lives
in `analysis_options.yaml` (single source of truth, enforced there). This
file exists so a human — or an AI — can answer the "why" and reason about
edge cases instead of pattern-matching from memorized examples.

If you hit a case where the rule seems wrong, read the rationale and decide
from there. Don't apply the rule mechanically. If you deviate, leave a
comment saying why.

---

## Imports

**Rule:** `analysis_options.yaml` → `prefer_relative_imports: true`

### Short version

- Files inside this package (anything under `lib/`) reach each other via
  **relative imports**:
  ```dart
  import '../exceptions.dart';
  ```
- Files outside this package (third-party dependencies) come in via
  **package imports**:
  ```dart
  import 'package:equatable/equatable.dart';
  ```

### Why relative (inside the package)

**1. Part-file compatibility.** Generated part files (`part 'foo.g.dart';`)
must use the same import style as their host library. Projects that use
`@JsonSerializable` or other code generation end up with `.g.dart` files
everywhere; if the host file uses `package:` and the generated one uses
something else, the analyzer raises `part_of_different_library`. One style
throughout keeps things quiet.

**2. Decoupled from the package name.** Renaming the package (e.g. pub.dev
naming rules forcing `customflags` → `custom_flags`) means rewriting every
`package:customflags/...` import. Relative imports don't care about the
pubspec name, so a rename costs one line in `pubspec.yaml` instead of a
repo-wide find-and-replace.

**3. Refactor-friendly.** IDEs update relative imports automatically when a
file moves between folders. Package imports are absolute, so moving the
target file usually means fixing imports by hand.

**4. Decoupled from the external API surface.** `package:customflags/customflags.dart`
works only because `customflags.dart` re-exports the symbol you want. If
that export is ever removed (say, you decide a class should be internal),
every internal consumer that was using `package:` breaks. Internal code
organization and the external API are two different things; coupling them
creates fragile dependencies.

**5. Matches Dart community practice.** Flutter framework, dio, bloc,
riverpod — major packages all use relative imports within their own `lib/`.
`package:` is reserved for crossing the package boundary.

### Edge cases

- **`test/` files** — live outside `lib/`, so they see the package from the
  consumer's perspective. Use `package:` there.
- **`example/` apps** — a separate package. Always `package:`.
- **Generated code (`.g.dart`)** — build_runner emits the correct style on
  its own. Don't edit it by hand.
