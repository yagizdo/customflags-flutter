# customflags_flutter

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
  customflags_flutter: ^0.0.1
```

Then:

```sh
flutter pub get
```

## Usage

```dart
import 'package:customflags_flutter/customflags_flutter.dart';
```

A runnable example will live under [`example/`](example/) once added.

## Roadmap

- [ ] Core flag evaluation API
- [ ] Remote config fetch & cache layer
- [ ] User / segment targeting
- [ ] Reactive widget bindings
- [ ] Example application
- [ ] Tests & documentation
- [ ] Publish to pub.dev

## Contributing

Issues and pull requests are welcome.

## License

[MIT](LICENSE) © 2026 Yağız Dokumaci
