import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    return PenumbraChrome(
      child: PenumbraPage(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final headline = Text(
                'A quiet studio for thinking in space.',
                style: theme.typography.xl4.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.08,
                  letterSpacing: -0.8,
                ),
              ).penumbraEnter(context);
              final lede = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  "A spatial notebook for thoughts that aren't ready to leave the room. Notes stay encrypted in the browser; you hold the key. The studio is yours alone.",
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.55,
                  ),
                ),
              ).penumbraEnter(context, delayMs: 40);
              final actions = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FButton(
                    onPress: () async {
                      final failure = await ref
                          .read(authControllerProvider.notifier)
                          .demo();
                      if (!context.mounted) return;
                      if (failure == null) {
                        context.go('/boards');
                      } else {
                        context.go('/sign-in');
                      }
                    },
                    prefix: const Icon(FLucideIcons.fingerprint),
                    child: const Text('Enter the studio'),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => context.go('/making-of'),
                    child: const Text('Read the making of'),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    onPress: () => context.go('/legal/privacy'),
                    child: const Text('Privacy'),
                  ),
                ],
              ).penumbraEnter(context, delayMs: 80);
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headline,
                  const SizedBox(height: 20),
                  lede,
                  const SizedBox(height: 32),
                  actions,
                ],
              );
              final teaser = const _Teaser().penumbraEnter(
                context,
                delayMs: 120,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: copy),
                        const SizedBox(width: 48),
                        Expanded(flex: 6, child: teaser),
                      ],
                    )
                  else ...[
                    copy,
                    const SizedBox(height: 40),
                    teaser,
                  ],
                  const SizedBox(height: 64),
                  _Facts(theme: theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.theme});

  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        title: 'Private by default',
        body:
            'Board bodies are encrypted in the browser before they touch a server.',
      ),
      (
        title: 'Accessible by design',
        body:
            'The canvas has a document order, names, and a high-contrast theme.',
      ),
      (
        title: 'Legally operable',
        body:
            'GDPR rights, an SBOM, and an honest “we are not CE-marked” note.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800;
        Widget factAt(int i) => _Fact(
          title: items[i].title,
          body: items[i].body,
        ).penumbraEnter(context, index: i);
        if (columns) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 32 : 0),
                    child: factAt(i),
                  ),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: factAt(i),
              ),
          ],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.lg.copyWith(
            fontFamily: PenumbraInk.displayFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Teaser extends StatelessWidget {
  const _Teaser();

  @override
  Widget build(BuildContext context) {
    if (penumbraReduceMotion(context)) {
      return const _TeaserStage(key: Key('penumbra-teaser'));
    }
    return const _LivingTeaser(key: Key('penumbra-teaser-living'));
  }
}

class _LivingTeaser extends StatefulWidget {
  const _LivingTeaser({super.key});

  @override
  State<_LivingTeaser> createState() => _LivingTeaserState();
}

class _LivingTeaserState extends State<_LivingTeaser>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) => _TeaserStage(
        shiftA: Offset(6 * (_drift.value - 0.5), -8 * (_drift.value - 0.5)),
        shiftB: Offset(-10 * (_drift.value - 0.5), 5 * (_drift.value - 0.5)),
        shiftC: Offset(4 * (_drift.value - 0.5), 10 * (_drift.value - 0.5)),
      ),
    );
  }
}

class _TeaserStage extends StatelessWidget {
  const _TeaserStage({
    super.key,
    this.shiftA = Offset.zero,
    this.shiftB = Offset.zero,
    this.shiftC = Offset.zero,
  });

  final Offset shiftA;
  final Offset shiftB;
  final Offset shiftC;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SizedBox(
      height: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _DotGridPainter(color: theme.colors.border),
            child: Stack(
              children: [
                _PaperCard(
                  left: 28 + shiftA.dx,
                  top: 36 + shiftA.dy,
                  label: 'Private by default.',
                ),
                _PaperCard(
                  left: 250 + shiftB.dx,
                  top: 64 + shiftB.dy,
                  label: 'Accessible by design.',
                ),
                _PaperCard(
                  left: 140 + shiftC.dx,
                  top: 168 + shiftC.dy,
                  label: 'Colour swatch',
                  swatch: PenumbraInk.copper,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.left,
    required this.top,
    required this.label,
    this.swatch,
  });

  final double left;
  final double top;
  final String label;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Positioned(
      left: left,
      top: top,
      child: Semantics(
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colors.border),
            boxShadow: [
              BoxShadow(
                color: theme.colors.foreground.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: swatch == null
                ? SizedBox(
                    width: 180,
                    child: Text(
                      label,
                      style: theme.typography.sm.copyWith(
                        fontFamily: PenumbraInk.displayFamily,
                      ),
                    ),
                  )
                : Container(width: 72, height: 72, color: swatch),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 22.0;
    for (var x = 12.0; x < size.width; x += step) {
      for (var y = 12.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
