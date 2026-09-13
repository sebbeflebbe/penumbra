import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/providers.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';

class LockedStudio extends ConsumerStatefulWidget {
  const LockedStudio({this.onUnlocked, super.key});

  final VoidCallback? onUnlocked;

  @override
  ConsumerState<LockedStudio> createState() => _LockedStudioState();
}

class _LockedStudioState extends ConsumerState<LockedStudio> {
  final _phrase = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .unlockPhrase(_phrase.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure?.message;
    });
    if (failure == null) {
      announce(context, 'Notes unlocked.');
      widget.onUnlocked?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return PenumbraPage(
      maxWidth: 480,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock this studio',
              style: theme.typography.xl3.copyWith(fontWeight: FontWeight.w500),
            ).penumbraEnter(context),
            const SizedBox(height: 10),
            Text(
              'This device does not have the wrapping key. Enter the twelve-word recovery phrase shown when you first signed in.',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
                height: 1.5,
              ),
            ).penumbraEnter(context, delayMs: 40),
            const SizedBox(height: 24),
            if (_error != null) ...[
              FAlert(variant: FAlertVariant.destructive, title: Text(_error!)),
              const SizedBox(height: 16),
            ],
            FTextField(
              label: const Text('Recovery phrase'),
              description: const Text('Twelve words, in order.'),
              minLines: 2,
              maxLines: 3,
              control: FTextFieldControl.managed(controller: _phrase),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Unlock with recovery phrase',
              child: FButton(
                onPress: _busy ? null : _unlock,
                child: const Text('Unlock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
