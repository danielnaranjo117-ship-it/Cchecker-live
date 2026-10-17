import 'package:flutter/material.dart';

import '../repos.dart';
import '../theme.dart';
import '../widgets.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String _err = '';

  Future<void> _go({required bool withPin}) async {
    if (!withPin) {
      Vault.hasPin = false;
      widget.onDone();
      return;
    }
    final a = _pin.text.trim();
    final b = _pin2.text.trim();
    if (a.length < 4) {
      setState(() => _err = 'el pin debe tener al menos 4 digitos');
      return;
    }
    if (a != b) {
      setState(() => _err = 'los pines no coinciden');
      return;
    }
    await Vault.setPin(a);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 30),
              const Text('CCheker Live', style: AppTextStyles.title),
              const SizedBox(height: 6),
              const Text(
                'Boveda cifrada + autorizacion real con Stripe.',
                style: AppTextStyles.caption,
              ),
              const SectionHeader('Protege tu boveda'),
              GlassPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'PIN'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pin2,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'repite el PIN'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'OJO: el PIN cifra la boveda. Si lo pierdes, pierdes los datos.',
                      style: AppTextStyles.tiny,
                    ),
                    if (_err.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_err, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 14),
                    NeonButton(
                      label: 'Crear con PIN',
                      icon: Icons.lock,
                      expand: true,
                      onPressed: () => _go(withPin: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: 'Empezar sin PIN',
                icon: Icons.lock_open,
                color: AppColors.textMid,
                expand: true,
                onPressed: () => _go(withPin: false),
              ),
            ],
          ),
        ),
      );
}
