import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/result.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/boards/domain/board_repository.dart';
import '../features/canvas/domain/canvas_repository.dart';
import '../features/canvas/domain/echo_composer.dart';
import '../features/privacy/domain/privacy_repository.dart';
import '../features/studio/device_store.dart';
import '../features/studio/in_memory_studio.dart';
import '../features/studio/studio_repositories.dart';
import 'theme.dart';

final configProvider = Provider<PenumbraConfig>(
  (ref) => PenumbraConfig.fromEnvironment(),
);

final studioProvider = Provider<InMemoryStudio>((ref) {
  throw StateError('studioProvider must be overridden in bootstrap.');
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(studioProvider),
);

final boardRepositoryProvider = Provider<BoardRepository>(
  (ref) => InMemoryBoardRepository(ref.watch(studioProvider)),
);

final canvasRepositoryProvider = Provider<CanvasRepository>(
  (ref) => InMemoryCanvasRepository(ref.watch(studioProvider)),
);

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => ref.watch(studioProvider),
);

final echoPromptProvider = Provider<String>((ref) => kPenumbraEchoSystemPrompt);

final echoComposerProvider = Provider<EchoComposer>((ref) {
  return penumbraEchoComposer(
    geminiApiKey: ref.watch(configProvider).geminiApiKey,
    systemPrompt: ref.watch(echoPromptProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._auth) : super(AsyncValue.data(_auth.current)) {
    _auth.watch().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  final AuthRepository _auth;

  Future<AuthFailure?> signInPassword(String email, String password) =>
      _unwrap(_auth.signInWithPassword(email: email, password: password));

  Future<AuthFailure?> signUpPassword(String email, String password) =>
      _unwrap(_auth.signUpWithPassword(email: email, password: password));

  Future<AuthFailure?> magicLink(String email) async =>
      (await _auth.sendMagicLink(email: email)).errOrNull;

  Future<AuthFailure?> google() => _unwrap(_auth.signInWithGoogle());
  Future<AuthFailure?> github() => _unwrap(_auth.signInWithGitHub());
  Future<AuthFailure?> passkey() => _unwrap(_auth.signInWithPasskey());
  Future<AuthFailure?> demo() => _unwrap(_auth.enterDemoStudio());

  Future<void> signOut() => _auth.signOut();

  Future<AuthFailure?> _unwrap(
    Future<Result<AuthUser, AuthFailure>> future,
  ) async {
    return (await future).errOrNull;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AppearanceController extends StateNotifier<PenumbraAppearance> {
  AppearanceController({
    DeviceStore? store,
    PenumbraAppearance initial = PenumbraAppearance.system,
  }) : _store = store ?? MemoryDeviceStore(),
       super(initial);

  static const storageKey = 'penumbra.appearance';

  final DeviceStore _store;

  void cycle() => set(state.next);

  void set(PenumbraAppearance value) {
    state = value;
    unawaited(_store.write(storageKey, value.name));
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceController, PenumbraAppearance>(
      (ref) => AppearanceController(),
    );
