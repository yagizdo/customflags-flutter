import 'package:customflags/customflags.dart';
import 'package:flutter/widgets.dart';

/// Subscribes to [CustomFlagClient.flagStream] and rebuilds whenever
/// the cached flags change (after [CustomFlagClient.init] or
/// [CustomFlagClient.refresh]).
///
/// [builder] receives the current [Flag] for [featureKey] — never
/// `null`. Before the cache is populated the flag's [Flag.value] is
/// `null`, so use the typed getters with a `fallback`:
///
/// ```dart
/// FlagBuilder(
///   client: client,
///   featureKey: 'dark_mode',
///   builder: (context, flag) {
///     final isDark = flag.getBool(fallback: false);
///     return Text('Dark mode: $isDark');
///   },
/// );
/// ```
class FlagBuilder extends StatelessWidget {
  const FlagBuilder({
    super.key,
    required this.client,
    required this.featureKey,
    required this.builder,
  });

  final CustomFlagClient client;
  final String featureKey;
  final Widget Function(BuildContext context, Flag flag) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, Flag>>(
      stream: client.flagStream,
      builder: (context, _) {
        final flag = client.getFlag(featureKey);
        return builder(context, flag);
      },
    );
  }
}
