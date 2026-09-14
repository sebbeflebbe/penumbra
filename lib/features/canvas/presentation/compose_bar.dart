import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

class ComposeBar extends StatelessWidget {
  const ComposeBar({
    required this.controller,
    required this.onPlace,
    required this.onSwatch,
    required this.onSummon,
    required this.summoning,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onPlace;
  final VoidCallback onSwatch;
  final VoidCallback? onSummon;
  final bool summoning;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
              color: theme.colors.foreground.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tight = constraints.maxWidth < 620;
              final field = FTextField(
                hint: l10n.composeHint,
                enabled: enabled,
                control: FTextFieldControl.managed(controller: controller),
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    onPress: enabled ? onPlace : null,
                    child: Text(l10n.place),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: enabled ? onSwatch : null,
                    child: Text(l10n.swatch),
                  ),
                  if (onSummon != null || summoning)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: summoning || !enabled ? null : onSummon,
                      prefix: summoning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: FCircularProgress(),
                            )
                          : null,
                      child: Text(l10n.summonEcho),
                    ),
                ],
              );
              if (tight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 8), actions],
                );
              }
              return Row(
                children: [
                  Text(
                    l10n.compose,
                    style: theme.typography.xs.copyWith(
                      fontFamily: PenumbraInk.displayFamily,
                      color: theme.colors.mutedForeground,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 28,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: theme.colors.border,
                      ),
                    ),
                  ),
                  Expanded(child: field),
                  const SizedBox(width: 8),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
