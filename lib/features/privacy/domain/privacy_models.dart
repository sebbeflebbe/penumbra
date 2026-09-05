import 'package:clock/clock.dart';

enum ConsentKind { necessaryStorage, termsOfUse }

class ConsentEvent {
  const ConsentEvent({
    required this.id,
    required this.userId,
    required this.kind,
    required this.granted,
    required this.at,
  });

  final String id;
  final String userId;
  final ConsentKind kind;
  final bool granted;
  final DateTime at;
}

class PrivacyExport {
  const PrivacyExport({
    required this.generatedAt,
    required this.profile,
    required this.boards,
    required this.nodes,
    required this.consents,
  });

  final DateTime generatedAt;
  final Map<String, Object?> profile;
  final List<Map<String, Object?>> boards;
  final List<Map<String, Object?>> nodes;
  final List<Map<String, Object?>> consents;

  Map<String, Object?> toJson() => {
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'profile': profile,
    'boards': boards,
    'nodes': nodes,
    'consents': consents,
  };
}

class DataCategory {
  const DataCategory({
    required this.name,
    required this.purpose,
    required this.lawfulBasis,
    required this.retention,
  });

  final String name;
  final String purpose;
  final String lawfulBasis;
  final String retention;
}

List<DataCategory> penumbraDataCategories() => const [
  DataCategory(
    name: 'Account identifiers',
    purpose: 'Authenticate you and restore your session',
    lawfulBasis: 'Contract (GDPR Art. 6(1)(b))',
    retention: 'Life of the account, then erased',
  ),
  DataCategory(
    name: 'Board metadata',
    purpose: 'List and organise your studio boards',
    lawfulBasis: 'Contract (GDPR Art. 6(1)(b))',
    retention: 'Life of the account, then erased',
  ),
  DataCategory(
    name: 'Encrypted board nodes',
    purpose: 'Store your notes as ciphertext the server cannot read',
    lawfulBasis: 'Contract (GDPR Art. 6(1)(b))',
    retention: 'Life of the account, then erased',
  ),
  DataCategory(
    name: 'Consent and security events',
    purpose: 'Demonstrate consent and detect abuse',
    lawfulBasis: 'Legal obligation / contract',
    retention: '90 days for security logs; consents for the life of the account',
  ),
  DataCategory(
    name: 'Optional echo (Gemini)',
    purpose: 'A short companion to one summoned slip, never the rest of the board',
    lawfulBasis: 'Consent (GDPR Art. 6(1)(a)); local fallback if no key',
    retention: 'Not stored at Google by us; the echo slip is encrypted like any other card',
  ),
];

ConsentEvent grantNecessary({required String id, required String userId}) {
  return ConsentEvent(
    id: id,
    userId: userId,
    kind: ConsentKind.necessaryStorage,
    granted: true,
    at: clock.now().toUtc(),
  );
}
