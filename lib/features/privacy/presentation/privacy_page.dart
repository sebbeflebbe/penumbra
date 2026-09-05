import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
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
    final result = await ref.read(privacyRepositoryProvider).eraseAccount();
    result.when(
      ok: (_) => setState(() => _status = 'Account erased.'),
      err: (failure) => setState(() => _error = failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final config = ref.watch(configProvider);
    return PenumbraChrome(
      title: 'Privacy',
      child: PenumbraPage(
        maxWidth: 780,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your rights', style: theme.typography.xl3.copyWith(fontWeight: FontWeight.w500)).penumbraEnter(context),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 66 * 8),
                child: Text(
                  'Controller: ${config.controllerName}. Contact: ${config.controllerEmail}. '
                  'Age: 16+. Necessary storage only — no marketing cookies.',
                  style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.5),
                ),
              ).penumbraEnter(context, delayMs: 40),
              const SizedBox(height: 28),
              if (_error != null) FAlert(variant: FAlertVariant.destructive, title: Text(_error!)),
              if (_status != null) FAlert(title: Text(_status!)),
              const SizedBox(height: 8),
              for (var i = 0; i < penumbraDataCategories().length; i++) ...[
                _Category(category: penumbraDataCategories()[i]).penumbraEnter(context, index: i),
                const SizedBox(height: 24),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(onPress: _exportData, child: const Text('Export my data')),
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
                    await Clipboard.setData(ClipboardData(text: jsonEncode(_export!.toJson())));
                    if (context.mounted) announce(context, 'Export copied to clipboard');
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
            style: theme.typography.lg.copyWith(fontFamily: PenumbraInk.displayFamily, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(category.purpose, style: theme.typography.md.copyWith(height: 1.5)),
          const SizedBox(height: 4),
          Text(
            '${category.lawfulBasis} · ${category.retention}',
            style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
