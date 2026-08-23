import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_button.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';

class ReportStampScreen extends StatefulWidget {
  const ReportStampScreen({required this.stampId, super.key});

  final String stampId;

  @override
  State<ReportStampScreen> createState() => _ReportStampScreenState();
}

class _ReportStampScreenState extends State<ReportStampScreen> {
  String? _reason;

  static const List<String> _reasons = <String>[
    'Inappropriate content',
    'Harassment or bullying',
    'Sensitive image',
    'Spam or scam',
    'Something else',
  ];

  @override
  Widget build(BuildContext context) {
    return InkstampScaffold(
      title: 'Report stamp',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'What happened?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Reports are private. The sender will not know who reported them.',
            style: TextStyle(color: AppColors.charcoal),
          ),
          const SizedBox(height: AppSpacing.lg),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (String? value) => setState(() => _reason = value),
            child: Column(
              children: _reasons
                  .map((String reason) {
                    return RadioListTile<String>(
                      value: reason,
                      title: Text(reason),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.ink,
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const Spacer(),
          InkstampButton(
            label: 'Submit report',
            onPressed: _reason == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you. Your report was submitted.'),
                      ),
                    );
                    context.pop();
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
