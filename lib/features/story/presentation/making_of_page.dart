import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import '../data/story_catalog.dart';

class MakingOfPage extends StatelessWidget {
  const MakingOfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return PenumbraChrome(
      title: 'Making of',
      child: PenumbraPage(
        maxWidth: 780,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Making of Penumbra',
                style: theme.typography.xl3.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ).penumbraEnter(context),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 66 * 8),
                child: Text(
                  'The development story is a product surface. Each chapter names the European control it answers.',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ).penumbraEnter(context, delayMs: 40),
              const SizedBox(height: 40),
              for (var i = 0; i < StoryCatalog.chapters.length; i++) ...[
                _Chapter(
                  chapter: StoryCatalog.chapters[i],
                  index: i,
                ).penumbraEnter(context, index: i),
                const SizedBox(height: 36),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chapter extends StatelessWidget {
  const _Chapter({required this.chapter, required this.index});

  final StoryChapter chapter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 66 * 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.id,
            style: theme.typography.xl.copyWith(
              fontFamily: PenumbraInk.displayFamily,
              color: theme.colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            chapter.title,
            style: theme.typography.xl2.copyWith(
              fontFamily: PenumbraInk.displayFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapter.control,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(chapter.body, style: theme.typography.md.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
