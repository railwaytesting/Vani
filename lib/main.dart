import 'package:flutter/material.dart';
import 'screens/HomeScreen.dart';

void main() => runApp(const VaniApp());

class VaniApp extends StatefulWidget {
  const VaniApp({super.key});

  @override
  State<VaniApp> createState() => _VaniAppState();
}

class _VaniAppState extends State<VaniApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() => _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vani ISL',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // LIGHT THEME (Cloud Pearl)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5), secondary: Color(0xFF0EA5E9)),
      ),
      // DARK THEME (Midnight Slate)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1), secondary: Color(0xFF10B981)),
      ),
      home: HomeScreen(toggleTheme: toggleTheme),
    );
  }
}