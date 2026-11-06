import 'package:flutter/material.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'price_insights_screen.dart';
import 'privacy_webview_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/feedback_service.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.more),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.translate('beta_banner_short'),
                      style: TextStyle(color: Colors.amber.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.bug_report_outlined,
            title: l10n.translate('report_problem'),
            subtitle: l10n.translate('report_problem_subtitle'),
            color: Colors.deepOrange,
            onTap: () async {
              final opened = await FeedbackService().openReportProblem();
              if (!context.mounted) return;
              if (!opened) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('report_problem_no_mail_app'))),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.bar_chart,
            title: l10n.statistics,
            subtitle: l10n.statsSubtitle,
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.trending_up,
            title: l10n.priceInsightsMenuTitle,
            subtitle: l10n.priceInsightsMenuSubtitle,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PriceInsightsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.settings,
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicySubtitle,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyWebViewScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
