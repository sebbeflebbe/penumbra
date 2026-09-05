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
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
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
              for (var i = 0; i < penumbraDataCategories().length; i++) ...[
                _Category(
                  category: penumbraDataCategories()[i],
                ).penumbraEnter(context, index: i),
                const SizedBox(height: 24),
              ],
              if (needsPassword) ...[
                FTextField(
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
                ],
              ),
              if (_export != null) ...[
                const SizedBox(height: 24),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () async {
                    await Clipboard.setData(
                      ClipboardData(text: jsonEncode(_export!.toJson())),
                    );
                    if (context.mounted)
                      announce(context, 'Export copied to clipboard');
                  },
                  child: const Text('Copy JSON'),
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
