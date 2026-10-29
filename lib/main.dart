import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'core/app_globals.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/preferences_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/expired_products_screen.dart';
import 'screens/trash_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/upload_pdf_screen.dart';
import 'screens/upload_ticket_screen.dart';
import 'screens/login_webview_screen.dart';
import 'screens/privacy_webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();

  //Añadir  env
  await dotenv.load(fileName: ".env");
  
  // Configurar handler de mensajes en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Cargar preferencias
  final preferencesService = PreferencesService();
  await preferencesService.loadPreferences();
  
  runApp(MyApp(preferencesService: preferencesService));
}

class MyApp extends StatelessWidget {
  final PreferencesService preferencesService;
  
  const MyApp({super.key, required this.preferencesService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: preferencesService,
      child: Consumer<PreferencesService>(
        builder: (context, prefs, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: prefs.themeMode,
            locale: prefs.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
              Locale('ca'),
              Locale('eu'),
              Locale('gl'),
            ],
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginPage(),
              '/home': (context) => const MainNavigationScreen(),
              '/inventory': (context) => const InventoryScreen(),
              '/expired-products': (context) => const ExpiredProductsScreen(),
              '/trash': (context) => const TrashScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/shopping-list': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final openCompare = args is Map && args['openCompareResults'] == true;
                return ShoppingListScreen(openCompareResults: openCompare);
              },
              '/upload-pdf': (context) => const UploadPdfScreen(),
              '/upload-ticket': (context) => const UploadTicketScreen(),
            },
          );
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  late final FCMService _fcmService;
  bool _isLoading = false;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fcmService = FCMService(navigatorKey);
    _listenForSharedFiles();
    _restoreSession();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _listenForSharedFiles() {
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFile(value.first.path);
      }
    });

    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedFile(value.first.path);
        }
      },
    );
  }

  void _handleSharedFile(String filePath) async {
    final token = await _authService.getValidAccessToken();
    if (token == null || !mounted) return;

    if (filePath.toLowerCase().endsWith('.pdf')) {
      Navigator.pushNamed(context, '/upload-pdf', arguments: filePath);
    } else {
      Navigator.pushNamed(context, '/upload-ticket', arguments: filePath);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final token = await _authService.login(context);

    if (token != null && mounted) {
      await _fcmService.initialize();
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('auth_cancelled'))),
        );
      }
    }
  }

  Future<void> _restoreSession() async {
    setState(() => _isLoading = true);

    try {
      final hasSession = await _authService.restoreSessionIfPossible();

      if (!mounted) return;

      if (hasSession) {
        await _fcmService.initialize();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }
    } catch (_) {
      // Si la restauración falla, mostramos la pantalla de login normal.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final registerUrl = '${_authService.keycloakUrl}/realms/${_authService.realmName}/protocol/openid-connect/registrations?client_id=${_authService.clientId}&response_type=code&redirect_uri=${_authService.redirectUrl}';
    
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginWebViewScreen(
            initialUrl: registerUrl,
            onRedirect: (url) async {
              if (url.contains('callback')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('registration_completed'))),
                );
                return null;
              }
              return null;
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/branding/scanticketfresh-icon-ui.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.translate('app_subtitle'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: Text(
                            l10n.login,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _register,
                          child: Text(
                            l10n.translate('no_account_register'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyWebViewScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.privacyPolicy,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
