import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/preferences_service.dart';
import '../services/cleanup_preferences_service.dart';
import '../services/inventory_service.dart';
import '../l10n/app_localizations.dart';
import '../models/pending_expiration_item.dart';

typedef CleanupPreferencesLoader = Future<CleanupPreferencesResponseDto> Function();
typedef CleanupPreferencesUpdater = Future<CleanupPreferencesResponseDto> Function(
  CleanupPreferencesUpdateRequestDto request,
);
typedef ExpiredPendingSummaryLoader = Future<ExpiredPendingSummaryResponseDto> Function();

class SettingsScreen extends StatefulWidget {
  final CleanupPreferencesLoader? loadCleanupPreferences;
  final CleanupPreferencesUpdater? updateCleanupPreferences;
  final ExpiredPendingSummaryLoader? loadExpiredPendingSummary;

  const SettingsScreen({
    super.key,
    this.loadCleanupPreferences,
    this.updateCleanupPreferences,
    this.loadExpiredPendingSummary,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CleanupPreferencesService _cleanupPreferencesService = CleanupPreferencesService();
  final InventoryService _inventoryService = InventoryService();

  bool _isLoadingCleanup = true;
  bool _isSavingCleanup = false;
  String? _cleanupError;
  CleanupPreferencesResponseDto? _cleanupPreferences;
  ExpiredPendingSummaryResponseDto? _summary;

  @override
  void initState() {
    super.initState();
    _loadCleanupData();
  }

  Future<void> _loadCleanupData() async {
    setState(() {
      _isLoadingCleanup = true;
      _cleanupError = null;
    });

    try {
      final preferences = await (widget.loadCleanupPreferences?.call() ??
          _cleanupPreferencesService.getCleanupPreferences());
      final summary = await (widget.loadExpiredPendingSummary?.call() ??
          _inventoryService.getExpiredPendingSummary());

      if (!mounted) return;
      setState(() {
        _cleanupPreferences = preferences;
        _summary = summary;
        _isLoadingCleanup = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cleanupError = e.toString();
        _isLoadingCleanup = false;
      });
    }
  }

  Future<void> _saveCleanupPreferences() async {
    final current = _cleanupPreferences;
    if (current == null || _isSavingCleanup) return;

    setState(() => _isSavingCleanup = true);
    final l10n = AppLocalizations.of(context);

    try {
      final updated = await (widget.updateCleanupPreferences?.call(
            CleanupPreferencesUpdateRequestDto(
              reminderFrequency: current.reminderFrequency,
              reminderWeekday: current.reminderFrequency == CleanupReminderFrequency.disabled
                  ? null
                  : current.reminderWeekday,
              reminderTime: current.reminderFrequency == CleanupReminderFrequency.disabled
                  ? null
                  : current.reminderTime,
              trashRetentionDays: current.trashRetentionDays,
            ),
          ) ??
          _cleanupPreferencesService.updateCleanupPreferences(
            CleanupPreferencesUpdateRequestDto(
              reminderFrequency: current.reminderFrequency,
              reminderWeekday: current.reminderFrequency == CleanupReminderFrequency.disabled
                  ? null
                  : current.reminderWeekday,
              reminderTime: current.reminderFrequency == CleanupReminderFrequency.disabled
                  ? null
                  : current.reminderTime,
              trashRetentionDays: current.trashRetentionDays,
            ),
          ));

      if (!mounted) return;
      setState(() {
        _cleanupPreferences = updated;
        _isSavingCleanup = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('cleanup_preferences_saved'))),
      );
      await _loadCleanupData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingCleanup = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _formatNextReminder(AppLocalizations l10n, DateTime? dateTime) {
    if (dateTime == null) return l10n.translate('cleanup_next_reminder_none');
    final local = dateTime.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  String _frequencyLabel(AppLocalizations l10n, CleanupReminderFrequency value) {
    switch (value) {
      case CleanupReminderFrequency.daily:
        return l10n.translate('cleanup_frequency_daily');
      case CleanupReminderFrequency.weekly:
        return l10n.translate('cleanup_frequency_weekly');
      case CleanupReminderFrequency.biweekly:
        return l10n.translate('cleanup_frequency_biweekly');
      case CleanupReminderFrequency.monthly:
        return l10n.translate('cleanup_frequency_monthly');
      case CleanupReminderFrequency.disabled:
        return l10n.translate('cleanup_frequency_disabled');
    }
  }

  String _weekdayLabel(AppLocalizations l10n, int? weekday) {
    switch (weekday) {
      case 1:
        return l10n.translate('weekday_monday');
      case 2:
        return l10n.translate('weekday_tuesday');
      case 3:
        return l10n.translate('weekday_wednesday');
      case 4:
        return l10n.translate('weekday_thursday');
      case 5:
        return l10n.translate('weekday_friday');
      case 6:
        return l10n.translate('weekday_saturday');
      case 7:
        return l10n.translate('weekday_sunday');
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(prefs.locale.languageCode, l10n)),
            onTap: () => _showLanguageDialog(context, prefs, l10n),
          ),
          const Divider(),
          ListTile(
            leading: Icon(prefs.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: Text(l10n.theme),
            subtitle: Text(prefs.isDarkMode ? l10n.darkMode : l10n.lightMode),
            trailing: Switch(
              value: prefs.isDarkMode,
              onChanged: (value) {
                prefs.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.translate('cleanup_section_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isLoadingCleanup)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_cleanupError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_cleanupError!),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadCleanupData,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.refresh),
                  ),
                ],
              ),
            )
          else if (_cleanupPreferences != null) ...[
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(l10n.translate('cleanup_frequency')),
              subtitle: Text(_frequencyLabel(l10n, _cleanupPreferences!.reminderFrequency)),
              trailing: DropdownButton<CleanupReminderFrequency>(
                value: _cleanupPreferences!.reminderFrequency,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _cleanupPreferences = CleanupPreferencesResponseDto(
                      reminderFrequency: value,
                      reminderWeekday: _cleanupPreferences!.reminderWeekday,
                      reminderTime: _cleanupPreferences!.reminderTime,
                      trashRetentionDays: _cleanupPreferences!.trashRetentionDays,
                    );
                  });
                },
                items: CleanupReminderFrequency.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_frequencyLabel(l10n, value)),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (_cleanupPreferences!.reminderFrequency != CleanupReminderFrequency.disabled)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.translate('cleanup_weekday')),
                subtitle: Text(_weekdayLabel(l10n, _cleanupPreferences!.reminderWeekday)),
                trailing: DropdownButton<int>(
                  value: _cleanupPreferences!.reminderWeekday ?? 1,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _cleanupPreferences = CleanupPreferencesResponseDto(
                        reminderFrequency: _cleanupPreferences!.reminderFrequency,
                        reminderWeekday: value,
                        reminderTime: _cleanupPreferences!.reminderTime,
                        trashRetentionDays: _cleanupPreferences!.trashRetentionDays,
                      );
                    });
                  },
                  items: List.generate(
                    7,
                    (index) {
                      final weekday = index + 1;
                      return DropdownMenuItem<int>(
                        value: weekday,
                        child: Text(_weekdayLabel(l10n, weekday)),
                      );
                    },
                  ),
                ),
              ),
            if (_cleanupPreferences!.reminderFrequency != CleanupReminderFrequency.disabled)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l10n.translate('cleanup_time')),
                subtitle: Text(_cleanupPreferences!.reminderTime ?? '09:00'),
                onTap: () async {
                  final current = _cleanupPreferences!.reminderTime ?? '09:00';
                  final parts = current.split(':');
                  final initialTime = TimeOfDay(
                    hour: int.tryParse(parts.first) ?? 9,
                    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                  );

                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: initialTime,
                  );
                  if (selectedTime == null || !mounted) return;

                  final formatted =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                  setState(() {
                    _cleanupPreferences = CleanupPreferencesResponseDto(
                      reminderFrequency: _cleanupPreferences!.reminderFrequency,
                      reminderWeekday: _cleanupPreferences!.reminderWeekday,
                      reminderTime: formatted,
                      trashRetentionDays: _cleanupPreferences!.trashRetentionDays,
                    );
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.auto_delete),
              title: Text(l10n.translate('cleanup_trash_retention')),
              subtitle: Text(
                l10n.translate(
                  'cleanup_trash_retention_days',
                  params: {'days': _cleanupPreferences!.trashRetentionDays.toString()},
                ),
              ),
              trailing: DropdownButton<int>(
                value: _cleanupPreferences!.trashRetentionDays,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _cleanupPreferences = CleanupPreferencesResponseDto(
                      reminderFrequency: _cleanupPreferences!.reminderFrequency,
                      reminderWeekday: _cleanupPreferences!.reminderWeekday,
                      reminderTime: _cleanupPreferences!.reminderTime,
                      trashRetentionDays: value,
                    );
                  });
                },
                items: const [1, 3, 7, 14, 30, 60, 90]
                    .map((days) => DropdownMenuItem<int>(value: days, child: Text('$days')))
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(l10n.translate('cleanup_next_reminder')),
              subtitle: Text(_formatNextReminder(l10n, _summary?.nextReminderAt)),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(l10n.translate('cleanup_expired_pending_count')),
              subtitle: Text((_summary?.expiredPendingCount ?? 0).toString()),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.translate('cleanup_trash_count')),
              subtitle: Text((_summary?.trashedCount ?? 0).toString()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isSavingCleanup ? null : _saveCleanupPreferences,
                icon: _isSavingCleanup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSavingCleanup ? l10n.translate('saving') : l10n.save),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'es':
        return l10n.spanish;
      case 'en':
        return l10n.english;
      case 'ca':
        return l10n.catalan;
      case 'eu':
        return l10n.basque;
      case 'gl':
        return l10n.galician;
      default:
        return code;
    }
  }

  void _showLanguageDialog(BuildContext context, PreferencesService prefs, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, prefs, l10n.spanish, 'es'),
            _languageOption(context, prefs, l10n.english, 'en'),
            _languageOption(context, prefs, l10n.catalan, 'ca'),
            _languageOption(context, prefs, l10n.basque, 'eu'),
            _languageOption(context, prefs, l10n.galician, 'gl'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, PreferencesService prefs, String title, String code) {
    final isSelected = prefs.locale.languageCode == code;

    return ListTile(
      title: Text(title),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      onTap: () {
        prefs.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}
