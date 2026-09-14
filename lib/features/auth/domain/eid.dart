import 'auth_models.dart';

const kBankIdUnavailableMessage =
    'BankID is not configured on this deployment.';

const kBankIdNotWiredMessage =
    'BankID issuer is set, but this build does not run a live BankID ceremony.';

AuthUnavailableFailure bankIdUnavailable({required bool configured}) {
  return AuthUnavailableFailure(
    configured ? kBankIdNotWiredMessage : kBankIdUnavailableMessage,
  );
}

/// Claims a future BankID / Freja OIDC assertion must never persist.
const kEidDroppedClaimKeys = {
  'ssn',
  'personalNumber',
  'personal_number',
  'swedishPersonalIdentityNumber',
};

/// Drop national-id shaped claims. Callers persist only opaque `sub` + email.
Map<String, Object?> sanitizeEidClaims(Map<String, Object?> claims) {
  return {
    for (final entry in claims.entries)
      if (!kEidDroppedClaimKeys.contains(entry.key)) entry.key: entry.value,
  };
}
