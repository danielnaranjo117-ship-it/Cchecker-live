import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../repos.dart';
import '../theme.dart';
import '../widgets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  String _err = '';

  Future<void> _try() async {
    final p = _pin.text.trim();
    if (Vault.checkPin(p)) {
      Vault.unlock(p);
      widget.onUnlock();
      return;
    }
    setState(() => _err = 'pin incorrecto');
  }

  Future<void> _bio() async {
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Desbloquea CCheker Live',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (!ok) return;
      final saved = Vault.get('pin_plain');
      if (saved.isNotEmpty) {
        Vault.unlock(saved);
        widget.onUnlock();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 40),
              const Text('Boveda bloqueada', style: AppTextStyles.title),
              const SizedBox(height: 20),
              GlassPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _try(),
                      decoration: const InputDecoration(labelText: 'PIN'),
                    ),
                    if (_err.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_err, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 14),
                    NeonButton(label: 'Desbloquear', icon: Icons.lock_open, expand: true, onPressed: _try),
                    const SizedBox(height: 10),
                    NeonButton(
                      label: 'Huella / cara',
                      icon: Icons.fingerprint,
                      color: AppColors.cyan,
                      expand: true,
                      onPressed: _bio,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
