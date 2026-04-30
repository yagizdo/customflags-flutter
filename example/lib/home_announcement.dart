import 'package:flutter/material.dart';

/// Typed view of the `home_announcement` JSON flag.
///
/// The factory tolerates malformed payloads by returning `null` when
/// any required field is missing or has the wrong type, or when the
/// announcement is explicitly disabled (`isActive: false`). That keeps
/// the rendering widget free of type-checking branches.
class HomeAnnouncement {
  const HomeAnnouncement({
    required this.title,
    required this.body,
    required this.ctaText,
  });

  final String title;
  final String body;
  final String ctaText;

  /// Placeholder shown when the flag is missing, inactive, or
  /// malformed. Mirrors the typical feature-flag pattern: a baseline
  /// experience always renders; the flag swaps in a richer one when
  /// configured on the backend.
  static const HomeAnnouncement defaultAnnouncement = HomeAnnouncement(
    title: 'No announcement configured',
    body: 'Set the home_announcement flag on your CustomFlags backend '
        'to override this card with a custom title, body, and CTA.',
    ctaText: 'Got it',
  );

  /// Returns a populated [HomeAnnouncement] when [json] has truthy
  /// `isActive` and string `title`/`body`/`ctaText`. Returns `null`
  /// otherwise — including when the announcement is intentionally
  /// disabled.
  static HomeAnnouncement? tryFromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'];
    if (isActive is! bool || !isActive) return null;

    final title = json['title'];
    final body = json['body'];
    final ctaText = json['ctaText'];
    if (title is! String || body is! String || ctaText is! String) {
      return null;
    }
    return HomeAnnouncement(title: title, body: body, ctaText: ctaText);
  }
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final HomeAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(announcement.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(announcement.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {},
                child: Text(announcement.ctaText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
