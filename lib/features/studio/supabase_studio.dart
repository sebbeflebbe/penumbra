// GoTrue passkeys are @experimental in 2.27; that is the shipped cloud API.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../../core/crypto/key_derivation.dart';
import '../../core/crypto/payload_cipher.dart';
import '../../core/crypto/recovery_phrase.dart';
import '../../core/errors.dart';
import '../../core/logging/security_log.dart';
import '../../core/result.dart';
import '../auth/data/passkey_ceremony_factory.dart';
import '../auth/domain/auth_models.dart';
import '../auth/domain/passkey_ceremony.dart';
import '../boards/domain/board.dart';
import '../boards/domain/echo_pairing.dart';
import '../privacy/domain/privacy_models.dart';
import '../privacy/domain/privacy_repository.dart';
import 'device_store.dart';

/// Supabase-backed studio. Payloads are AES-256-GCM in the browser; Postgres
/// stores ciphertext and RLS is the authorisation boundary.
class SupabaseStudio implements AuthRepository, PrivacyRepository {
  SupabaseStudio({
    required SupabaseClient client,
    required List<String> wordlist,
    required DeviceStore store,
    PayloadCipher? cipher,
    KeyDerivation? derivation,
    Random? random,
    String? redirectTo,
    PasskeyCeremony? passkeys,
  }) : _client = client,
       _wordlist = wordlist,
       _store = store,
       _cipher = cipher ?? PayloadCipher(),
       _derivation = derivation ?? KeyDerivation(),
       _random = random ?? Random.secure(),
       _redirectTo = redirectTo,
       _passkeys = passkeys ?? createPasskeyCeremony() {
    _authSub = _client.auth.onAuthStateChange.listen((data) {
      if (_holdListener) return;
      unawaited(_onSession(data.session, wrappingSecret: null));
    });
    unawaited(_onSession(_client.auth.currentSession, wrappingSecret: null));
  }

  final SupabaseClient _client;
  final List<String> _wordlist;
  final DeviceStore _store;
  final PayloadCipher _cipher;
  final KeyDerivation _derivation;
  final Random _random;
  final String? _redirectTo;
  final PasskeyCeremony _passkeys;

  final _controller = StreamController<AuthUser?>.broadcast();
  StreamSubscription<AuthState>? _authSub;

  AuthUser? _current;
  Uint8List? _sessionDek;
  String? _pendingRecoveryPhrase;
  DateTime? _lastReauthAt;
  Future<void>? _hydrateGate;
  var _holdListener = false;

  @override
  AuthUser? get current => _current;

  @override
  String? get pendingRecoveryPhrase =>
      _current == null ? null : _pendingRecoveryPhrase;

  @override
  Stream<AuthUser?> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  void acknowledgeRecoveryPhrase() {
    _pendingRecoveryPhrase = null;
    final user = _current;
    if (user == null) return;
    _setCurrent(user.copyWith(needsRecoveryPhraseReveal: false));
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized) || password.length < 12) {
      return const Err(InvalidCredentialsFailure());
    }
    _holdListener = true;
    try {
      final response = await _client.auth.signInWithPassword(
        email: normalized,
        password: password,
      );
      final session = response.session;
      if (session == null) {
        return const Err(InvalidCredentialsFailure());
      }
      await _onSession(session, wrappingSecret: password, markReauth: true);
      final user = _current;
      if (user == null || _sessionDek == null) {
        return const Err(InvalidCredentialsFailure());
      }
      await _audit(
        SecurityEventType.signInSuccess,
        userId: user.id,
        detail: 'password',
      );
      return Ok(user);
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    } finally {
      _holdListener = false;
    }
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      return const Err(InvalidCredentialsFailure('Enter a valid email.'));
    }
    if (password.length < 12) {
      return const Err(WeakSecretFailure());
    }
    _holdListener = true;
    try {
      final response = await _client.auth.signUp(
        email: normalized,
        password: password,
        emailRedirectTo: _redirectTo,
      );
      final session = response.session;
      if (session == null) {
        return const Err(
          AuthUnavailableFailure(
            'Confirm your email, then sign in to enter the studio.',
          ),
        );
      }
      await _onSession(session, wrappingSecret: password, markReauth: true);
      final user = _current;
      if (user == null) {
        return const Err(
          AuthUnavailableFailure('Sign-up did not establish a session.'),
        );
      }
      await recordConsent(ConsentKind.necessaryStorage, granted: true);
      await _audit(
        SecurityEventType.signInSuccess,
        userId: user.id,
        detail: 'password-signup',
      );
      return Ok(user);
    } on AuthWeakPasswordException catch (error) {
      return Err(WeakSecretFailure(error.message));
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    } finally {
      _holdListener = false;
    }
  }

  @override
  Future<Result<void, AuthFailure>> sendMagicLink({
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      return const Err(InvalidCredentialsFailure('Enter a valid email.'));
    }
    try {
      await _client.auth.signInWithOtp(
        email: normalized,
        emailRedirectTo: _redirectTo,
      );
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    }
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithGoogle() =>
      _federated(OAuthProvider.google);

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithGitHub() =>
      _federated(OAuthProvider.github);

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithPasskey() async {
    if (!_passkeys.isSupported) {
      return Err(passkeyUnavailable(supported: false));
    }
    _holdListener = true;
    try {
      final challenge = await _client.auth.passkey.startAuthentication();
      final credential = await _passkeys.get(challenge.options);
      final response = await _client.auth.passkey.verifyAuthentication(
        challengeId: challenge.challengeId,
        credential: credential,
      );
      final session = response.session;
      if (session == null) {
        return Err(passkeyUnavailable(supported: true));
      }
      await _onSession(session, wrappingSecret: null, markReauth: true);
      final user = _current;
      if (user == null || _sessionDek == null) {
        return const Err(
          AuthUnavailableFailure(
            'Passkey sign-in did not unlock the studio key.',
          ),
        );
      }
      await _audit(
        SecurityEventType.signInSuccess,
        userId: user.id,
        detail: 'passkey',
      );
      return Ok(user);
    } on PasskeyCancelled {
      return const Err(AuthCancelledFailure());
    } on UnsupportedError {
      return Err(passkeyUnavailable(supported: false));
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    } finally {
      _holdListener = false;
    }
  }

  @override
  Future<Result<void, AuthFailure>> registerPasskey() async {
    if (!_passkeys.isSupported) {
      return Err(passkeyUnavailable(supported: false));
    }
    if (_current == null) {
      return const Err(AuthUnavailableFailure('Sign in first.'));
    }
    try {
      final challenge = await _client.auth.passkey.startRegistration();
      final credential = await _passkeys.create(challenge.options);
      await _client.auth.passkey.verifyRegistration(
        challengeId: challenge.challengeId,
        credential: credential,
      );
      return const Ok(null);
    } on PasskeyCancelled {
      return const Err(AuthCancelledFailure());
    } on UnsupportedError {
      return Err(passkeyUnavailable(supported: false));
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    }
  }

  @override
  Future<Result<AuthUser, AuthFailure>> enterDemoStudio() async {
    return const Err(
      AuthUnavailableFailure(
        'The demo studio is the in-memory path. Run without SUPABASE dart-defines, or sign in.',
      ),
    );
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    final id = _current?.id;
    await _audit(SecurityEventType.signOut, userId: id);
    await _client.auth.signOut();
    _clearLocal();
    return const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> reauthenticate({String? password}) async {
    final user = _current;
    if (user == null) return const Err(AuthUnavailableFailure());
    if (user.methods.contains(AuthMethod.password)) {
      final email = user.email;
      if (email == null || password == null) {
        return const Err(InvalidCredentialsFailure());
      }
      try {
        await _client.auth.signInWithPassword(email: email, password: password);
      } on AuthException catch (error) {
        return Err(_mapAuth(error));
      }
    } else if (password != null) {
      return const Err(InvalidCredentialsFailure());
    } else {
      final last = _lastReauthAt;
      if (last == null ||
          clock.now().toUtc().difference(last) > const Duration(minutes: 5)) {
        return const Err(
          AuthUnavailableFailure('Sign in again to erase this account.'),
        );
      }
      return const Ok(null);
    }
    _lastReauthAt = clock.now().toUtc();
    return const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    final user = _current;
    if (user == null) return const Err(AuthUnavailableFailure());
    final reauth = _lastReauthAt;
    if (reauth == null ||
        clock.now().toUtc().difference(reauth) > const Duration(minutes: 5)) {
      return const Err(
        AuthUnavailableFailure('Re-authenticate to erase this account.'),
      );
    }
    await _audit(SecurityEventType.accountErasureRequested, userId: user.id);
    try {
      await _client.from('board_nodes').delete().eq('owner_id', user.id);
      await _client.from('boards').delete().eq('owner_id', user.id);
      await _client.from('consent_events').delete().eq('user_id', user.id);
      await _client.from('security_events').delete().eq('user_id', user.id);
      await _client.from('profiles').delete().eq('id', user.id);
      await _client.rpc<void>('erase_own_account');
    } on Object {
      // RPC may be missing until migration 0003 is applied; local rows are already gone.
    }
    await _store.delete(_deviceKey(user.id));
    await _store.delete(_deviceWrapped(user.id));
    await _client.auth.signOut();
    _clearLocal();
    await _audit(SecurityEventType.accountErasureCompleted, userId: user.id);
    return const Ok(null);
  }

  Future<Result<List<Board>, AppFailure>> listMine() async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    try {
      final rows = await _client
          .from('boards')
          .select()
          .eq('owner_id', user.id)
          .order('updated_at', ascending: false);
      return Ok([
        for (final row in rows as List) _boardFrom(row as Map<String, dynamic>),
      ]);
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  Future<Result<Board, AppFailure>> getById(String id) async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    try {
      final row = await _client
          .from('boards')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const Err(NotFoundFailure('Board not found.'));
      final board = _boardFrom(row);
      if (board.ownerId != user.id) {
        return const Err(
          ForbiddenFailure('That board belongs to someone else.'),
        );
      }
      return Ok(board);
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  Future<Result<Board, AppFailure>> create({required String title}) async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    final trimmed = title.trim();
    if (trimmed.isEmpty)
      return const Err(ValidationFailure('Give the board a name.'));
    try {
      final row = await _client
          .from('boards')
          .insert({'owner_id': user.id, 'title': trimmed})
          .select()
          .single();
      return Ok(_boardFrom(row));
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  Future<Result<Board, AppFailure>> rename({
    required String id,
    required String title,
  }) async {
    final existing = await getById(id);
    return existing.when(
      ok: (board) async {
        if (board.restricted) {
          return const Err(
            ForbiddenFailure('This board is restricted (Art. 18).'),
          );
        }
        try {
          final row = await _client
              .from('boards')
              .update({
                'title': title.trim(),
                'updated_at': clock.now().toUtc().toIso8601String(),
              })
              .eq('id', id)
              .select()
              .single();
          return Ok(_boardFrom(row));
        } on Object catch (error) {
          return Err(_mapPostgrest(error));
        }
      },
      err: (failure) async => Err(failure),
    );
  }

  Future<Result<void, AppFailure>> delete(String id) async {
    final existing = await getById(id);
    return existing.when(
      ok: (_) async {
        try {
          await _client.from('boards').delete().eq('id', id);
          return const Ok(null);
        } on Object catch (error) {
          return Err(_mapPostgrest(error));
        }
      },
      err: (failure) async => Err(failure),
    );
  }

  Future<Result<Board, AppFailure>> setRestricted({
    required String id,
    required bool restricted,
  }) async {
    final existing = await getById(id);
    return existing.when(
      ok: (board) async {
        try {
          final row = await _client
              .from('boards')
              .update({
                'restricted': restricted,
                'updated_at': clock.now().toUtc().toIso8601String(),
              })
              .eq('id', id)
              .select()
              .single();
          await _audit(
            SecurityEventType.boardRestricted,
            userId: board.ownerId,
            detail: restricted ? 'restricted' : 'unrestricted',
          );
          return Ok(_boardFrom(row));
        } on Object catch (error) {
          return Err(_mapPostgrest(error));
        }
      },
      err: (failure) async => Err(failure),
    );
  }

  Future<Result<List<BoardNode>, AppFailure>> listNodes(String boardId) async {
    final dek = _sessionDek;
    if (dek == null) return const Err(UnauthenticatedFailure());
    switch (await getById(boardId)) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        try {
          final rows = await _client
              .from('board_nodes')
              .select()
              .eq('board_id', boardId);
          final out = <BoardNode>[];
          for (final row in rows as List) {
            final map = row as Map<String, dynamic>;
            final stored = Ciphertext.fromStorage(
              map['ciphertext'] as String? ?? '',
            );
            switch (stored) {
              case Err():
                continue;
              case Ok(:final value):
                switch (await _cipher.decrypt(
                  dekBytes: dek,
                  ciphertext: value,
                )) {
                  case Err():
                    continue;
                  case Ok(:final value):
                    final decoded = json.decode(utf8.decode(value));
                    if (decoded is! Map) continue;
                    out.add(
                      BoardNode.fromPayload(
                        id: map['id'] as String,
                        boardId: boardId,
                        payload: decoded.map(
                          (k, v) => MapEntry(k.toString(), v),
                        ),
                      ),
                    );
                }
            }
          }
          return Ok(out);
        } on Object catch (error) {
          return Err(_mapPostgrest(error));
        }
    }
  }

  Future<Result<BoardNode, AppFailure>> upsert(BoardNode node) async {
    final dek = _sessionDek;
    final user = _current;
    if (dek == null || user == null) return const Err(UnauthenticatedFailure());
    switch (await getById(node.boardId)) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final board = value;
        if (board.restricted) {
          return const Err(
            ForbiddenFailure('This board is restricted (Art. 18).'),
          );
        }
        final siblings = await _decryptedSiblings(
          boardId: node.boardId,
          dek: dek,
          exceptId: node.id,
        );
        switch (EchoPairing.validateWrite(node, siblings)) {
          case Err(:final failure):
            return Err(failure);
          case Ok():
            break;
        }
        final jsonBytes = utf8.encode(json.encode(node.toPayload()));
        switch (await _cipher.encrypt(dekBytes: dek, plaintext: jsonBytes)) {
          case Err(:final failure):
            return Err(failure);
          case Ok(:final value):
            try {
              await _client.from('board_nodes').upsert({
                'id': node.id,
                'board_id': node.boardId,
                'owner_id': user.id,
                'ciphertext': value.toStorage(),
              });
              await _client
                  .from('boards')
                  .update({'updated_at': clock.now().toUtc().toIso8601String()})
                  .eq('id', board.id);
              return Ok(node);
            } on Object catch (error) {
              return Err(_mapPostgrest(error));
            }
        }
    }
  }

  Future<Result<void, AppFailure>> deleteNode(String nodeId) async {
    final dek = _sessionDek;
    final user = _current;
    if (dek == null || user == null) return const Err(UnauthenticatedFailure());
    try {
      final row = await _client
          .from('board_nodes')
          .select()
          .eq('id', nodeId)
          .maybeSingle();
      if (row == null) return const Err(NotFoundFailure('Card not found.'));
      final boardId = row['board_id'] as String;
      switch (await getById(boardId)) {
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value):
          if (value.restricted) {
            return const Err(
              ForbiddenFailure('This board is restricted (Art. 18).'),
            );
          }
          final cascade = <String>{nodeId};
          final siblings = await _client
              .from('board_nodes')
              .select()
              .eq('board_id', boardId);
          for (final other in siblings as List) {
            final map = other as Map<String, dynamic>;
            final id = map['id'] as String;
            if (id == nodeId) continue;
            final stored = Ciphertext.fromStorage(
              map['ciphertext'] as String? ?? '',
            );
            switch (stored) {
              case Err():
                continue;
              case Ok(:final value):
                switch (await _cipher.decrypt(
                  dekBytes: dek,
                  ciphertext: value,
                )) {
                  case Err():
                    continue;
                  case Ok(:final value):
                    final decoded = json.decode(utf8.decode(value));
                    if (decoded is Map && decoded['parentId'] == nodeId) {
                      cascade.add(id);
                    }
                }
            }
          }
          for (final id in cascade) {
            await _client.from('board_nodes').delete().eq('id', id);
          }
          return const Ok(null);
      }
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  @override
  Future<Result<List<ConsentEvent>, AppFailure>> consents() async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    try {
      final rows = await _client
          .from('consent_events')
          .select()
          .eq('user_id', user.id)
          .order('at');
      return Ok([
        for (final row in rows as List)
          ConsentEvent(
            id: (row as Map<String, dynamic>)['id'] as String,
            userId: row['user_id'] as String,
            kind: _consentKind(row['kind'] as String?),
            granted: row['granted'] as bool? ?? false,
            at: DateTime.parse(row['at'] as String).toUtc(),
          ),
      ]);
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  @override
  Future<Result<ConsentEvent, AppFailure>> recordConsent(
    ConsentKind kind, {
    required bool granted,
  }) async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    try {
      final row = await _client
          .from('consent_events')
          .insert({'user_id': user.id, 'kind': kind.name, 'granted': granted})
          .select()
          .single();
      return Ok(
        ConsentEvent(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          kind: kind,
          granted: granted,
          at: DateTime.parse(row['at'] as String).toUtc(),
        ),
      );
    } on Object catch (error) {
      return Err(_mapPostgrest(error));
    }
  }

  @override
  Future<Result<PrivacyExport, AppFailure>> exportMine() async {
    final user = _current;
    if (user == null) return const Err(UnauthenticatedFailure());
    await _audit(SecurityEventType.exportRequested, userId: user.id);
    final boards = await listMine();
    return boards.when(
      ok: (list) async {
        final nodes = <Map<String, Object?>>[];
        for (final board in list) {
          final listed = await listNodes(board.id);
          listed.when(
            ok: (items) {
              for (final node in items) {
                nodes.add({
                  'id': node.id,
                  'boardId': node.boardId,
                  'kind': node.kind.name,
                  'text': node.text,
                  'colorArgb': node.colorArgb,
                  'x': node.x,
                  'y': node.y,
                });
              }
            },
            err: (_) {},
          );
        }
        final consentRows =
            (await consents()).okOrNull ?? const <ConsentEvent>[];
        return Ok(
          PrivacyExport(
            generatedAt: clock.now().toUtc(),
            profile: {
              'id': user.id,
              'email': user.email,
              'displayName': user.displayName,
              'methods': user.methods.map((m) => m.name).toList(),
            },
            boards: [
              for (final board in list)
                {
                  'id': board.id,
                  'title': board.title,
                  'updatedAt': board.updatedAt.toIso8601String(),
                  'restricted': board.restricted,
                },
            ],
            nodes: nodes,
            consents: [
              for (final c in consentRows)
                {
                  'id': c.id,
                  'kind': c.kind.name,
                  'granted': c.granted,
                  'at': c.at.toIso8601String(),
                },
            ],
          ),
        );
      },
      err: (failure) async => Err(failure),
    );
  }

  @override
  Future<Result<void, AppFailure>> eraseAccount({String? password}) async {
    final reauth = await reauthenticate(password: password);
    return reauth.when(
      ok: (_) async {
        final deleted = await deleteAccount();
        return deleted.when(
          ok: (_) => const Ok(null),
          err: (f) => Err(UnavailableFailure(f.message)),
        );
      },
      err: (f) async => Err(UnauthenticatedFailure(f.message)),
    );
  }

  Future<Result<AuthUser, AuthFailure>> _federated(
    OAuthProvider provider,
  ) async {
    try {
      final launched = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectTo,
      );
      if (!launched) return const Err(AuthCancelledFailure());
      final user = _current;
      if (user != null) return Ok(user);
      return Ok(
        AuthUser(
          id: 'oauth-redirect',
          methods: {
            provider == OAuthProvider.google
                ? AuthMethod.google
                : AuthMethod.github,
          },
        ),
      );
    } on AuthException catch (error) {
      return Err(_mapAuth(error));
    }
  }

  Future<void> _onSession(
    Session? session, {
    String? wrappingSecret,
    bool markReauth = false,
  }) {
    final previous = _hydrateGate;
    final next = () async {
      await previous;
      await _hydrate(
        session,
        wrappingSecret: wrappingSecret,
        markReauth: markReauth,
      );
    }();
    _hydrateGate = next;
    return next;
  }

  Future<void> _hydrate(
    Session? session, {
    String? wrappingSecret,
    bool markReauth = false,
  }) async {
    if (session == null) {
      _clearLocal();
      return;
    }
    final remote = session.user;
    if (_sessionDek != null &&
        _current?.id == remote.id &&
        wrappingSecret == null) {
      if (markReauth) _lastReauthAt = clock.now().toUtc();
      return;
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select()
          .eq('id', remote.id)
          .maybeSingle();
    } on Object {
      profile = null;
    }

    final saltRaw = profile?['wrap_salt'] as String?;
    final wrappedRaw = profile?['wrapped_dek'] as String?;
    Uint8List? dek;
    var reveal = false;
    var firstWrap = false;

    if (wrappingSecret != null && saltRaw != null && wrappedRaw != null) {
      dek = await _unwrapDek(
        secret: wrappingSecret,
        saltRaw: saltRaw,
        wrappedRaw: wrappedRaw,
      );
    }

    dek ??= await _unlockDevice(remote.id);

    if (dek == null &&
        wrappingSecret != null &&
        (saltRaw == null || wrappedRaw == null)) {
      dek = _newDek();
      firstWrap = await _persistWrap(
        userId: remote.id,
        dek: dek,
        secret: wrappingSecret,
      );
      if (!firstWrap) dek = null;
    }

    if (dek == null && (saltRaw == null || wrappedRaw == null)) {
      final phrase = _newPhrase();
      dek = _newDek();
      firstWrap = await _persistWrap(
        userId: remote.id,
        dek: dek,
        secret: phrase,
      );
      if (firstWrap) {
        _pendingRecoveryPhrase = phrase;
        reveal = true;
      } else {
        dek = null;
      }
    }

    if (dek == null) {
      _sessionDek = null;
      _setCurrent(_toUser(remote, reveal: false));
      return;
    }

    _sessionDek = dek;
    await _rememberDevice(remote.id, dek);
    if (markReauth || wrappingSecret != null) {
      _lastReauthAt = clock.now().toUtc();
    }
    _setCurrent(_toUser(remote, reveal: reveal));
    if (firstWrap) {
      try {
        await recordConsent(ConsentKind.necessaryStorage, granted: true);
      } on Object {
        // Consent insert is best-effort on first wrap.
      }
    }
  }

  Future<Uint8List?> _unwrapDek({
    required String secret,
    required String saltRaw,
    required String wrappedRaw,
  }) async {
    final salt = _decodeB64(saltRaw);
    if (salt == null) return null;
    final wrapping = await _derivation.deriveWrappingKey(
      secret: secret,
      salt: salt,
    );
    final wrapKey = wrapping.okOrNull;
    if (wrapKey == null) return null;
    final stored = Ciphertext.fromStorage(wrappedRaw).okOrNull;
    if (stored == null) return null;
    return (await _cipher.decrypt(
      dekBytes: wrapKey,
      ciphertext: stored,
    )).okOrNull;
  }

  Future<bool> _persistWrap({
    required String userId,
    required Uint8List dek,
    required String secret,
  }) async {
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    final wrapping = await _derivation.deriveWrappingKey(
      secret: secret,
      salt: salt,
    );
    final wrapKey = wrapping.okOrNull;
    if (wrapKey == null) return false;
    final wrapped = (await _cipher.encrypt(
      dekBytes: wrapKey,
      plaintext: dek,
    )).okOrNull;
    if (wrapped == null) return false;
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'wrap_salt': base64Url.encode(salt).replaceAll('=', ''),
        'wrapped_dek': wrapped.toStorage(),
      });
      return true;
    } on Object {
      return false;
    }
  }

  Future<Uint8List?> _unlockDevice(String userId) async {
    final keyRaw = _store.read(_deviceKey(userId));
    final wrappedRaw = _store.read(_deviceWrapped(userId));
    if (keyRaw == null || wrappedRaw == null) return null;
    final key = _decodeB64(keyRaw);
    if (key == null || key.length != 32) return null;
    final stored = Ciphertext.fromStorage(wrappedRaw).okOrNull;
    if (stored == null) return null;
    return (await _cipher.decrypt(dekBytes: key, ciphertext: stored)).okOrNull;
  }

  Future<void> _rememberDevice(String userId, Uint8List dek) async {
    final key = _newDek();
    final wrapped = (await _cipher.encrypt(
      dekBytes: key,
      plaintext: dek,
    )).okOrNull;
    if (wrapped == null) return;
    await _store.write(
      _deviceKey(userId),
      base64Url.encode(key).replaceAll('=', ''),
    );
    await _store.write(_deviceWrapped(userId), wrapped.toStorage());
  }

  Future<List<BoardNode>> _decryptedSiblings({
    required String boardId,
    required Uint8List dek,
    required String exceptId,
  }) async {
    final listed = await listNodes(boardId);
    return [
      for (final node in listed.okOrNull ?? const <BoardNode>[])
        if (node.id != exceptId) node,
    ];
  }

  Future<void> _audit(
    SecurityEventType type, {
    String? userId,
    String? detail,
  }) async {
    if (userId == null) return;
    try {
      await _client.from('security_events').insert({
        'user_id': userId,
        'type': type.name,
        'detail': detail,
      });
    } on Object {
      // Auditing must never block sign-out or erasure.
    }
  }

  AuthUser _toUser(User user, {required bool reveal}) {
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName:
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
      methods: _methods(user),
      needsRecoveryPhraseReveal: reveal && _pendingRecoveryPhrase != null,
    );
  }

  Set<AuthMethod> _methods(User user) {
    final out = <AuthMethod>{};
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      switch (identity.provider) {
        case 'google':
          out.add(AuthMethod.google);
        case 'github':
          out.add(AuthMethod.github);
        case 'email':
          out.add(AuthMethod.password);
          out.add(AuthMethod.magicLink);
        case 'webauthn':
          out.add(AuthMethod.passkey);
      }
    }
    if (out.isEmpty) out.add(AuthMethod.magicLink);
    return out;
  }

  Board _boardFrom(Map<String, dynamic> row) {
    return Board(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String,
      title: row['title'] as String? ?? '',
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      restricted: row['restricted'] as bool? ?? false,
    );
  }

  ConsentKind _consentKind(String? name) {
    for (final kind in ConsentKind.values) {
      if (kind.name == name) return kind;
    }
    return ConsentKind.necessaryStorage;
  }

  void _setCurrent(AuthUser user) {
    _current = user;
    _controller.add(user);
  }

  void _clearLocal() {
    _current = null;
    _sessionDek = null;
    _pendingRecoveryPhrase = null;
    _lastReauthAt = null;
    _controller.add(null);
  }

  Uint8List _newDek() =>
      Uint8List.fromList(List<int>.generate(32, (_) => _random.nextInt(256)));

  String _newPhrase() {
    final entropy = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return RecoveryPhrase.fromEntropy(
      entropy: entropy,
      wordlist: _wordlist,
    ).when(
      ok: (phrase) => phrase.display,
      err: (_) => base64Url.encode(entropy),
    );
  }

  Uint8List? _decodeB64(String value) {
    try {
      final pad = (4 - value.length % 4) % 4;
      return Uint8List.fromList(base64Url.decode(value + ('=' * pad)));
    } on FormatException {
      return null;
    }
  }

  AuthFailure _mapAuth(AuthException error) {
    if (error.statusCode == '429') return const RateLimitedFailure();
    if (error is AuthWeakPasswordException)
      return WeakSecretFailure(error.message);
    final code = error.code;
    if (code == 'passkey_disabled' || code == 'webauthn_credential_not_found') {
      return const AuthUnavailableFailure(kPasskeyProjectDisabledMessage);
    }
    if (code == 'webauthn_challenge_expired' ||
        code == 'webauthn_verification_failed') {
      return const AuthCancelledFailure(
        'That passkey could not be verified. Try again.',
      );
    }
    return InvalidCredentialsFailure(error.message);
  }

  AppFailure _mapPostgrest(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const ForbiddenFailure('That board belongs to someone else.');
      }
      if (error.code == 'PGRST116') {
        return const NotFoundFailure('Board not found.');
      }
      return UnavailableFailure(error.message);
    }
    return const UnavailableFailure('The studio could not reach the cloud.');
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);

  String _deviceKey(String userId) => 'penumbra.device_key.$userId';
  String _deviceWrapped(String userId) => 'penumbra.device_wrapped.$userId';

  void dispose() {
    unawaited(_authSub?.cancel());
    unawaited(_controller.close());
  }
}
