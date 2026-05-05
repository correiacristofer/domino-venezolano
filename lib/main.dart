import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/team_setup_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const DominoDuelApp());
}

class DominoDuelApp extends StatelessWidget {
  const DominoDuelApp({super.key});

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
            title: 'Domino Duel',
            debugShowCheckedModeBanner: false,
            themeMode: themeProv.mode,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.amber,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.grey,
              scaffoldBackgroundColor: Colors.black,
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                displayMedium: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
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
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        if (provider.hasGame) {
          return const GameScreen();
        }
        return const TeamSetupScreen();
      },
    );
  }
}
