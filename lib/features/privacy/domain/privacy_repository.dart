import '../../../core/errors.dart';
import '../../../core/logging/security_log.dart';
import '../../../core/result.dart';
import 'privacy_models.dart';

abstract class PrivacyRepository {
  Future<Result<List<ConsentEvent>, AppFailure>> consents();
  Future<Result<ConsentEvent, AppFailure>> recordConsent(
    ConsentKind kind, {
    required bool granted,
  });
  Future<Result<List<SecurityEvent>, AppFailure>> securityEvents();
  Future<Result<PrivacyExport, AppFailure>> exportMine();
  Future<Result<void, AppFailure>> eraseAccount({String? password});
  Future<Result<void, AppFailure>> updateDisplayName(String? name);
}
