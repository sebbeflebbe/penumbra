import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'core/config.dart';
import 'core/crypto/wordlist.dart';
import 'features/canvas/domain/echo_composer.dart';
import 'features/studio/in_memory_studio.dart';
import 'features/studio/prefs_device_store.dart';
import 'features/studio/studio_repositories.dart';
import 'features/studio/supabase_studio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
    usePathUrlStrategy();
  }

  final wordlist = await Bip39Wordlist.load();
  final config = PenumbraConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();
  final deviceStore = PrefsDeviceStore(prefs);
  final savedAppearance = appearanceFromName(
    deviceStore.read(AppearanceController.storageKey),
  );
  var echoPrompt = kPenumbraEchoSystemPrompt;
  try {
    echoPrompt = await rootBundle.loadString(
      'assets/prompts/penumbra_echo.txt',
    );
  } catch (_) {
    // Asset missing in a stripped test bind — keep the in-code fallback.
  }

  final overrides = <Override>[
    configProvider.overrideWithValue(config),
    echoPromptProvider.overrideWithValue(echoPrompt),
    appearanceProvider.overrideWith(
      (ref) =>
          AppearanceController(store: deviceStore, initial: savedAppearance),
    ),
  ];

  switch (config.studioMode) {
    case StudioMode.memory:
      overrides.add(
        studioProvider.overrideWithValue(
          InMemoryStudio(wordlist: wordlist.words),
        ),
      );
    case StudioMode.supabase:
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
      );
      final remote = SupabaseStudio(
        client: Supabase.instance.client,
        wordlist: wordlist.words,
        store: deviceStore,
        redirectTo: kIsWeb ? Uri.base.origin : config.productionOrigin,
      );
      overrides.addAll([
        authRepositoryProvider.overrideWithValue(remote),
        boardRepositoryProvider.overrideWithValue(
          SupabaseBoardRepository(remote),
        ),
        canvasRepositoryProvider.overrideWithValue(
          SupabaseCanvasRepository(remote),
        ),
        privacyRepositoryProvider.overrideWithValue(remote),
      ]);
  }

  runApp(ProviderScope(overrides: overrides, child: const PenumbraApp()));
}
