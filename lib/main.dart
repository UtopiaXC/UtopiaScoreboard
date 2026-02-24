import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utopia Scoreboard',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansScTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        fontFamily: GoogleFonts.notoSansSc().fontFamily,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2D3748),
          contentTextStyle: GoogleFonts.notoSansSc(
            color: Colors.white,
            fontSize: 14,
          ),
          actionTextColor: const Color(0xFF667EEA),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansScTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        fontFamily: GoogleFonts.notoSansSc().fontFamily,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2D3748),
          contentTextStyle: GoogleFonts.notoSansSc(
            color: Colors.white,
            fontSize: 14,
          ),
          actionTextColor: const Color(0xFF667EEA),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
