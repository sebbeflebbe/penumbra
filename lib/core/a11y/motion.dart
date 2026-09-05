import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

bool penumbraReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

Duration penumbraDuration(BuildContext context, Duration duration) =>
    penumbraReduceMotion(context) ? Duration.zero : duration;

Duration penumbraRouteDuration(BuildContext context) =>
    penumbraReduceMotion(context)
    ? const Duration(milliseconds: 80)
    : const Duration(milliseconds: 280);

extension PenumbraMotion on Widget {
  Widget penumbraEnter(BuildContext context, {int delayMs = 0, int index = 0}) {
    if (penumbraReduceMotion(context)) return this;
    return animate(delay: Duration(milliseconds: delayMs + index * 55))
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .move(
          begin: const Offset(0, 12),
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget penumbraCardAppear(BuildContext context) {
    if (penumbraReduceMotion(context)) return this;
    return animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
