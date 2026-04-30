# CustomFlags — Example App

A small Flutter app demonstrating the `customflags` SDK. Three feature
flags drive three pieces of UI: a promo banner (bool), an app theme
(string), and an announcement card (JSON object).

## Setup

1. Open `lib/main.dart` and replace the two placeholder constants with
   values from your CustomFlags backend:

   ```dart
   const String _apiKey = 'YOUR_API_KEY_HERE';
   const String _identifier = 'YOUR_USER_ID_HERE';
   ```

2. On your CustomFlags backend, create the three feature keys below
   for the user identified by `_identifier`. The "Feature keys" table
   below lists ready-to-paste sample values for each.

## Feature keys

Each section always renders something — the page is never empty.
That mirrors how a real app uses feature flags: ship a baseline
experience, then swap in a richer one when the flag is on.

| Key | Type | Example values | UI effect |
|---|---|---|---|
| `show_promo_banner` | bool | `true` / `false` | `true` → promo banner (campaign icon, primary container colour). `false`/missing/wrong type → standard-view banner (info icon, secondary container colour). |
| `theme_variant` | string | `"premium"` / `"free"` | `"premium"` → deep-purple Material 3 theme. Anything else (including missing) → blue-grey theme. The active variant is also printed at the bottom of the page. |
| `home_announcement` | JSON object | `{"title": "Spring sale", "body": "20% off everything", "ctaText": "Shop now", "isActive": true}` | Valid payload with `isActive: true` → custom announcement card. Inactive, missing, or malformed → default placeholder card prompting the developer to configure the flag. |

## Run

```sh
flutter pub get
flutter run
```

Tap the refresh icon in the AppBar to re-fetch every flag from the
backend. Flip a flag's value on your dashboard, tap refresh, and the
matching widget updates.

## How the demo is wired up

Three files in `lib/`:

* `main.dart` — boots the SDK client, builds the `HomePage`, holds the
  refresh counter, and lays out the three flag-driven sections.
* `flag_builder.dart` — a small `FlagBuilder` widget that fetches one
  flag and exposes a `Flag?` to its builder. Pending and failed fetches
  both surface as `null`; the call site picks the typed getter
  (`flag?.getBool(...)`, `getString(...)`, `getJson(...)`) and supplies
  a fallback. This is the reusable pattern an app would copy.
* `home_announcement.dart` — a typed view of the JSON flag plus the
  card widget that renders it.

## Troubleshooting

If a flag doesn't seem to take effect, watch the debug console for
lines like:

```
CustomFlags[show_promo_banner] fetch error: ...
```

That means the network call failed or the flag is missing. The widget
falls back silently to its default value.

## Note: cache pending

This example calls `client.getFlag(featureKey)` from inside each
`FlagBuilder`, meaning every widget mount issues an HTTP request. The
SDK does not yet have a cache layer; when one lands, `FlagBuilder`
will be revised to read synchronously from the cache and drop
`FutureBuilder`. The current pattern is the most direct way to
demonstrate the per-widget consumption shape.
