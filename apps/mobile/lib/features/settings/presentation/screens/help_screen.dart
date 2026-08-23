import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      title: 'Help',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          ...const <(String, String)>[
            (
              'Who can see my stamps?',
              'Only friends included in the audience when the stamp is sent.',
            ),
            (
              'Will people know they are Close Friends?',
              'No. Your Close Friends list is completely private.',
            ),
            (
              'Can I take back a stamp?',
              'Yes. Delete for everyone removes it from Inbox, Archive and the widget.',
            ),
            (
              'Does Inkstamp save my location?',
              'No. EXIF and GPS metadata are removed before upload.',
            ),
          ].map(((String, String) item) {
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                item.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    item.$2,
                    style: const TextStyle(color: AppColors.charcoal),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Contact support'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Community Guidelines'),
          ),
          TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
        ],
      ),
    );
  }
}
