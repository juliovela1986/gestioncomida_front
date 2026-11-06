import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/support_config.dart';

/// Canal de reporte humano (SCRUM-164): mailto con versión de app.
class FeedbackService {
  Future<bool> wasBetaNoticeDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SupportConfig.betaNoticePrefsKey) ?? false;
  }

  Future<void> dismissBetaNotice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SupportConfig.betaNoticePrefsKey, true);
  }

  Future<PackageInfo> packageInfo() => PackageInfo.fromPlatform();

  Future<Uri> buildReportMailtoUri({String? userNote}) async {
    final info = await packageInfo();
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;
    final subject = Uri.encodeComponent(
      'ScanTicketFresh feedback — ${info.version}+${info.buildNumber}',
    );
    final body = Uri.encodeComponent(
      [
        userNote ?? '',
        '',
        '---',
        'App: ${info.appName}',
        'Version: ${info.version} (${info.buildNumber})',
        'Package: ${info.packageName}',
        'Platform: $platform',
        '',
        'Describe el problema (pantalla, qué hiciste, qué esperabas):',
        '',
      ].join('\n'),
    );
    return Uri.parse(
      'mailto:${SupportConfig.supportEmail}?subject=$subject&body=$body',
    );
  }

  /// Abre el cliente de correo. Devuelve false si no hay app de email.
  Future<bool> openReportProblem({String? userNote}) async {
    final uri = await buildReportMailtoUri(userNote: userNote);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
