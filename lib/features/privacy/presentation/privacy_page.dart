import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/privacy_models.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  String? _status;
  String? _error;
  PrivacyExport? _export;
  var _echoGranted = false;
  var _passkeyBusy = false;
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _displayName.text = user?.displayName ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshConsents());
  }

  @override
  void dispose() {
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _refreshConsents() async {
    final result = await ref.read(privacyRepositoryProvider).consents();
    if (!mounted) return;
    result.when(
      ok: (events) => setState(() {
        _echoGranted = hasGrantedConsent(events, ConsentKind.remoteEcho);
      }),
      err: (_) {},
    );
  }

  Future<void> _exportData() async {
    final result = await ref.read(privacyRepositoryProvider).exportMine();
    result.when(
      ok: (bundle) {
        setState(() {
          _export = bundle;
          _status = 'Export ready. This is your Art. 15 / 20 copy.';
          _error = null;
        });
      },
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _downloadExport() async {
    final bundle = _export;
    if (bundle == null) return;
    await ref.read(exportDownloaderProvider)(
      'penumbra-export.json',
      jsonEncode(bundle.toJson()),
    );
    if (!mounted) return;
    announce(context, 'Export downloaded.');
  }

  Future<void> _saveDisplayName() async {
    final result = await ref
        .read(privacyRepositoryProvider)
        .updateDisplayName(_displayName.text);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _status = 'Display name saved.';
          _error = null;
        });
        announce(context, 'Display name saved.');
      },
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _addPasskey() async {
    setState(() {
      _passkeyBusy = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .registerPasskey();
    if (!mounted) return;
    setState(() {
      _passkeyBusy = false;
      if (failure != null) {
        _error = failure.message;
      } else {
        _status = 'Passkey added.';
      }
    });
    if (failure == null) announce(context, 'Passkey added.');
  }

  Future<void> _withdrawEcho() async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        title: const Text('Withdraw echo consent'),
        body: const Text(
          'Future remote echoes will ask again. Notes already on the board stay. '
          'This does not erase past consent records (Art. 7(3)).',
        ),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('Withdraw consent'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Keep consent'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final result = await ref
        .read(privacyRepositoryProvider)
        .recordConsent(ConsentKind.remoteEcho, granted: false);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _echoGranted = false;
          _status = 'Echo consent withdrawn.';
          _error = null;
        });
        announce(context, 'Echo consent withdrawn.');
      },
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _erase() async {
    final user = ref.read(authControllerProvider).value;
    final needsPassword = user?.methods.contains(AuthMethod.password) ?? false;
    if (needsPassword && _password.text.length < 12) {
      setState(() => _error = 'Re-enter your password to erase this account.');
      return;
    }
    final result = await ref
        .read(privacyRepositoryProvider)
        .eraseAccount(password: needsPassword ? _password.text : null);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _status = 'Account erased.';
          _error = null;
        });
        context.go('/');
      },
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final config = ref.watch(configProvider);
    final user = ref.watch(authControllerProvider).value;
    final needsPassword = user?.methods.contains(AuthMethod.password) ?? false;
    final hasPasskey = user?.methods.contains(AuthMethod.passkey) ?? false;
    return PenumbraChrome(
      title: 'Privacy',
      child: PenumbraPage(
        maxWidth: 780,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your rights',
                style: theme.typography.xl3.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ).penumbraEnter(context),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 66 * 8),
                child: Text(
                  'Controller: ${config.controllerName}. Contact: ${config.controllerEmail}. '
                  'Age: 16+. Necessary storage only — no marketing cookies.',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ).penumbraEnter(context, delayMs: 40),
              const SizedBox(height: 28),
              if (_error != null)
                FAlert(
                  variant: FAlertVariant.destructive,
                  title: Text(_error!),
                ),
              if (_status != null) FAlert(title: Text(_status!)),
              const SizedBox(height: 8),
              FTextField(
                label: const Text('Display name'),
                description: const Text('Art. 16 rectification. Optional.'),
                control: FTextFieldControl.managed(controller: _displayName),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Save display name',
                child: FButton(
                  onPress: _saveDisplayName,
                  child: const Text('Save display name'),
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < penumbraDataCategories().length; i++) ...[
                _Category(
                  category: penumbraDataCategories()[i],
                ).penumbraEnter(context, index: i),
                const SizedBox(height: 24),
              ],
              if (needsPassword) ...[
                FTextField(
                  key: const Key('erase-password'),
                  label: const Text('Password to erase'),
                  obscureText: true,
                  description: const Text(
                    'Art. 17 erasure requires a recent password confirmation.',
                  ),
                  control: FTextFieldControl.managed(controller: _password),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  'OAuth and passkey accounts can erase only with a sign-in from the last five minutes. '
                  'Sign in again first if that window has closed.',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    onPress: _exportData,
                    child: const Text('Export my data'),
                  ),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: _erase,
                    child: const Text('Erase my account'),
                  ),
                  if (_echoGranted)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _withdrawEcho,
                      child: const Text('Withdraw echo consent'),
                    ),
                  if (!hasPasskey)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _passkeyBusy ? null : _addPasskey,
                      child: const Text('Add a passkey'),
                    )
                  else
                    Text(
                      'A passkey is already on this account.',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
              if (_export != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: () async {
                        await Clipboard.setData(
                          ClipboardData(text: jsonEncode(_export!.toJson())),
                        );
                        if (context.mounted) {
                          announce(context, 'Export copied to clipboard');
                        }
                      },
                      child: const Text('Copy JSON'),
                    ),
                    Semantics(
                      button: true,
                      label: 'Download export as JSON',
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: _downloadExport,
                        child: const Text('Download JSON'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_export!.toJson()),
                  style: theme.typography.sm.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({required this.category});

  final DataCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 66 * 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: theme.typography.lg.copyWith(
              fontFamily: PenumbraInk.displayFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.purpose,
            style: theme.typography.md.copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${category.lawfulBasis} · ${category.retention}',
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
