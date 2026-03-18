import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_constants.dart';

/// App settings screen — Phase 0 stub.
///
/// Phase 0: allows theme switching (dark/light/system).
/// Phase 3: adds performance display preferences (font size, line spacing).
/// Phase 5: adds audio sensitivity and microphone enable/disable.
///
/// TODO(phase-3): Add display settings (font size, line height, scroll speed).
/// TODO(phase-5): Add audio following settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          _ThemeTile(currentMode: themeMode, ref: ref),
          const Divider(indent: 16, endIndent: 16),
          _SectionHeader(title: 'Display'),
          _StubTile(icon: Icons.text_fields_rounded, title: 'Font size', subtitle: '${AppConstants.defaultFontSize.toInt()} pt  •  Phase 3'),
          _StubTile(icon: Icons.format_line_spacing_rounded, title: 'Line spacing', subtitle: 'Normal  •  Phase 3'),
          _StubTile(icon: Icons.speed_outlined, title: 'Auto-scroll speed', subtitle: 'Medium  •  Phase 4'),
          const Divider(indent: 16, endIndent: 16),
          _SectionHeader(title: 'Audio following'),
          _StubTile(icon: Icons.mic_outlined, title: 'Microphone following', subtitle: 'Off  •  Phase 5'),
          _StubTile(icon: Icons.tune_outlined, title: 'Audio sensitivity', subtitle: 'Medium  •  Phase 5'),
          const Divider(indent: 16, endIndent: 16),
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            trailing: Text(AppConstants.appVersion, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final WidgetRef ref;

  const _ThemeTile({required this.currentMode, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_themeIcon(currentMode)),
      title: const Text('Theme'),
      trailing: DropdownButton<ThemeMode>(
        value: currentMode,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
        ],
        onChanged: (mode) {
          if (mode != null) {
            ref.read(themeModeProvider.notifier).state = mode;
          }
        },
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}

class _StubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StubTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      enabled: false,
    );
  }
}
