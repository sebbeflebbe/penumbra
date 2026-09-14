/// Compile-time configuration. Anon keys are public by design; the service role
/// must never appear here.
class PenumbraConfig {
  const PenumbraConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.controllerName,
    required this.controllerEmail,
    required this.productionOrigin,
    this.geminiApiKey = '',
    this.bankIdIssuer = '',
    this.bankIdClientId = '',
  });

  factory PenumbraConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
    const issuer = String.fromEnvironment('BANKID_ISSUER');
    const clientId = String.fromEnvironment('BANKID_CLIENT_ID');
    resolveEidMode(bankIdIssuer: issuer, bankIdClientId: clientId);
    return PenumbraConfig(
      supabaseUrl: url,
      supabaseAnonKey: anon,
      controllerName: const String.fromEnvironment(
        'PENUMBRA_CONTROLLER_NAME',
        defaultValue: 'Penumbra controller (placeholder)',
      ),
      controllerEmail: const String.fromEnvironment(
        'PENUMBRA_CONTROLLER_EMAIL',
        defaultValue: 'privacy@example.invalid',
      ),
      productionOrigin: const String.fromEnvironment(
        'PENUMBRA_ORIGIN',
        defaultValue: 'http://localhost',
      ),
      geminiApiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      bankIdIssuer: issuer,
      bankIdClientId: clientId,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String controllerName;
  final String controllerEmail;
  final String productionOrigin;
  final String geminiApiKey;
  final String bankIdIssuer;
  final String bankIdClientId;

  bool get hasRemoteBackend =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasGemini => geminiApiKey.trim().isNotEmpty;

  StudioMode get studioMode => resolveStudioMode(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  EidMode get eidMode => resolveEidMode(
    bankIdIssuer: bankIdIssuer,
    bankIdClientId: bankIdClientId,
  );
}

enum StudioMode { memory, supabase }

/// Both dart-defines, or neither. A half-set config fails closed.
StudioMode resolveStudioMode({
  required String supabaseUrl,
  required String supabaseAnonKey,
}) {
  final url = supabaseUrl.trim();
  final key = supabaseAnonKey.trim();
  if (url.isEmpty && key.isEmpty) return StudioMode.memory;
  if (url.isEmpty || key.isEmpty) {
    throw ArgumentError(
      'Supabase config is half-set. Set both SUPABASE_URL and SUPABASE_ANON_KEY, or neither.',
    );
  }
  return StudioMode.supabase;
}

enum EidMode { unset, configured }

/// Both BankID dart-defines, or neither. A half-set config fails closed.
EidMode resolveEidMode({
  required String bankIdIssuer,
  required String bankIdClientId,
}) {
  final issuer = bankIdIssuer.trim();
  final clientId = bankIdClientId.trim();
  if (issuer.isEmpty && clientId.isEmpty) return EidMode.unset;
  if (issuer.isEmpty || clientId.isEmpty) {
    throw ArgumentError(
      'BankID config is half-set. Set both BANKID_ISSUER and BANKID_CLIENT_ID, or neither.',
    );
  }
  return EidMode.configured;
}
