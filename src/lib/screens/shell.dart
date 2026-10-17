import 'package:flutter/material.dart';

import '../run_bar.dart';
import '../theme.dart';
import 'analysis.dart';
import 'import.dart';
import 'proxies.dart';
import 'scrape.dart';
import 'settings.dart';
import 'vault.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  static const _tabs = <(String, IconData)>[
    ('Boveda', Icons.credit_card),
    ('Importar', Icons.download),
    ('Fuentes', Icons.public),
    ('Analisis', Icons.insights),
    ('Proxies', Icons.lan),
    ('Ajustes', Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const VaultScreen(),
      const ImportScreen(),
      const ScrapeScreen(),
      const AnalysisScreen(),
      const ProxiesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tab == 0) const RunBar(),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.panel,
              border: Border(top: BorderSide(color: AppColors.stroke)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Icon(
                              _tabs[i].$2,
                              size: 20,
                              color: _tab == i ? AppColors.lime : AppColors.textMid,
                            ),
                            const SizedBox(height: 3),
                            Text(_tabs[i].$1, style: AppTextStyles.tiny),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
