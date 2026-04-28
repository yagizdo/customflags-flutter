# customflags

A Flutter SDK for feature flags, remote configuration, and runtime toggles.

Ship features safely, roll them out gradually, and change behavior without a new release.

> ⚠️ **Early development** — API is not yet stable. Not recommended for production use.

## Features

- Boolean, string, and numeric feature flags
- Remote-controlled values with local fallbacks
- User/segment targeting
- Environment-based configuration (dev / staging / prod)
- Reactive API for widgets to rebuild when flag values change

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  customflags: ^0.0.1
```

Then:

```sh
flutter pub get
```

## Usage

```dart
import 'package:customflags/customflags.dart';
```

See [`example/`](example/) for a runnable app.

## Smoke test coverage

The end-to-end flow has been hand-verified via `example/lib/smoke.dart`
against a live backend. Until full integration tests land, the following
paths are known **green** vs. **unverified**:

**Verified:**
- `CustomFlagClient.fetchAllFlags()` parses a multi-flag response.
- `CustomFlagClient.getFlag(key)` parses a single-flag response with the
  same envelope shape as `fetchAllFlags`.
- `getFlag('')` throws `ArgumentError`.
- Calls before `setIdentity()` throw `ConfigurationException`.

**Not yet verified end-to-end:**
- Typed readers on `Flag` (`getBool`, `getString`, `getInt`, `getDouble`,
  `getJson`) — only `Flag.value` has been read against live data, the
  type-narrowing branches have not been exercised.
- `TypeMismatchException` path — reading a flag as the wrong type.
- `getFlag(key)` with an unknown key — backend behavior and the
  `flags.length != 1` guard inside `ApiClient.fetchFlag` are unverified.
- Network failure modes other than HTTP 401 (timeout, connection error,
  5xx).
- URL-encoded path keys — only plain ASCII keys (`dark_mode`) have been
  exercised; keys containing `/`, spaces, or unicode are untested.

## Platform notes

> **Android — HTTP backend.** The current development backend is served
> over plain HTTP. Android 9+ blocks cleartext traffic by default, so
> apps targeting the dev environment need to opt in via
> `android:usesCleartextTraffic="true"` in their `AndroidManifest.xml`
> (or a domain-scoped network security config). This is a temporary
> state — once the backend moves to HTTPS, no consumer-side change is
> required.

## Roadmap

- [ ] Core flag evaluation API
- [ ] Remote config fetch & cache layer
- [ ] User / segment targeting
- [ ] Reactive widget bindings
- [x] Example application
- [ ] Tests & documentation
- [ ] Publish to pub.dev

## Contributing

Issues and pull requests are welcome.

## License

[MIT](LICENSE) © 2026 Yağız Dokumaci
