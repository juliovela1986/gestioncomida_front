import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_localizations.dart';
import '../config/privacy_policy.dart';

class PrivacyWebViewScreen extends StatefulWidget {
  final String? url;

  const PrivacyWebViewScreen({super.key, this.url});

  @override
  State<PrivacyWebViewScreen> createState() => _PrivacyWebViewScreenState();
}

class _PrivacyWebViewScreenState extends State<PrivacyWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final target = widget.url ?? PrivacyPolicy.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(target));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
