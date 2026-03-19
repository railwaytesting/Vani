// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'l10n/AppLocalizations.dart';
import 'models/EmergencyContact.dart';
import 'services/EmergencyService.dart';
import 'screens/HomeScreen.dart';
import 'components/SOSFloatingButton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive: local storage for emergency contacts ──
  await Hive.initFlutter();
  Hive.registerAdapter(EmergencyContactAdapter());
  await Hive.openBox<EmergencyContact>('emergency_contacts');

  runApp(const VaniApp());
}

class VaniApp extends StatefulWidget {
  const VaniApp({super.key});

  @override
  State<VaniApp> createState() => _VaniAppState();
}

class _VaniAppState extends State<VaniApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    const accentIndigo = Color(0xFF6C63FF);
    const deepBg = Color(0xFF06060F);
    const surfaceCard = Color(0xFF0D0D1F);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).t('app_title'),
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Light theme (unchanged) ──
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: accentIndigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6FD),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: accentIndigo,
          secondary: Color(0xFF4F46E5),
          surface: Colors.white,
          onSurface: Color(0xFF0F0E2A),
        ),
        useMaterial3: true,
      ),

      // ── Dark theme (unchanged) ──
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: accentIndigo,
        scaffoldBackgroundColor: deepBg,
        cardColor: surfaceCard,
        canvasColor: deepBg,
        dividerColor: Colors.white.withOpacity(0.04),
        colorScheme: const ColorScheme.dark(
          primary: accentIndigo,
          secondary: Color(0xFF9D8FFF),
          surface: surfaceCard,
          onSurface: Color(0xFFEAE8FF),
        ),
        useMaterial3: true,
      ),

      // ── Root is now _RootShell (wraps HomeScreen + SOS FAB) ──
      home: _RootShell(toggleTheme: toggleTheme, setLocale: setLocale),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RootShell
// Wraps HomeScreen with the persistent SOS floating button and initialises
// EmergencyService (shake detection + context) after the first frame.
// ─────────────────────────────────────────────────────────────────────────────

class _RootShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(Locale) setLocale;

  const _RootShell({
    required this.toggleTheme,
    required this.setLocale,
  });

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  @override
  void initState() {
    super.initState();
    // Init after first frame so context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EmergencyService.instance.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HomeScreen provides its own Scaffold — this outer one
      // exists only to host the persistent SOS FAB across all routes.
      backgroundColor: Colors.transparent,
      body: HomeScreen(
        toggleTheme: widget.toggleTheme,
        setLocale: widget.setLocale,
      ),
      floatingActionButton: SOSFloatingButton(
        toggleTheme: widget.toggleTheme,
        setLocale: widget.setLocale,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}