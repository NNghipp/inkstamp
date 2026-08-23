import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() {
    return _NotificationSettingsScreenState();
  }
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _newStamps = true;
  bool _reactions = true;
  bool _friendRequests = true;
  bool _previewNames = true;

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      title: 'Notifications',
      body: ListView(
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            value: _newStamps,
            onChanged: (bool value) => setState(() => _newStamps = value),
            title: const Text('New stamps'),
            subtitle: const Text('When a friend sends a new stamp'),
            activeThumbColor: AppColors.ink,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _reactions,
            onChanged: (bool value) => setState(() => _reactions = value),
            title: const Text('Reactions and replies'),
            subtitle: const Text('When someone responds to your stamp'),
            activeThumbColor: AppColors.ink,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _friendRequests,
            onChanged: (bool value) {
              setState(() => _friendRequests = value);
            },
            title: const Text('Friend requests'),
            activeThumbColor: AppColors.ink,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: AppSpacing.xl),
          SwitchListTile(
            value: _previewNames,
            onChanged: (bool value) => setState(() => _previewNames = value),
            title: const Text('Show sender name'),
            subtitle: const Text(
              'Photos are never shown in Lock Screen notifications.',
            ),
            activeThumbColor: AppColors.ink,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
