import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/feedback_service.dart';

/// Muestra el aviso beta una vez (SharedPreferences) tras el primer frame.
Future<void> maybeShowBetaNotice(BuildContext context) async {
  final feedback = FeedbackService();
  if (await feedback.wasBetaNoticeDismissed()) return;
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.translate('beta_notice_title')),
      content: Text(l10n.translate('beta_notice_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.translate('beta_notice_dismiss')),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final opened = await feedback.openReportProblem();
            if (!context.mounted) return;
            if (!opened) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translate('report_problem_no_mail_app'))),
              );
            }
          },
          child: Text(l10n.translate('report_problem')),
        ),
      ],
    ),
  );

  await feedback.dismissBetaNotice();
}
