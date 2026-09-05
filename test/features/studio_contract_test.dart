import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/errors.dart';
import 'package:penumbra/features/auth/domain/auth_models.dart';
import 'package:penumbra/features/boards/domain/board.dart';
import 'package:penumbra/features/privacy/domain/privacy_models.dart';
import 'package:penumbra/features/studio/in_memory_studio.dart';
import 'package:penumbra/features/studio/studio_repositories.dart';
import 'package:uuid/uuid.dart';

void main() {
  late InMemoryStudio studio;
  late InMemoryBoardRepository boards;
  late InMemoryCanvasRepository canvas;

  setUp(() async {
    studio = InMemoryStudio(
      wordlist: File('assets/crypto/bip39_english.txt').readAsLinesSync(),
    );
    boards = InMemoryBoardRepository(studio);
    canvas = InMemoryCanvasRepository(studio);
  });

  test(
    'password sign-up rejects short secrets and accepts a 12-character secret',
    () async {
      final short = await studio.signUpWithPassword(
        email: 'ada@penumbra.studio',
        password: 'short',
      );
      expect(short.errOrNull, isA<WeakSecretFailure>());

      final ok = await studio.signUpWithPassword(
        email: 'ada@penumbra.studio',
        password: 'long-enough-1',
      );
      expect(ok.okOrNull?.email, 'ada@penumbra.studio');
      expect(ok.okOrNull?.methods, contains(AuthMethod.password));
    },
  );

  test(
    'passkey, Google, GitHub and magic link all establish a session',
    () async {
      expect((await studio.signInWithPasskey()).isOk, isTrue);
      await studio.signOut();
      expect((await studio.signInWithGoogle()).isOk, isTrue);
      await studio.signOut();
      expect((await studio.signInWithGitHub()).isOk, isTrue);
      await studio.signOut();
      expect(
        (await studio.sendMagicLink(email: 'link@penumbra.studio')).isOk,
        isTrue,
      );
      expect(studio.current?.email, 'link@penumbra.studio');
    },
  );

  test('OAuth users receive a 12-word recovery phrase once', () async {
    final user = (await studio.signInWithGitHub()).okOrNull!;
    expect(user.needsRecoveryPhraseReveal, isTrue);
    expect(studio.pendingRecoveryPhrase!.split(' '), hasLength(12));
    studio.acknowledgeRecoveryPhrase();
    expect(studio.current?.needsRecoveryPhraseReveal, isFalse);
  });

  test('boards are isolated between users (RLS contract)', () async {
    await studio.signUpWithPassword(
      email: 'ada@penumbra.studio',
      password: 'long-enough-1',
    );
    final board = (await boards.create(title: 'Ada only')).okOrNull!;

    await studio.signOut();
    await studio.signUpWithPassword(
      email: 'grace@penumbra.studio',
      password: 'long-enough-2',
    );
    final stolen = await boards.getById(board.id);
    expect(stolen.errOrNull, isA<ForbiddenFailure>());
    expect((await boards.listMine()).okOrNull, isEmpty);
  });

  test('node payloads are stored encrypted', () async {
    await studio.enterDemoStudio();
    final board = (await boards.listMine()).okOrNull!.first;
    final node = BoardNode(
      id: const Uuid().v4(),
      boardId: board.id,
      x: 12,
      y: 40,
      kind: NodeKind.text,
      text: 'plaintext-must-not-persist',
    );
    expect((await canvas.upsert(node)).isOk, isTrue);
    final stored = studio.debugCipherStorage(node.id)!;
    expect(stored.contains('plaintext-must-not-persist'), isFalse);
    final loaded = (await canvas.listNodes(board.id)).okOrNull!;
    expect(
      loaded.where((n) => n.id == node.id).single.text,
      'plaintext-must-not-persist',
    );
  });

  test(
    'echo payloads are stored encrypted and a second summon is refused',
    () async {
      await studio.enterDemoStudio();
      final board = (await boards.listMine()).okOrNull!.first;
      final nodes = (await canvas.listNodes(board.id)).okOrNull!;
      final parent = nodes.firstWhere((n) => n.kind == NodeKind.text);
      final echo = BoardNode(
        id: const Uuid().v4(),
        boardId: board.id,
        x: parent.x + 28,
        y: parent.y + 36,
        kind: NodeKind.echo,
        text: 'echo-plaintext-must-not-persist',
        parentId: parent.id,
      );
      expect((await canvas.upsert(echo)).isOk, isTrue);
      final stored = studio.debugCipherStorage(echo.id)!;
      expect(stored.contains('echo-plaintext-must-not-persist'), isFalse);
      final loaded = (await canvas.listNodes(board.id)).okOrNull!;
      expect(
        loaded.where((n) => n.id == echo.id).single.text,
        'echo-plaintext-must-not-persist',
      );
      expect(loaded.where((n) => n.id == echo.id).single.parentId, parent.id);

      final second = BoardNode(
        id: const Uuid().v4(),
        boardId: board.id,
        x: parent.x + 40,
        y: parent.y + 40,
        kind: NodeKind.echo,
        text: 'another',
        parentId: parent.id,
      );
      expect((await canvas.upsert(second)).errOrNull, isA<ValidationFailure>());

      expect((await canvas.delete(echo.id)).isOk, isTrue);
      expect((await canvas.upsert(second)).isOk, isTrue);
    },
  );

  test(
    'export contains the user data and erasure removes it after re-auth',
    () async {
      await studio.signUpWithPassword(
        email: 'ada@penumbra.studio',
        password: 'long-enough-1',
      );
      await boards.create(title: 'Keep');
      final exported = (await studio.exportMine()).okOrNull!;
      expect(exported.boards, isNotEmpty);
      expect(exported.profile['email'], 'ada@penumbra.studio');

      expect(
        (await studio.eraseAccount(password: 'wrong-password')).isErr,
        isTrue,
      );
      expect(
        (await studio.eraseAccount(password: 'long-enough-1')).isOk,
        isTrue,
      );
      expect(studio.current, isNull);
      await studio.signUpWithPassword(
        email: 'ada@penumbra.studio',
        password: 'long-enough-1',
      );
      expect((await boards.listMine()).okOrNull, isEmpty);
    },
  );

  test('restricted boards refuse writes (Art. 18)', () async {
    await studio.enterDemoStudio();
    final board = (await boards.listMine()).okOrNull!.first;
    await boards.setRestricted(id: board.id, restricted: true);
    final write = await canvas.upsert(
      BoardNode(
        id: 'n1',
        boardId: board.id,
        x: 0,
        y: 0,
        kind: NodeKind.text,
        text: 'nope',
      ),
    );
    expect(write.errOrNull, isA<ForbiddenFailure>());
    final existing = (await canvas.listNodes(board.id)).okOrNull!.first;
    expect(
      (await canvas.delete(existing.id)).errOrNull,
      isA<ForbiddenFailure>(),
    );
  });

  test('deleting a human slip cascades its encrypted echo', () async {
    await studio.enterDemoStudio();
    final board = (await boards.listMine()).okOrNull!.first;
    final parent = (await canvas.listNodes(
      board.id,
    )).okOrNull!.firstWhere((n) => n.kind == NodeKind.text);
    final echo = BoardNode(
      id: const Uuid().v4(),
      boardId: board.id,
      x: parent.x + 28,
      y: parent.y + 36,
      kind: NodeKind.echo,
      text: 'cascade-echo-plaintext',
      parentId: parent.id,
    );
    expect((await canvas.upsert(echo)).isOk, isTrue);
    expect(studio.debugCipherStorage(echo.id), isNotNull);
    expect((await canvas.delete(parent.id)).isOk, isTrue);
    expect(studio.debugCipherStorage(parent.id), isNull);
    expect(studio.debugCipherStorage(echo.id), isNull);
    final left = (await canvas.listNodes(board.id)).okOrNull!;
    expect(left.where((n) => n.id == parent.id || n.id == echo.id), isEmpty);
  });

  test('remote echo consent is recorded and exported', () async {
    await studio.signUpWithPassword(
      email: 'ada@penumbra.studio',
      password: 'long-enough-1',
    );
    expect(
      hasGrantedConsent(
        (await studio.consents()).okOrNull!,
        ConsentKind.remoteEcho,
      ),
      isFalse,
    );
    expect(
      (await studio.recordConsent(ConsentKind.remoteEcho, granted: true)).isOk,
      isTrue,
    );
    expect(
      hasGrantedConsent(
        (await studio.consents()).okOrNull!,
        ConsentKind.remoteEcho,
      ),
      isTrue,
    );
    final exported = (await studio.exportMine()).okOrNull!;
    expect(
      exported.consents.any(
        (row) => row['kind'] == 'remoteEcho' && row['granted'] == true,
      ),
      isTrue,
    );
  });
}
