import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/app/providers.dart';
import 'package:penumbra/app/theme.dart';
import 'package:penumbra/features/studio/device_store.dart';

void main() {
  test('appearance names are spoken, not raw enum values', () {
    expect(PenumbraAppearance.system.spokenName, 'System');
    expect(PenumbraAppearance.light.spokenName, 'Light');
    expect(PenumbraAppearance.dark.spokenName, 'Dark');
    expect(PenumbraAppearance.highContrast.spokenName, 'High contrast');
    expect(appearanceFromName('dark'), PenumbraAppearance.dark);
    expect(appearanceFromName('nope'), PenumbraAppearance.system);
  });

  test('cycling appearance persists to the device store', () async {
    final store = MemoryDeviceStore();
    final controller = AppearanceController(store: store);
    controller.cycle();
    await Future<void>.delayed(Duration.zero);
    expect(
      store.read(AppearanceController.storageKey),
      PenumbraAppearance.light.name,
    );
    controller.set(PenumbraAppearance.highContrast);
    await Future<void>.delayed(Duration.zero);
    expect(store.read(AppearanceController.storageKey), 'highContrast');
  });

  test('toggling locale persists to the device store', () async {
    final store = MemoryDeviceStore();
    final controller = LocaleController(store: store);
    expect(controller.state.languageCode, 'en');
    controller.toggle();
    await Future<void>.delayed(Duration.zero);
    expect(store.read(LocaleController.storageKey), 'sv');
    expect(controller.state.languageCode, 'sv');
    controller.set(const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    expect(store.read(LocaleController.storageKey), 'en');
  });
}
