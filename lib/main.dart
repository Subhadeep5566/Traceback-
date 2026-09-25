import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'design/tb_theme.dart';
import 'firebase_options.dart';
import 'providers/asset_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Apply dark system UI immediately
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Tb.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice (safe in tests/offline): $e');
  }

  final storageService = StorageService();
  await storageService.init();

  // Initialize Traceback Node.js + MySQL REST API client
  await ApiService().init();

  runApp(TracebackApp(storageService: storageService));
}

class TracebackApp extends StatefulWidget {
  final StorageService storageService;

  const TracebackApp({super.key, required this.storageService});

  @override
  State<TracebackApp> createState() => _TracebackAppState();
}

class _TracebackAppState extends State<TracebackApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(widget.storageService);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetProvider(widget.storageService)),
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        Provider<StorageService>.value(value: widget.storageService),
      ],
      child: MaterialApp(
        title: 'TRACEBACK',
        debugShowCheckedModeBanner: false,
        theme: Tb.theme,
        initialRoute: _authService.isLoggedIn ? '/home' : '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigationShell(),
        },
      ),
    );
  }
}