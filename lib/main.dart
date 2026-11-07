import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/team_setup_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const DominoVenezolanoApp());
}

/// App theme, also used to render store screenshots.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFB300),
    brightness: brightness,
    surface: isDark ? const Color(0xFF111111) : const Color(0xFFFFFBF3),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Roboto',
    appBarTheme: AppBarThemeData(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      // Dialog styles replace the ambient text style, so they need the
      // family too or dialogs fall back to a different font.
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: scheme.onSurfaceVariant,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
  );
}

class DominoVenezolanoApp extends StatelessWidget {
  const DominoVenezolanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameProvider()..tryRestoreGame(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..load(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp(
            title: 'Domino Venezolano',
            debugShowCheckedModeBanner: false,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            themeMode: themeProv.mode,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

/// Decides between resuming a saved game or starting fresh on app launch.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, ThemeProvider>(
      builder: (context, provider, theme, _) {
        if (provider.isRestoring || theme.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.hasGame) {
          return const GameScreen();
        }
        return const TeamSetupScreen();
      },
    );
  }
}
