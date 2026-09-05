import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import '../../core/crypto/key_derivation.dart';
import '../../core/crypto/payload_cipher.dart';
import '../../core/crypto/recovery_phrase.dart';
import '../../core/errors.dart';
import '../../core/logging/security_log.dart';
import '../../core/result.dart';
import '../auth/domain/auth_models.dart';
import '../boards/domain/board.dart';
import '../boards/domain/echo_pairing.dart';
import '../privacy/domain/privacy_models.dart';
import '../privacy/domain/privacy_repository.dart';

class _Account {
  _Account({
    required this.id,
    required this.email,
    required this.methods,
    required this.dek,
    required this.wrapSalt,
    required this.wrappedDek,
    this.passwordHash,
    this.displayName,
  });

  final String id;
  String? email;
  String? displayName;
  Set<AuthMethod> methods;
  String? passwordHash;
  Uint8List dek;
  Uint8List wrapSalt;
  Ciphertext wrappedDek;
  String? pendingRecoveryPhrase;
  DateTime? lastReauthAt;
}

class _StoredNode {
  _StoredNode({
    required this.id,
    required this.boardId,
    required this.ownerId,
    required this.ciphertext,
  });

  final String id;
  final String boardId;
  final String ownerId;
  Ciphertext ciphertext;
}

/// In-memory studio used for tests, CI, and local demo when no Supabase project
/// is configured. Behaviour matches the intended RLS + encryption contracts.
class InMemoryStudio implements AuthRepository, PrivacyRepository {
  InMemoryStudio({
    required List<String> wordlist,
    PayloadCipher? cipher,
    KeyDerivation? derivation,
    SecurityLog? securityLog,
    Uuid? uuid,
    Random? random,
  }) : _wordlist = wordlist,
       _cipher = cipher ?? PayloadCipher(),
       _derivation = derivation ?? KeyDerivation.testing(),
       securityLog = securityLog ?? SecurityLog(),
       _uuid = uuid ?? const Uuid(),
       _random = random ?? Random.secure();

  final List<String> _wordlist;
  final PayloadCipher _cipher;
  final KeyDerivation _derivation;
  final SecurityLog securityLog;
  final Uuid _uuid;
  final Random _random;

  final _accounts = <String, _Account>{};
  final _emailIndex = <String, String>{};
  final _boards = <String, Board>{};
  final _nodes = <String, _StoredNode>{};
  final _consents = <String, List<ConsentEvent>>{};
  final _passwordFailures = <String, int>{};
  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser? _current;
  Uint8List? _sessionDek;
  DateTime? _lastPasswordAttempt;

  @override
  AuthUser? get current => _current;

  Uint8List? get sessionDek => _sessionDek;

  List<String> get wordlist => _wordlist;

  String? debugCipherStorage(String nodeId) => _nodes[nodeId]?.ciphertext.toStorage();

  @override
  String? get pendingRecoveryPhrase {
    final id = _current?.id;
    if (id == null) return null;
    return _accounts[id]?.pendingRecoveryPhrase;
  }

  @override
  Stream<AuthUser?> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  void acknowledgeRecoveryPhrase() {
    final user = _current;
    if (user == null) return;
    _accounts[user.id]?.pendingRecoveryPhrase = null;
    _setCurrent(user.copyWith(needsRecoveryPhraseReveal: false));
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized) || password.length < 12) {
      securityLog.record(type: SecurityEventType.signInFailure, detail: 'password');
      return const Err(InvalidCredentialsFailure());
    }
    if (_isRateLimited()) {
      return const Err(RateLimitedFailure());
    }
    _lastPasswordAttempt = clock.now();
    final id = _emailIndex[normalized];
    final account = id == null ? null : _accounts[id];
    if (account == null || account.passwordHash != _hash(password)) {
      _passwordFailures[normalized] = (_passwordFailures[normalized] ?? 0) + 1;
      securityLog.record(type: SecurityEventType.signInFailure, detail: 'password');
      return const Err(InvalidCredentialsFailure());
    }
    if ((_passwordFailures[normalized] ?? 0) >= 8) {
      return const Err(RateLimitedFailure());
    }
    _passwordFailures[normalized] = 0;
    _sessionDek = account.dek;
    account.lastReauthAt = clock.now().toUtc();
    final user = _toUser(account);
    _setCurrent(user);
    securityLog.record(type: SecurityEventType.signInSuccess, userId: user.id, detail: 'password');
    return Ok(user);
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
    if (_emailIndex.containsKey(normalized)) {
      return const Err(InvalidCredentialsFailure('An account already exists for that email.'));
    }
    final account = await _createAccount(
      email: normalized,
      methods: {AuthMethod.password},
      wrappingSecret: password,
      passwordHash: _hash(password),
    );
    _sessionDek = account.dek;
    account.lastReauthAt = clock.now().toUtc();
    final user = _toUser(account);
    _setCurrent(user);
    await recordConsent(ConsentKind.necessaryStorage, granted: true);
    securityLog.record(type: SecurityEventType.signInSuccess, userId: user.id, detail: 'password-signup');
    return Ok(user);
  }

  @override
  Future<Result<void, AuthFailure>> sendMagicLink({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      return const Err(InvalidCredentialsFailure('Enter a valid email.'));
    }
    final existingId = _emailIndex[normalized];
    final account = existingId == null
        ? await _createAccount(
            email: normalized,
            methods: {AuthMethod.magicLink},
            wrappingSecret: null,
          )
        : _accounts[existingId]!;
    account.methods.add(AuthMethod.magicLink);
    _sessionDek = account.dek;
    final user = _toUser(account, reveal: account.pendingRecoveryPhrase != null);
    _setCurrent(user);
    await recordConsent(ConsentKind.necessaryStorage, granted: true);
    securityLog.record(type: SecurityEventType.signInSuccess, userId: user.id, detail: 'magic-link');
    return const Ok(null);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithGoogle() => _federated(AuthMethod.google, 'google-ada@penumbra.studio');

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithGitHub() => _federated(AuthMethod.github, 'github-ada@penumbra.studio');

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithPasskey() => _federated(AuthMethod.passkey, 'passkey-ada@penumbra.studio');

  @override
  Future<Result<void, AuthFailure>> registerPasskey() async {
    final user = _current;
    if (user == null) return const Err(AuthUnavailableFailure('Sign in first.'));
    _accounts[user.id]?.methods.add(AuthMethod.passkey);
    _setCurrent(_toUser(_accounts[user.id]!));
    return const Ok(null);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> enterDemoStudio() async {
    const email = 'demo@penumbra.studio';
    final existing = _emailIndex[email];
    if (existing != null) {
      final account = _accounts[existing]!;
      _sessionDek = account.dek;
      final user = _toUser(account);
      _setCurrent(user);
      return Ok(user);
    }
    final account = await _createAccount(
      email: email,
      methods: {AuthMethod.password, AuthMethod.passkey},
      wrappingSecret: 'demo-studio-key',
      passwordHash: _hash('demo-studio-key'),
      displayName: 'Ada',
    );
    _sessionDek = account.dek;
    final user = _toUser(account);
    _setCurrent(user);
    await recordConsent(ConsentKind.necessaryStorage, granted: true);
    await create(title: 'Quiet thoughts');
    final boards = (_current == null) ? <Board>[] : _boards.values.where((b) => b.ownerId == _current!.id).toList();
    if (boards.isNotEmpty) {
      final boardId = boards.first.id;
      await upsert(
        BoardNode(
          id: _uuid.v4(),
          boardId: boardId,
          x: 72,
          y: 80,
          kind: NodeKind.text,
          text: 'Private by default.',
        ),
      );
      await upsert(
        BoardNode(
          id: _uuid.v4(),
          boardId: boardId,
          x: 72,
          y: 280,
          kind: NodeKind.text,
          text: 'Accessible by design.',
        ),
      );
      await upsert(
        BoardNode(
          id: _uuid.v4(),
          boardId: boardId,
          x: 600,
          y: 80,
          kind: NodeKind.swatch,
          colorArgb: 0xFF1F4E5A,
        ),
      );
    }
    securityLog.record(type: SecurityEventType.signInSuccess, userId: user.id, detail: 'demo');
    return Ok(user);
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    final id = _current?.id;
    _current = null;
    _sessionDek = null;
    _controller.add(null);
    securityLog.record(type: SecurityEventType.signOut, userId: id);
    return const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> reauthenticate({String? password}) async {
    final user = _current;
    if (user == null) return const Err(AuthUnavailableFailure());
    final account = _accounts[user.id]!;
    if (account.methods.contains(AuthMethod.password)) {
      if (password == null || account.passwordHash != _hash(password)) {
        return const Err(InvalidCredentialsFailure());
      }
    }
    account.lastReauthAt = clock.now().toUtc();
    return const Ok(null);
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    final user = _current;
    if (user == null) return const Err(AuthUnavailableFailure());
    final account = _accounts[user.id]!;
    final reauth = account.lastReauthAt;
    if (reauth == null || clock.now().toUtc().difference(reauth) > const Duration(minutes: 5)) {
      return const Err(AuthUnavailableFailure('Re-authenticate to erase this account.'));
    }
    securityLog.record(type: SecurityEventType.accountErasureRequested, userId: user.id);
    _boards.removeWhere((_, board) => board.ownerId == user.id);
    _nodes.removeWhere((_, node) => node.ownerId == user.id);
    _consents.remove(user.id);
    if (account.email != null) _emailIndex.remove(account.email);
    _accounts.remove(user.id);
    _current = null;
    _sessionDek = null;
    _controller.add(null);
    securityLog.record(type: SecurityEventType.accountErasureCompleted, userId: user.id);
    return const Ok(null);
  }

  Future<Result<List<Board>, AppFailure>> listMine() async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    final mine = _boards.values.where((b) => b.ownerId == user.id).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Ok(mine);
  }

  Future<Result<Board, AppFailure>> getById(String id) async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    final board = _boards[id];
    if (board == null) return const Err(NotFoundFailure('Board not found.'));
    if (board.ownerId != user.id) return const Err(ForbiddenFailure('That board belongs to someone else.'));
    return Ok(board);
  }

  Future<Result<Board, AppFailure>> create({required String title}) async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    final trimmed = title.trim();
    if (trimmed.isEmpty) return const Err(ValidationFailure('Give the board a name.'));
    final board = Board.create(id: _uuid.v4(), ownerId: user.id, title: trimmed);
    _boards[board.id] = board;
    return Ok(board);
  }

  Future<Result<Board, AppFailure>> rename({required String id, required String title}) async {
    final result = await getById(id);
    return result.when(
      ok: (board) {
        if (board.restricted) {
          return const Err(ForbiddenFailure('This board is restricted (Art. 18).'));
        }
        final updated = board.copyWith(title: title.trim(), updatedAt: clock.now().toUtc());
        _boards[id] = updated;
        return Ok(updated);
      },
      err: Err.new,
    );
  }

  Future<Result<void, AppFailure>> delete(String id) async {
    final result = await getById(id);
    return result.when(
      ok: (board) {
        _boards.remove(board.id);
        _nodes.removeWhere((_, node) => node.boardId == board.id);
        return const Ok(null);
      },
      err: Err.new,
    );
  }

  Future<Result<Board, AppFailure>> setRestricted({required String id, required bool restricted}) async {
    final result = await getById(id);
    return result.when(
      ok: (board) {
        final updated = board.copyWith(restricted: restricted, updatedAt: clock.now().toUtc());
        _boards[id] = updated;
        securityLog.record(
          type: SecurityEventType.boardRestricted,
          userId: board.ownerId,
          detail: restricted ? 'restricted' : 'unrestricted',
        );
        return Ok(updated);
      },
      err: Err.new,
    );
  }

  Future<Result<List<BoardNode>, AppFailure>> listNodes(String boardId) async {
    final dek = _sessionDek;
    if (dek == null) return const Err(UnauthenticatedFailure());
    switch (await getById(boardId)) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        final out = <BoardNode>[];
        for (final stored in _nodes.values.where((n) => n.boardId == boardId)) {
          switch (await _cipher.decrypt(dekBytes: dek, ciphertext: stored.ciphertext)) {
            case Err():
              continue;
            case Ok(:final value):
              final decoded = json.decode(utf8.decode(value));
              if (decoded is! Map) continue;
              out.add(
                BoardNode.fromPayload(
                  id: stored.id,
                  boardId: boardId,
                  payload: decoded.map((k, v) => MapEntry(k.toString(), v)),
                ),
              );
          }
        }
        return Ok(out);
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
          return const Err(ForbiddenFailure('This board is restricted (Art. 18).'));
        }
        final siblings = await _decryptedSiblings(boardId: node.boardId, dek: dek, exceptId: node.id);
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
            _nodes[node.id] = _StoredNode(
              id: node.id,
              boardId: node.boardId,
              ownerId: user.id,
              ciphertext: value,
            );
            _boards[board.id] = board.copyWith(updatedAt: clock.now().toUtc());
            return Ok(node);
        }
    }
  }

  Future<Result<void, AppFailure>> deleteNode(String nodeId) async {
    final stored = _nodes[nodeId];
    if (stored == null) return const Err(NotFoundFailure('Card not found.'));
    final dek = _sessionDek;
    if (dek == null) return const Err(UnauthenticatedFailure());
    final board = await getById(stored.boardId);
    switch (board) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        final cascade = <String>{nodeId};
        for (final other in _nodes.values.where((n) => n.boardId == stored.boardId && n.id != nodeId)) {
          switch (await _cipher.decrypt(dekBytes: dek, ciphertext: other.ciphertext)) {
            case Err():
              continue;
            case Ok(:final value):
              final decoded = json.decode(utf8.decode(value));
              if (decoded is Map && decoded['parentId'] == nodeId) {
                cascade.add(other.id);
              }
          }
        }
        for (final id in cascade) {
          _nodes.remove(id);
        }
        return const Ok(null);
    }
  }

  Future<List<BoardNode>> _decryptedSiblings({
    required String boardId,
    required Uint8List dek,
    required String exceptId,
  }) async {
    final out = <BoardNode>[];
    for (final stored in _nodes.values.where((n) => n.boardId == boardId && n.id != exceptId)) {
      switch (await _cipher.decrypt(dekBytes: dek, ciphertext: stored.ciphertext)) {
        case Err():
          continue;
        case Ok(:final value):
          final decoded = json.decode(utf8.decode(value));
          if (decoded is! Map) continue;
          out.add(
            BoardNode.fromPayload(
              id: stored.id,
              boardId: boardId,
              payload: decoded.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
      }
    }
    return out;
  }

  @override
  Future<Result<List<ConsentEvent>, AppFailure>> consents() async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    return Ok(List.unmodifiable(_consents[user.id] ?? const []));
  }

  @override
  Future<Result<ConsentEvent, AppFailure>> recordConsent(ConsentKind kind, {required bool granted}) async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    final event = ConsentEvent(
      id: _uuid.v4(),
      userId: user.id,
      kind: kind,
      granted: granted,
      at: clock.now().toUtc(),
    );
    _consents.putIfAbsent(user.id, () => []).add(event);
    return Ok(event);
  }

  @override
  Future<Result<PrivacyExport, AppFailure>> exportMine() async {
    final user = _requireUser();
    if (user == null) return const Err(UnauthenticatedFailure());
    securityLog.record(type: SecurityEventType.exportRequested, userId: user.id);
    final boards = _boards.values.where((b) => b.ownerId == user.id).toList();
    final nodes = <Map<String, Object?>>[];
    for (final board in boards) {
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
          for (final board in boards)
            {
              'id': board.id,
              'title': board.title,
              'updatedAt': board.updatedAt.toIso8601String(),
              'restricted': board.restricted,
            },
        ],
        nodes: nodes,
        consents: [
          for (final c in _consents[user.id] ?? const <ConsentEvent>[])
            {
              'id': c.id,
              'kind': c.kind.name,
              'granted': c.granted,
              'at': c.at.toIso8601String(),
            },
        ],
      ),
    );
  }

  @override
  Future<Result<void, AppFailure>> eraseAccount({String? password}) async {
    final reauth = await reauthenticate(password: password);
    return reauth.when(
      ok: (_) async {
        final deleted = await deleteAccount();
        return deleted.when(ok: (_) => const Ok(null), err: (f) => Err(UnavailableFailure(f.message)));
      },
      err: (f) async => Err(UnauthenticatedFailure(f.message)),
    );
  }

  Future<Result<AuthUser, AuthFailure>> _federated(AuthMethod method, String email) async {
    final existing = _emailIndex[email];
    final isNew = existing == null;
    final account = existing == null
        ? await _createAccount(email: email, methods: {method}, wrappingSecret: null)
        : _accounts[existing]!;
    account.methods.add(method);
    _sessionDek = account.dek;
    account.lastReauthAt = clock.now().toUtc();
    final user = _toUser(account, reveal: isNew || account.pendingRecoveryPhrase != null);
    _setCurrent(user);
    await recordConsent(ConsentKind.necessaryStorage, granted: true);
    securityLog.record(type: SecurityEventType.signInSuccess, userId: user.id, detail: method.name);
    return Ok(user);
  }

  Future<_Account> _createAccount({
    required String email,
    required Set<AuthMethod> methods,
    required String? wrappingSecret,
    String? passwordHash,
    String? displayName,
  }) async {
    final dek = Uint8List.fromList(List<int>.generate(32, (_) => _random.nextInt(256)));
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => _random.nextInt(256)));
    String secret = wrappingSecret ?? '';
    String? phrase;
    if (secret.isEmpty) {
      final entropy = Uint8List.fromList(List<int>.generate(16, (_) => _random.nextInt(256)));
      final generated = RecoveryPhrase.fromEntropy(entropy: entropy, wordlist: _wordlist).when(
        ok: (p) => p.display,
        err: (_) => base64Url.encode(entropy),
      );
      phrase = generated;
      secret = generated;
    }
    final wrapping = await _derivation.deriveWrappingKey(secret: secret, salt: salt);
    final wrapKey = wrapping.when(ok: (bytes) => bytes, err: (_) => dek);
    final wrapped = await _cipher.encrypt(dekBytes: wrapKey, plaintext: dek);
    final wrappedCipher = wrapped.when(
      ok: (c) => c,
      err: (_) => Ciphertext(nonce: Uint8List(12), cipherBytes: dek, mac: Uint8List(16)),
    );
    final account = _Account(
      id: _uuid.v4(),
      email: email,
      methods: {...methods},
      dek: dek,
      wrapSalt: salt,
      wrappedDek: wrappedCipher,
      passwordHash: passwordHash,
      displayName: displayName,
    );
    account.pendingRecoveryPhrase = phrase;
    _accounts[account.id] = account;
    _emailIndex[email] = account.id;
    return account;
  }

  AuthUser _toUser(_Account account, {bool reveal = false}) {
    return AuthUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      methods: {...account.methods},
      needsRecoveryPhraseReveal: reveal && account.pendingRecoveryPhrase != null,
    );
  }

  void _setCurrent(AuthUser user) {
    _current = user;
    _controller.add(user);
  }

  AuthUser? _requireUser() => _current;

  bool _validEmail(String email) => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);

  bool _isRateLimited() {
    final last = _lastPasswordAttempt;
    if (last == null) return false;
    return clock.now().difference(last) < const Duration(milliseconds: 20) && _passwordFailures.length > 20;
  }

  String _hash(String password) {
    // Demo-only digest. Production wraps the DEK with Argon2id; this hash is
    // solely an equality check for the in-memory password path.
    return base64Url.encode(utf8.encode('penumbra:$password'));
  }
}
