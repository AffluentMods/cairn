// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/net/dio_client.dart';
import '../../core/settings/settings.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/cairn_theme.dart';
import '../../core/units/unit_formatter.dart';
import '../../data/data_providers.dart';
import '../../domain/usecases/recording_engine.dart' show RecordingProfile;
import '../navigate/navigate_providers.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'diagnostics_screen.dart';

/// Settings (spec Phase 9): units, theme, default map, weights, terrain cache,
/// sync, data sources, privacy, licenses, version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final metric = s.units == UnitSystem.metric;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _header(context, l10n.settingsUnits),
          RadioListTileless(
            selected: !metric,
            title: l10n.unitsImperial,
            onTap: () => notifier.setUnits(UnitSystem.imperial),
          ),
          RadioListTileless(
            selected: metric,
            title: l10n.unitsMetric,
            onTap: () => notifier.setUnits(UnitSystem.metric),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsAppearance),
            subtitle: Text(_appearanceSummary(context, s)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AppearanceScreen()),
            ),
          ),
          const Divider(),
          _header(context, l10n.settingsDefaultStyle),
          for (final style in CairnMapStyle.values)
            RadioListTileless(
              selected: s.mapStyle == style,
              title: switch (style) {
                CairnMapStyle.outdoors => l10n.styleOutdoors,
                CairnMapStyle.topo => l10n.styleTopo,
                CairnMapStyle.satellite => l10n.styleSatellite,
              },
              onTap: () => notifier.setMapStyle(style),
            ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsBodyWeight),
            subtitle: Text(
              s.bodyWeightKg == null
                  ? '--'
                  : UnitFormatter(s.units).weight(s.bodyWeightKg!),
            ),
            onTap: () => _editWeight(
              context,
              metric,
              s.bodyWeightKg,
              (kg) => notifier.setBodyWeightKg(kg),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsPackWeight),
            subtitle: Text(
              s.defaultPackKg == null
                  ? '--'
                  : UnitFormatter(s.units).weight(s.defaultPackKg!),
            ),
            onTap: () => _editWeight(
              context,
              metric,
              s.defaultPackKg,
              (kg) => notifier.setDefaultPackKg(kg),
            ),
          ),
          const Divider(),
          _header(context, l10n.settingsRecording),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l10n.settingsRecordingProfile,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final p in RecordingProfile.values)
            RadioListTileless(
              selected: s.recordingProfile == p,
              title: switch (p) {
                RecordingProfile.precise => l10n.profilePrecise,
                RecordingProfile.balanced => l10n.profileBalanced,
                RecordingProfile.saver => l10n.profileSaver,
              },
              subtitle: switch (p) {
                RecordingProfile.precise => l10n.profilePreciseSub,
                RecordingProfile.balanced => l10n.profileBalancedSub,
                RecordingProfile.saver => l10n.profileSaverSub,
              },
              onTap: () => notifier.setRecordingProfile(p),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.pause_circle_outline),
            title: Text(l10n.settingsAutoPause),
            subtitle: Text(l10n.settingsAutoPauseSub),
            value: s.autoPause,
            onChanged: notifier.setAutoPause,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.battery_saver_outlined),
            title: Text(l10n.settingsAutoSaver),
            subtitle: Text(l10n.settingsAutoSaverSub),
            value: s.autoSaver,
            onChanged: notifier.setAutoSaver,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_high_outlined),
            title: Text(l10n.settingsKeepScreenOn),
            value: s.keepScreenOn,
            onChanged: notifier.setKeepScreenOn,
          ),
          if (Platform.isAndroid) const _BatteryOptimizationTile(),
          const Divider(),
          const _TerrainCacheTile(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.settingsSync),
            subtitle: Text(l10n.settingsSyncOff),
            onTap: () => context.push('/saved/sync'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.settingsProxyUrl),
            subtitle: Text(
              s.proxyBaseUrl.isEmpty
                  ? l10n.settingsProxyExplainer
                  : s.proxyBaseUrl,
            ),
            onTap: () => _editProxy(context, ref, s.proxyBaseUrl),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsSources),
            leading: const Icon(Icons.map_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const AboutSourcesScreen()),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsPrivacy),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDiagnostics),
            subtitle: Text(l10n.diagnosticsSubtitle),
            leading: const Icon(Icons.bug_report_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const DiagnosticsScreen()),
            ),
          ),
          if (kDebugMode) ...[
            const Divider(),
            _header(context, l10n.settingsDeveloper),
            SwitchListTile(
              secondary: const Icon(Icons.route_outlined),
              title: Text(l10n.settingsSimulateLocation),
              subtitle: Text(l10n.settingsSimulateLocationSub),
              value: ref.watch(simulateLocationProvider),
              onChanged: (v) =>
                  ref.read(simulateLocationProvider.notifier).state = v,
            ),
          ],
          ListTile(
            title: Text(l10n.settingsLicenses),
            leading: const Icon(Icons.article_outlined),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: kCairnVersion,
            ),
          ),
          ListTile(
            title: Text(l10n.settingsVersion(kCairnVersion)),
            leading: const Icon(Icons.info_outline),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _appearanceSummary(BuildContext context, Settings s) {
    final l10n = context.l10n;
    String nameOf(String id) =>
        (builtInThemeById(id) ?? cairnBuiltInThemes.first).name;
    return switch (s.themeMode) {
      ThemeMode.system =>
        '${l10n.themeSystem} · ${nameOf(s.darkThemeId)} / ${nameOf(s.lightThemeId)}',
      ThemeMode.dark => '${l10n.themeDark} · ${nameOf(s.darkThemeId)}',
      ThemeMode.light => '${l10n.themeLight} · ${nameOf(s.lightThemeId)}',
    };
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );

  Future<void> _editWeight(
    BuildContext context,
    bool metric,
    double? currentKg,
    void Function(double?) onSet,
  ) async {
    final controller = TextEditingController(
      text: currentKg == null
          ? ''
          : (metric ? currentKg : currentKg / 0.45359237).toStringAsFixed(0),
    );
    final l10n = context.l10n;
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: metric ? 'kg' : 'lb'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1.0),
            child: Text(l10n.genericDelete),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v == null) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, metric ? v : v * 0.45359237);
            },
            child: Text(l10n.genericSave),
          ),
        ],
      ),
    );
    if (result == null) return;
    onSet(result < 0 ? null : result);
  }

  Future<void> _editProxy(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.genericSave),
          ),
        ],
      ),
    );
    if (url == null) return;
    final ok = await ref.read(settingsProvider.notifier).setProxyBaseUrl(url);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsProxyInvalid)),
      );
    }
  }
}

/// A checkable row without the deprecated RadioListTile group API.
class RadioListTileless extends StatelessWidget {
  const RadioListTileless({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

/// Whether Android lets Cairn run unrestricted in the background; a tap opens
/// the system page. Re-checked when the app comes back to the foreground.
class _BatteryOptimizationTile extends StatefulWidget {
  const _BatteryOptimizationTile();

  @override
  State<_BatteryOptimizationTile> createState() =>
      _BatteryOptimizationTileState();
}

class _BatteryOptimizationTileState extends State<_BatteryOptimizationTile> {
  bool? _unrestricted;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    bool? value;
    try {
      value = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } on Exception {
      value = null;
    }
    if (mounted) setState(() => _unrestricted = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ok = _unrestricted;
    return ListTile(
      leading: Icon(
        ok == false ? Icons.battery_alert_outlined : Icons.battery_full,
        color: ok == false ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(l10n.settingsBatteryOptimization),
      subtitle: Text(
        ok == null
            ? '...'
            : ok
                ? l10n.settingsBatteryUnrestricted
                : l10n.settingsBatteryRestricted,
      ),
      onTap: () async {
        try {
          await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
        } on Exception {
          // not available
        }
      },
    );
  }
}

class _TerrainCacheTile extends ConsumerStatefulWidget {
  const _TerrainCacheTile();

  @override
  ConsumerState<_TerrainCacheTile> createState() => _TerrainCacheTileState();
}

class _TerrainCacheTileState extends ConsumerState<_TerrainCacheTile> {
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    final dir = Directory(
      '${ref.read(appSupportDirProvider).path}/terrain',
    );
    var total = 0;
    if (dir.existsSync()) {
      await for (final e in dir.list(recursive: true)) {
        if (e is File) total += await e.length();
      }
    }
    if (mounted) setState(() => _bytes = total);
  }

  Future<void> _clear() async {
    final dir = Directory('${ref.read(appSupportDirProvider).path}/terrain');
    if (dir.existsSync()) await dir.delete(recursive: true);
    await _measure();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mb =
        _bytes == null ? '...' : '${(_bytes! / (1024 * 1024)).round()} MB';
    return ListTile(
      leading: const Icon(Icons.terrain_outlined),
      title: Text(l10n.settingsTerrainCache),
      subtitle: Text(mb),
      trailing: TextButton(
        onPressed: _clear,
        child: Text(l10n.settingsClearCache),
      ),
    );
  }
}
