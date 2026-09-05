import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import 'legal_catalog.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final doc = LegalCatalog.documents.firstWhere(
      (d) => d.slug == slug,
      orElse: () => LegalCatalog.privacy,
    );
    return PenumbraChrome(
      title: doc.title,
      child: PenumbraPage(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final nav = SizedBox(
                width: stacked ? double.infinity : 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in LegalCatalog.documents)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.go('/legal/${item.slug}'),
                          child: Semantics(
                            button: true,
                            selected: item.slug == doc.slug,
                            child: Text(
                              item.title,
                              style: theme.typography.sm.copyWith(
                                color: item.slug == doc.slug
                                    ? theme.colors.foreground
                                    : theme.colors.mutedForeground,
                                fontWeight: item.slug == doc.slug
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                decoration: item.slug == doc.slug
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: theme.colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
              final body = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 66 * 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: theme.typography.xl3.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      doc.body,
                      style: theme.typography.md.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ).penumbraEnter(context, delayMs: 40);
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [nav, const SizedBox(height: 32), body],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nav,
                  const SizedBox(width: 48),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
