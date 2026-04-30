import 'package:customflags/customflags.dart';
import 'package:flutter/widgets.dart';

/// Fetches one flag and rebuilds when it arrives, fails, or is refreshed.
///
/// `refreshCount` is a counter the parent bumps when the user requests a
/// re-fetch (e.g. an AppBar refresh button). Whenever it changes, this
/// widget re-issues `client.getFlag(featureKey)`.
///
/// `builder` receives `null` while the fetch is pending and after any
/// failure (network error, missing flag). Type the value at the call
/// site with `flag?.getBool(...)`, `getString(...)`, or `getJson(...)` —
/// each accepts a `fallback` and never throws.
///
/// The SDK has no cache layer yet, so every mount issues an HTTP
/// request. When caching lands this widget will read synchronously
/// from the cache and drop [FutureBuilder].
class FlagBuilder extends StatefulWidget {
  const FlagBuilder({
    super.key,
    required this.client,
    required this.featureKey,
    required this.refreshCount,
    required this.builder,
  });

  final CustomFlagClient client;
  final String featureKey;
  final int refreshCount;
  final Widget Function(BuildContext context, Flag? flag) builder;

  @override
  State<FlagBuilder> createState() => _FlagBuilderState();
}

class _FlagBuilderState extends State<FlagBuilder> {
  late Future<Flag> _future = widget.client.getFlag(widget.featureKey);

  @override
  void didUpdateWidget(FlagBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshCount != oldWidget.refreshCount ||
        widget.featureKey != oldWidget.featureKey) {
      _future = widget.client.getFlag(widget.featureKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Flag>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'CustomFlags[${widget.featureKey}] fetch error: ${snapshot.error}',
          );
        }
        return widget.builder(context, snapshot.data);
      },
    );
  }
}
