import 'package:flutter/material.dart';

/// SCRUM-198: atajos rápidos de caducidad (Hoy / +3 / +7 / +30).
class ExpiryDateQuickChips extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelected;
  final EdgeInsetsGeometry padding;

  const ExpiryDateQuickChips({
    super.key,
    this.selectedDate,
    required this.onSelected,
    this.padding = const EdgeInsets.only(top: 8),
  });

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static DateTime fromOffsetDays(int days) => today().add(Duration(days: days));

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String>['Hoy', '+3 d', '+7 d', '+30 d'];
    final dates = <DateTime>[
      today(),
      fromOffsetDays(3),
      fromOffsetDays(7),
      fromOffsetDays(30),
    ];

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List<Widget>.generate(labels.length, (i) {
          final label = labels[i];
          final date = dates[i];
          return ChoiceChip(
            label: Text(label),
            selected: _isSameDay(selectedDate, date),
            onSelected: (_) => onSelected(date),
          );
        }),
      ),
    );
  }
}
