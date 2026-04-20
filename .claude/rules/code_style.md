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

---

## Const discipline

**Rules:** `analysis_options.yaml` →
- `prefer_const_constructors_in_immutables: true`
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- `prefer_const_declarations: true`

### Short version

- If a class is immutable (all fields `final`, or `extends Equatable`, or
  `@immutable`), its constructor should be `const`.
- When calling such a constructor with compile-time-known arguments, prefix
  the invocation with `const`.
- Collection literals (`[...]`, `{...}`) passed where a const value is
  accepted should be `const [...]`, `const {...}`.
- Local variables whose initializer is a compile-time constant should be
  declared `const`, not `final`.

```dart
// constructor declaration
const FlagResponse({required this.flags});

// constructor invocation
const flag = Flag(key: 'dark_mode', value: true);

// collection literal in const-accepting position
const defaults = <String, bool>{'dark_mode': false};

// local const (not final)
const retries = 3;
```

### Why we care

**1. Canonicalization — one object, many uses.** `const` values are built once
at compile time and every `const Foo()` literal with the same arguments
resolves to the **same** object instance. Without `const`, each invocation
allocates a fresh object on the heap. For small data classes this is fine;
for hot code (Flutter `build()`, per-frame loops) it adds up.

**2. Widget tree stability (when this SDK consumer is a Flutter app).**
`const` widgets do not rebuild when their parent rebuilds — Flutter's
element tree reuses them directly. A missing `const` on a deeply-nested
widget forces the whole subtree to rebuild on every parent tick. If our SDK
surfaces widgets later (unlikely here, but possible), we want them
const-constructible so consumers benefit automatically.

**3. `const` is a stronger signal than `final`.** `final` promises "this
reference won't be reassigned". `const` promises "this object is fully
frozen, recursively, forever, from compile time". For value types (Flag,
FlagResponse, exceptions) the stronger guarantee matches the semantics. The
lint forces us to declare what we already mean.

**4. `@immutable` classes silently break without const.** Equatable is
annotated `@immutable`. `prefer_const_constructors_in_immutables` catches
every new value type that forgets the `const` constructor declaration —
otherwise the bug is invisible until someone else tries `const Flag(...)`
and gets a cryptic "cannot be used in a const context" error.

**5. The four lints form a layered net.**
- `_in_immutables` catches the declaration site (most important — fixes
  root cause).
- `prefer_const_constructors` catches call sites that could benefit.
- `_literals_to_create_immutables` catches nested collection literals
  inside const-context positions.
- `_declarations` catches locals where `final` is weaker than warranted.

Each layer closes a gap the others leave open.

### Edge cases

- **Factory constructors cannot be const.** Language restriction — factories
  are free-form and may execute arbitrary logic. If you need a const variant,
  expose a named const constructor alongside the factory.
- **Non-final fields block const.** If even one field is non-final, the class
  cannot have a const constructor. The fix is usually to make the field
  final, not to remove const.
- **Generated code is not lint-clean.** The `.g.dart` files built by
  `json_serializable` are excluded from lints (the generator marks them).
  Don't chase warnings into `.g.dart` — they're not your code.
- **Subclasses of non-const classes can't be const.** If you extend a class
  whose constructor isn't const, yours can't be either. Lint may fire but
  won't be fixable without changing the parent. Leave a comment if you
  `// ignore:` it.
- **`const` call sites with runtime values don't apply.** The lint only
  fires when all arguments are themselves compile-time constants. If you
  pass a runtime variable, plain `Foo(x)` is correct — no warning.
