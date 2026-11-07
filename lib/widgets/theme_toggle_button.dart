import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Switches between light and dark based on what is on screen right now,
/// which also covers the initial "follow the system" mode.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;

  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Usar tema claro' : 'Usar tema oscuro',
      onPressed: () => context.read<ThemeProvider>().setDark(!isDark),
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: color,
      ),
    );
  }
}
