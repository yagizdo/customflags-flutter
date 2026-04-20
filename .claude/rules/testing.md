# Testing Standards

## Why this document exists

Test output is read by people who did not write the test — teammates, future
you, AI agents, CI bots — and they often see only the failing line, not the
surrounding code. They have to decide whether it is a real regression or a
flake from that line alone.

If the test name is vague, the reader has to open the source, reconstruct the
setup, and guess the intent. That is a tax paid on every failure. Clear test
names pay that tax once, at write-time.

This file explains the **reasoning** behind our conventions, not just the rules.
When you hit an edge case, use the reasoning to decide — do not mechanically
apply a rule that no longer fits. If you deviate, leave a comment saying why.

## Naming convention

```dart
group('ClassUnderTest', () {
  test('[ClassUnderTest] <observable behavior> when <condition>', () { ... });
});
```

Two parts in every test name:

1. A bracketed tag: `[ClassUnderTest]`
2. A plain-English behavior description, ideally with the triggering condition.

### Why the bracketed prefix

Flutter's test runner prints `group > test description`. In many contexts
(CI logs, terminal tails, diff viewers, bug reports) only the test description
survives — the group name gets stripped.

If five different exceptions all have a test called
`"uses default message when none provided"`, the log is ambiguous. Which one
broke? You cannot tell without opening the run manually.

The bracket tag makes each line self-describing. Small duplication with the
group name, big win for readability everywhere the group context is lost.

### Why natural-language behavior descriptions

Vague names like `"has correct default message"` fail the stranger-test: a
new reader cannot know what "correct" means without reading the body. Every
test becomes a puzzle.

```dart
// Vague — "correct" relative to what?
test('has correct default message', ...);

// Describes implementation, not behavior
test('calls super with default string', ...);

// Describes observable behavior and condition
test('uses default message when none provided', ...);
```

Rule of thumb: if the test fails in CI and you see only the name, does the
name alone tell you what regressed? If not, rename it.

### Phrasings to avoid and why

- **"requires X"** — Dart enforces required parameters at compile time. A
  runtime test cannot prove "required-ness"; it can only prove that a value,
  once passed, is stored. Use `"stores the provided X"`.
- **"works correctly"**, **"should work"** — zero information. Every test is
  there because something should work.
- **"test X"** at the start — `test(...)` already signals "this is a test".

## Examples by category

### Defaults and overrides
- `[NetworkException] uses default message when none provided`
- `[NetworkException] uses provided message when specified`

### Field storage
- `[ApiClientException] stores statusCode, body and message`
- `[ApiClientException] allows null body`

### toString
- `[ApiClientException] toString includes statusCode and body`

### Equality (Equatable)
- `[ApiClientException] instances with identical fields are equal`

### Derived values
- `[TypeMismatchException] builds message from flagKey, expected and actual types`

## When it is okay to deviate

The format above assumes a single class under test. Real code has edge cases:

- **Free functions / extensions** — the "class" is a function. Put the function
  name in the tag: `[debounce] cancels pending calls on dispose`.
- **Integration tests spanning multiple classes** — use the feature or flow
  name: `[FlagsInit] boots with defaults when config is empty`.
- **Regression tests for a specific issue** — prepend the issue number after
  the tag: `[ApiClientException] (#42) preserves body when message is empty`.
  Future readers can jump straight to the bug report.

Do not deviate to save keystrokes. A longer, honest name is always cheaper
than one hour of confused debugging.

## Keeping this standard alive

- This applies to unit, widget, and integration tests in this package.
- When this file changes, update existing tests in the same commit. Two
  parallel standards in the codebase is worse than one imperfect standard.
- If a convention here starts feeling wrong across several tests, that is a
  signal to revise **this document**, not to quietly ignore it in new tests.

---

## Invariant tests alongside fixture-driven tests

### The circularity trap

When a test loads a fixture (or inline JSON) and asserts specific output
values, both sides are author-written. The pair is internally consistent
by construction. The test only catches *fixture drift* — someone changing
one side without the other. A logic bug that produces different-but-self-
consistent output sails through.

```dart
// Circular: the fixture has 2 flags because I put them there.
// A bug that always returns a list of 2 would pass this test.
test('[FlagResponse] flags_bool.json yields two flags', () async {
  expect((await _fromFixture('flags_bool.json')).flags.length, 2);
});
```

The assertion (`length == 2`) is a *magic number* derived from the
author's fixture choice, not from the input. That is where the blind spot
lives.

### What to add: invariant tests

For every data-driven test group, add at least one **invariant test** —
an assertion derived from the input itself, holding for any syntactically
valid shape.

```dart
test('[FlagResponse] fromJson produces one Flag per input map entry', () {
  final input = <String, dynamic>{'a': true, 'b': 'x', 'c': 42};

  final response = FlagResponse.fromJson({'flags': input});

  // Invariant: |output| == |input|. Holds regardless of which keys
  // or how many keys this input happens to contain.
  expect(response.flags.length, input.length);
});
```

A logic bug that hard-codes a count, drops an entry, or duplicates one
would fail this test for *any* input — not just the author-chosen one.

### Why keep fixtures too

Invariants prove logic; fixtures prove integration. A fixture file
verifies the code handles what actually comes off the wire:

- Formatting quirks (trailing whitespace, newline styles, unicode)
- Real-world number parsing (JSON spec integers vs doubles)
- Keys the SDK would plausibly encounter (realistic names, not `'a'`/`'b'`)
- Regression anchors — a named fixture is a stable artifact that
  documents "this is a shape the SDK handled, and must keep handling"

Drop neither. Use both.

### Rule of thumb

- **Fixture-content test:** "when input has X, output has Y" — magic
  number or hand-picked value on the assertion side. Catches fixture
  drift, not logic bugs.
- **Invariant test:** "for any input, property P(input, output) holds"
  — assertion derived from the input. Catches logic bugs regardless of
  input choice.

Every group that does data-driven testing should have at least one of
each. When adding new model or service tests, ask yourself: "if I
hard-coded the output, would my tests catch it?" If the answer is no,
you need an invariant.
