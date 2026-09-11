// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../data/data_providers.dart';
import '../../data/sync/sync_service.dart';
import '../../l10n/app_localizations.dart';

/// Multi-device sync setup (spec: the user's Zest-sync request). End to end
/// encrypted, off by default. Set up on one device, join on others with the
/// sync code and passphrase.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _server = TextEditingController();
  final _passphrase = TextEditingController();
  final _code = TextEditingController();
  SyncState? _state;
  bool _loading = true;
  bool _busy = false;

  /// The passphrase is the only thing protecting E2E data if the sync code
  /// leaks (the server holds the salt and wrapped key), so require some length.
  static const _minPassphrase = 10;
  bool get _passphraseOk => _passphrase.text.length >= _minPassphrase;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final state = await ref.read(syncServiceProvider).loadState();
    if (mounted) {
      setState(() {
        _state = state;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _server.dispose();
    _passphrase.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      await action();
      await _reload();
    } on SyncWrongPassphrase {
      _snack(l10n.syncWrongPassphrase);
    } on SyncNoData {
      _snack(l10n.syncNoData);
    } catch (_) {
      _snack(l10n.syncStatusError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children:
                  _state == null ? _setupViews(l10n) : _enabledViews(l10n),
            ),
    );
  }

  List<Widget> _setupViews(AppLocalizations l10n) {
    return [
      Text(l10n.syncIntro, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 20),
      TextField(
        controller: _server,
        decoration: InputDecoration(
          labelText: l10n.syncServerUrl,
          hintText: 'https://sync.example.com',
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _passphrase,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: l10n.syncPassphrase,
          helperText: l10n.syncPassphraseHint,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _busy || !_passphraseOk ? null : () => _run(_enable),
        child: Text(l10n.syncEnable),
      ),
      if (_passphrase.text.isNotEmpty && !_passphraseOk)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.syncPassphraseTooShort,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const Divider(height: 40),
      Text(l10n.syncJoin, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      TextField(
        controller: _code,
        decoration: InputDecoration(
          labelText: l10n.syncRecoveryCode,
          helperText: l10n.syncRecoveryCodeHint,
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy || !_passphraseOk ? null : () => _run(_join),
        child: Text(l10n.syncJoin),
      ),
      if (_busy) ...[
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
    ];
  }

  List<Widget> _enabledViews(AppLocalizations l10n) {
    final s = _state!;
    final last = s.lastSyncedAtMs == null
        ? l10n.syncStatusIdle
        : l10n.syncLastSynced(_ago(s.lastSyncedAtMs!));
    return [
      Row(
        children: [
          const Icon(Icons.check_circle, size: 18),
          const SizedBox(width: 8),
          Text(l10n.syncEnabled,
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      const SizedBox(height: 12),
      Text(l10n.syncRecoveryCode,
          style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(child: SelectableText(s.syncId)),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: s.syncId));
              _snack(l10n.syncCodeCopied);
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(last, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() => ref.read(syncServiceProvider).syncNow()),
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync),
        label: Text(l10n.syncNow),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _busy
            ? null
            : () => _run(() => ref.read(syncServiceProvider).disconnect()),
        child: Text(l10n.syncDisconnect),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => _confirmPurge(l10n),
        child: Text(
          l10n.syncPurge,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ];
  }

  Future<void> _enable() => ref.read(syncServiceProvider).enable(
        baseUrl: _server.text.trim(),
        passphrase: _passphrase.text,
      );

  Future<void> _join() => ref.read(syncServiceProvider).join(
        baseUrl: _server.text.trim(),
        syncId: _code.text.trim(),
        passphrase: _passphrase.text,
      );

  Future<void> _confirmPurge(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.syncPurge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.genericCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.genericDelete),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => ref.read(syncServiceProvider).purge());
  }

  String _ago(int ms) {
    final d =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} d';
  }
}
