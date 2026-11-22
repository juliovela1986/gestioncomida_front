import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// SCRUM-193: pill de caducidad (días restantes / caducado hace N).
/// Copy propio — no clonar estilo ALL-CAPS del competidor.
class ExpiryStatusChip extends StatelessWidget {
  /// Días hasta caducar. Negativo = caducado hace N días. `0` = caduca hoy.
  final int? daysUntil;
  final bool hasDate;

  const ExpiryStatusChip({
    super.key,
    required this.daysUntil,
    this.hasDate = true,
  });

  /// Lista de caducados pendientes (`daysExpired` ≥ 0).
  factory ExpiryStatusChip.expiredAgo(int daysExpired) {
    if (daysExpired <= 0) {
      return const ExpiryStatusChip(daysUntil: 0);
    }
    return ExpiryStatusChip(daysUntil: -daysExpired);
  }

  static Color colorFor({required bool hasDate, int? daysUntil}) {
    if (!hasDate || daysUntil == null) return Colors.grey;
    if (daysUntil < 0) return Colors.red;
    if (daysUntil == 0) return Colors.deepOrange;
    if (daysUntil <= 3) return Colors.orange;
    return Colors.green;
  }

  String _label(AppLocalizations l10n) {
    if (!hasDate) return l10n.noDateShort;
    if (daysUntil == null) return l10n.noDateShort;
    if (daysUntil! < 0) return l10n.expiredDaysAgo(-daysUntil!);
    if (daysUntil == 0) return l10n.expiresToday;
    return l10n.daysLeft(daysUntil!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = colorFor(hasDate: hasDate, daysUntil: daysUntil);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        _label(l10n),
        style: TextStyle(
          color: color.shade700IfMaterial,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

extension on Color {
  /// Prefer darker shade for text when this is a MaterialColor.
  Color get shade700IfMaterial {
    if (this is MaterialColor) {
      return (this as MaterialColor).shade700;
    }
    return this;
  }
}
