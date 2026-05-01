import 'package:customflags/customflags.dart';
import 'package:flutter/material.dart';

import 'flag_builder.dart';
import 'home_announcement.dart';

const String _apiKey =
    'oflag_development_d519e82f2f884da452980a78ea25729dd26c45e789d7afb1';
const String _identifier = 'demouser';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = CustomFlagClient(
    config: CustomFlagConfig(apiKey: _apiKey),
  );
  client.setIdentity(const Identity(identifier: _identifier));
  await client.init();

  runApp(MaterialApp(
    title: 'CustomFlags Demo',
    theme: ThemeData(useMaterial3: true),
    home: HomePage(client: client),
  ));
}

/// Single demo page. Four flag-driven sections:
///
/// * page [Theme], driven by `theme_variant` (string)
/// * a banner that swaps default ↔ promo, driven by `show_promo_banner` (bool)
/// * an announcement card, driven by `home_announcement` (JSON)
/// * a free-trial tile, driven by `free_trial_days` (int)
///
/// Each section always renders something — the page is never empty.
/// That mirrors how a real app uses feature flags: ship a baseline
/// experience, then swap in a richer one when the flag is on.
///
/// The AppBar refresh button calls [CustomFlagClient.refresh], which
/// fetches fresh flags from the backend and updates every
/// [FlagBuilder] in the subtree via [CustomFlagClient.flagStream].
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.client});

  final CustomFlagClient client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomFlags Demo'),
        actions: [
          IconButton(
            tooltip: 'Refresh flags',
            icon: const Icon(Icons.refresh),
            onPressed: () => client.refresh(),
          ),
        ],
      ),
      body: FlagBuilder(
        client: client,
        featureKey: 'theme_variant',
        builder: (context, flag) {
          final variant = flag.getString(fallback: 'free');
          return Theme(
            data: _themeFor(variant),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                FlagBuilder(
                  client: client,
                  featureKey: 'show_promo_banner',
                  builder: (context, flag) {
                    final showPromo = flag.getBool(fallback: false);
                    return _Banner(showPromo: showPromo);
                  },
                ),
                FlagBuilder(
                  client: client,
                  featureKey: 'home_announcement',
                  builder: (context, flag) {
                    final json = flag.getJson(fallback: const {});
                    final announcement =
                        HomeAnnouncement.tryFromJson(json) ??
                            HomeAnnouncement.defaultAnnouncement;
                    return AnnouncementCard(announcement: announcement);
                  },
                ),
                FlagBuilder(
                  client: client,
                  featureKey: 'free_trial_days',
                  builder: (context, flag) {
                    final days = flag.getInt(fallback: 0);
                    return _FreeTrialTile(days: days);
                  },
                ),
                _ThemeFooter(variant: variant),
              ],
            ),
          );
        },
      ),
    );
  }
}

ThemeData _themeFor(String variant) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor:
            variant == 'premium' ? Colors.deepPurple : Colors.blueGrey,
      ),
      useMaterial3: true,
    );

class _Banner extends StatelessWidget {
  const _Banner({required this.showPromo});

  final bool showPromo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg =
        showPromo ? scheme.primaryContainer : scheme.secondaryContainer;
    final fg =
        showPromo ? scheme.onPrimaryContainer : scheme.onSecondaryContainer;
    final icon = showPromo ? Icons.campaign : Icons.info_outline;
    final text = showPromo
        ? 'Promo banner is on (show_promo_banner = true).'
        : 'Standard view — flip show_promo_banner to true on the backend '
            'to swap this for a promo banner.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ],
      ),
    );
  }
}

class _FreeTrialTile extends StatelessWidget {
  const _FreeTrialTile({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = days > 0;
    final icon = isActive ? Icons.timer : Icons.timer_off;
    final text = isActive
        ? 'Free trial: $days day${days == 1 ? '' : 's'} remaining.'
        : 'No free trial active — set free_trial_days to a positive int '
            'on the backend to enable it.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeFooter extends StatelessWidget {
  const _ThemeFooter({required this.variant});

  final String variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active theme: $variant', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Flip flags on your CustomFlags backend, then tap the refresh '
            'icon above.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
