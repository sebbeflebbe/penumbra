import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/result.dart';
import 'package:penumbra/features/auth/domain/auth_models.dart';
import 'package:penumbra/features/auth/domain/eid.dart';
import 'package:penumbra/features/studio/in_memory_studio.dart';

import '../../helpers/pump_studio.dart';

class _UnavailableBankIdStudio extends InMemoryStudio {
  _UnavailableBankIdStudio()
    : super(
        wordlist: File('assets/crypto/bip39_english.txt').readAsLinesSync(),
      );

  @override
  Future<Result<AuthUser, AuthFailure>> signInWithBankId() async {
    return Err(bankIdUnavailable(configured: false));
  }
}

void main() {
  testWidgets('locale toggle updates chrome to Swedish', (tester) async {
    await pumpStudio(tester, memoryStudio());
    expect(
      find.bySemanticsLabel('Language: English. Switch to Swedish.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Svenska'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tillkomst'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Språk: svenska. Byt till engelska.'),
      findsOneWidget,
    );
  });

  testWidgets('English sign-in leads with passkey then BankID', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Sign in').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final passkey = tester.getTopLeft(find.text('Continue with a passkey'));
    final bankId = tester.getTopLeft(find.text('Continue with BankID'));
    expect(passkey.dy, lessThan(bankId.dy));
  });

  testWidgets('Swedish sign-in leads with BankID then passkey', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Svenska'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Logga in').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final bankId = tester.getTopLeft(find.text('Fortsätt med BankID'));
    final passkey = tester.getTopLeft(find.text('Fortsätt med en passnyckel'));
    expect(bankId.dy, lessThan(passkey.dy));
  });

  testWidgets('BankID unavailable copy when the cloud ceremony is absent', (
    tester,
  ) async {
    await pumpStudio(tester, _UnavailableBankIdStudio());
    await tester.tap(find.text('Sign in').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Continue with BankID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('BankID is not configured on this deployment'),
      findsOneWidget,
    );
  });

  testWidgets('Privacy lists a security event after demo sign-in', (
    tester,
  ) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Privacy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('Security events'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Security events'), findsOneWidget);
    expect(find.textContaining('signInSuccess'), findsWidgets);
  });
}
