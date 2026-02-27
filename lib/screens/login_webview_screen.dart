import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final Future<String?> Function(String) onRedirect;

  const LoginWebViewScreen({
    Key? key,
    required this.initialUrl,
    required this.onRedirect,
  }) : super(key: key);

  @override
  State<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends State<LoginWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('[WebView] 🔵 Iniciando WebView');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('[WebView] 🌐 Cargando página: $url');
          },
          onPageFinished: (String url) {
            print('[WebView] ✅ Página cargada: $url');
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) async {
            print('[WebView] 🔀 Navegación solicitada: ${request.url}');
            if (request.url.startsWith('com.gestioncomida.app://callback')) {
              print('[WebView] 🎯 Callback detectado, procesando...');
              final result = await widget.onRedirect(request.url);
              if (mounted) {
                Navigator.of(context).pop(result);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('[WebView] ❌ Error: ${error.description}');
          },
        ),
      );

    _initWebView();
  }

  Future<void> _initWebView() async {
    print('[WebView] 🧹 Limpiando cookies y caché...');
    await WebViewCookieManager().clearCookies();
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    print('[WebView] ✅ Limpieza completada');
    print('[WebView] 🚀 Cargando URL: ${widget.initialUrl}');
    await _controller.loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
            // Si el usuario presiona "atrás", nos aseguramos de que se devuelva un nulo
            if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(null);
            }
            return true;
        },
        child: Scaffold(
            appBar: AppBar(
                title: const Text('Iniciar Sesión'),
            ),
            body: Stack(
                children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                    const Center(
                    child: CircularProgressIndicator(),
                    ),
                ],
            ),
        ),
    );
  }
}
