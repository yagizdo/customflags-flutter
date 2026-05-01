import 'package:customflags/customflags.dart';
import 'package:flutter/widgets.dart';

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
