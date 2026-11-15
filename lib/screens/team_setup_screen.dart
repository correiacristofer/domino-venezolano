import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/theme_toggle_button.dart';
import 'turn_order_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _team1Player1Controller = TextEditingController();
  final _team1Player2Controller = TextEditingController();
  final _team2Player1Controller = TextEditingController();
  final _team2Player2Controller = TextEditingController();
  late final String _randomPhrase;

  @override
  void initState() {
    super.initState();
    // Picked once so the phrase does not change on every rebuild.
    _randomPhrase = context.read<GameProvider>().getRandomPhrase();
    _loadLastTeamNames();
  }

  Future<void> _loadLastTeamNames() async {
    final provider = Provider.of<GameProvider>(context, listen: false);
    final lastNames = await provider.getLastTeamNames();
    if (!mounted) return;
    if (lastNames['team1']!.isNotEmpty) {
      _team1Controller.text = lastNames['team1']!;
    }
    if (lastNames['team2']!.isNotEmpty) {
      _team2Controller.text = lastNames['team2']!;
    }
    if (lastNames['team1Player1']!.isNotEmpty) {
      _team1Player1Controller.text = lastNames['team1Player1']!;
    }
    if (lastNames['team1Player2']!.isNotEmpty) {
      _team1Player2Controller.text = lastNames['team1Player2']!;
    }
    if (lastNames['team2Player1']!.isNotEmpty) {
      _team2Player1Controller.text = lastNames['team2Player1']!;
    }
    if (lastNames['team2Player2']!.isNotEmpty) {
      _team2Player2Controller.text = lastNames['team2Player2']!;
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _team1Player1Controller.dispose();
    _team1Player2Controller.dispose();
    _team2Player1Controller.dispose();
    _team2Player2Controller.dispose();
    super.dispose();
  }

  void _continueToTurnOrder() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TurnOrderScreen(
            team1Name: _team1Controller.text.trim(),
            team2Name: _team2Controller.text.trim(),
            team1Player1: _team1Player1Controller.text.trim(),
            team1Player2: _team1Player2Controller.text.trim(),
            team2Player1: _team2Player1Controller.text.trim(),
            team2Player2: _team2Player2Controller.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ThemeToggleButton(color: colors.onSurfaceVariant),
                ),
                
                // App Title
                Icon(
                  Icons.casino,
                  size: 80,
                  color: colors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'DOMINO VENEZOLANO',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Venezuelan phrase
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant, width: 1),
                  ),
                  child: Text(
                    _randomPhrase,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // TEAM 1
                Text(
                  'EQUIPO 1',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _team1Controller,
                  hint: 'Nombre del equipo 1',
                  validator: (value) => value == null || value.trim().isEmpty 
                      ? 'Ingresa el nombre del equipo 1' 
                      : null,
                ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _team1Player1Controller,
                        hint: 'Jugador 1',
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Nombre requerido' 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _team1Player2Controller,
                        hint: 'Jugador 2',
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Nombre requerido' 
                            : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // TEAM 2
                Text(
                  'EQUIPO 2',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _team2Controller,
                  hint: 'Nombre del equipo 2',
                  validator: (value) => value == null || value.trim().isEmpty 
                      ? 'Ingresa el nombre del equipo 2' 
                      : null,
                ),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _team2Player1Controller,
                        hint: 'Jugador 1',
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Nombre requerido' 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _team2Player2Controller,
                        hint: 'Jugador 2',
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Nombre requerido' 
                            : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),
                
                // Continue Button
                ElevatedButton(
                  onPressed: _continueToTurnOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'CONTINUAR →',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Rules
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.tertiary.withValues(alpha: 0.45), width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: colors.onTertiaryContainer,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El primer equipo que llegue a 100 puntos GANA',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Solo se cuentan las fichas del equipo PERDEDOR 🐷',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colors.onSurface, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
