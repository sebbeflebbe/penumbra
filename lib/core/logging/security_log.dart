import 'package:clock/clock.dart';

/// Append-only security events. Never store card bodies, DEKs, or phrases.
enum SecurityEventType {
  signInSuccess,
  signInFailure,
  signOut,
  exportRequested,
  accountErasureRequested,
  accountErasureCompleted,
  boardRestricted,
}

class SecurityEvent {
  const SecurityEvent({
    required this.type,
    required this.at,
    this.userId,
    this.detail,
  });

  final SecurityEventType type;
  final DateTime at;
  final String? userId;

  /// Coarse, non-sensitive detail (e.g. auth method name).
  final String? detail;
}

class SecurityLog {
  SecurityLog({List<SecurityEvent>? seed}) : _events = [...?seed];

  final List<SecurityEvent> _events;

  List<SecurityEvent> get events => List.unmodifiable(_events);

  void record({
    required SecurityEventType type,
    String? userId,
    String? detail,
  }) {
    _events.add(
      SecurityEvent(
        type: type,
        at: clock.now().toUtc(),
        userId: userId,
        detail: detail,
      ),
    );
  }
}
