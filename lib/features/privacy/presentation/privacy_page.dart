import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../core/logging/security_log.dart';
import '../../../l10n/app_localizations.dart';
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
  List<SecurityEvent> _events = const [];
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
    final privacy = ref.read(privacyRepositoryProvider);
    final consents = await privacy.consents();
    final events = await privacy.securityEvents();
    if (!mounted) return;
    consents.when(
      ok: (items) => setState(() {
        _echoGranted = hasGrantedConsent(items, ConsentKind.remoteEcho);
      }),
      err: (_) {},
    );
    events.when(ok: (items) => setState(() => _events = items), err: (_) {});
  }

  Future<void> _exportData() async {
    final result = await ref.read(privacyRepositoryProvider).exportMine();
    result.when(
      ok: (bundle) {
        setState(() {
          _export = bundle;
          _status = AppLocalizations.of(context).exportReady;
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
    announce(context, AppLocalizations.of(context).exportDownloaded);
  }

  Future<void> _saveDisplayName() async {
    final result = await ref
        .read(privacyRepositoryProvider)
        .updateDisplayName(_displayName.text);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _status = AppLocalizations.of(context).displayNameSaved;
          _error = null;
        });
        announce(context, AppLocalizations.of(context).displayNameSaved);
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
        _status = AppLocalizations.of(context).passkeyAdded;
      }
    });
    if (failure == null)
      announce(context, AppLocalizations.of(context).passkeyAdded);
  }

  Future<void> _withdrawEcho() async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) {
        final l10n = AppLocalizations.of(context);
        return FDialog(
          animation: animation,
          title: Text(l10n.withdrawEchoTitle),
          body: Text(l10n.withdrawEchoBody),
          actions: [
            FButton(
              variant: FButtonVariant.destructive,
              onPress: () => Navigator.of(context).pop(true),
              child: Text(l10n.withdrawConsent),
            ),
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(context).pop(false),
              child: Text(l10n.keepConsent),
            ),
          ],
        );
      },
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
          _status = AppLocalizations.of(context).echoConsentWithdrawn;
          _error = null;
        });
        announce(context, AppLocalizations.of(context).echoConsentWithdrawn);
      },
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  Future<void> _erase() async {
    final user = ref.read(authControllerProvider).value;
    final needsPassword = user?.methods.contains(AuthMethod.password) ?? false;
    if (needsPassword && _password.text.length < 12) {
      setState(() => _error = AppLocalizations.of(context).reenterPassword);
      return;
    }
    final result = await ref
        .read(privacyRepositoryProvider)
        .eraseAccount(password: needsPassword ? _password.text : null);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _status = AppLocalizations.of(context).accountErased;
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
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(configProvider);
    final user = ref.watch(authControllerProvider).value;
    final needsPassword = user?.methods.contains(AuthMethod.password) ?? false;
    final hasPasskey = user?.methods.contains(AuthMethod.passkey) ?? false;
    final categories = _localizedCategories(l10n);
    return PenumbraChrome(
      title: l10n.privacyTitle,
      child: PenumbraPage(
        maxWidth: 780,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.yourRights,
                style: theme.typography.xl3.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ).penumbraEnter(context),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 66 * 8),
                child: Text(
                  l10n.controllerLine(
                    config.controllerName,
                    config.controllerEmail,
                  ),
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
                label: Text(l10n.displayName),
                description: Text(l10n.displayNameHint),
                control: FTextFieldControl.managed(controller: _displayName),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: l10n.saveDisplayName,
                child: FButton(
                  onPress: _saveDisplayName,
                  child: Text(l10n.saveDisplayName),
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < categories.length; i++) ...[
                _Category(
                  category: categories[i],
                ).penumbraEnter(context, index: i),
                const SizedBox(height: 24),
              ],
              Text(
                l10n.securityEvents,
                style: theme.typography.lg.copyWith(
                  fontFamily: PenumbraInk.displayFamily,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.securityEventsHint,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              if (_events.isEmpty)
                Text(
                  l10n.noSecurityEvents,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                )
              else
                for (final event in _events.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${event.at.toUtc().toIso8601String()} · ${event.type.name}'
                      '${event.detail == null || event.detail!.isEmpty ? '' : ' · ${event.detail}'}',
                      style: theme.typography.sm.copyWith(height: 1.4),
                    ),
                  ),
              const SizedBox(height: 24),
              if (needsPassword) ...[
                FTextField(
                  key: const Key('erase-password'),
                  label: Text(l10n.passwordToErase),
                  obscureText: true,
                  description: Text(l10n.passwordToEraseHint),
                  control: FTextFieldControl.managed(controller: _password),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  l10n.oauthEraseHint,
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
                  FButton(onPress: _exportData, child: Text(l10n.exportMyData)),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: _erase,
                    child: Text(l10n.eraseMyAccount),
                  ),
                  if (_echoGranted)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _withdrawEcho,
                      child: Text(l10n.withdrawEchoConsent),
                    ),
                  if (!hasPasskey)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _passkeyBusy ? null : _addPasskey,
                      child: Text(l10n.addPasskey),
                    )
                  else
                    Text(
                      l10n.passkeyAlready,
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
                          announce(context, l10n.exportCopied);
                        }
                      },
                      child: Text(l10n.copyJson),
                    ),
                    Semantics(
                      button: true,
                      label: l10n.downloadExportSemantics,
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: _downloadExport,
                        child: Text(l10n.downloadJson),
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

List<DataCategory> _localizedCategories(AppLocalizations l10n) => [
  DataCategory(
    name: l10n.catAccountName,
    purpose: l10n.catAccountPurpose,
    lawfulBasis: l10n.catAccountBasis,
    retention: l10n.catAccountRetention,
  ),
  DataCategory(
    name: l10n.catBoardName,
    purpose: l10n.catBoardPurpose,
    lawfulBasis: l10n.catBoardBasis,
    retention: l10n.catBoardRetention,
  ),
  DataCategory(
    name: l10n.catNodesName,
    purpose: l10n.catNodesPurpose,
    lawfulBasis: l10n.catNodesBasis,
    retention: l10n.catNodesRetention,
  ),
  DataCategory(
    name: l10n.catEventsName,
    purpose: l10n.catEventsPurpose,
    lawfulBasis: l10n.catEventsBasis,
    retention: l10n.catEventsRetention,
  ),
  DataCategory(
    name: l10n.catEchoName,
    purpose: l10n.catEchoPurpose,
    lawfulBasis: l10n.catEchoBasis,
    retention: l10n.catEchoRetention,
  ),
];

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
