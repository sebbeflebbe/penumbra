import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/chrome.dart';
import '../domain/auth_models.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _info;
  String? _busyId;
  bool _passwordOpen = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _busy => _busyId != null;

  Future<void> _run(
    String id,
    Future<AuthFailure?> Function() action, {
    String? success,
  }) async {
    setState(() {
      _busyId = id;
      _error = null;
      _info = null;
    });
    final failure = await action();
    if (!mounted) return;
    setState(() {
      _busyId = null;
      if (failure != null) {
        _error = failure.message;
      } else {
        _info = success;
        if (ref.read(authControllerProvider).value != null) {
          context.go('/boards');
        }
      }
    });
  }

  Widget _prefix(String id, Widget idle) {
    if (_busyId == id) {
      return const SizedBox(width: 16, height: 16, child: FCircularProgress());
    }
    return idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final swedish = Localizations.localeOf(context).languageCode == 'sv';
    final bankIdButton = FButton(
      variant: swedish ? FButtonVariant.primary : FButtonVariant.outline,
      onPress: _busy
          ? null
          : () => _run(
              'bankid',
              () => ref.read(authControllerProvider.notifier).bankId(),
            ),
      prefix: _prefix('bankid', const Icon(FLucideIcons.smartphone)),
      child: Text(l10n.continueBankId),
    ).penumbraEnter(context, delayMs: swedish ? 80 : 95);
    return PenumbraChrome(
      title: l10n.signInTitle,
      child: PenumbraPage(
        maxWidth: 560,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colors.border),
              boxShadow: [
                BoxShadow(
                  color: theme.colors.foreground.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.signInHeadline,
                      style: theme.typography.xl3.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ).penumbraEnter(context),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signInLede,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        height: 1.45,
                      ),
                    ).penumbraEnter(context, delayMs: 40),
                    const SizedBox(height: 28),
                    if (_error != null) ...[
                      FAlert(
                        variant: FAlertVariant.destructive,
                        title: Text(_error!),
                      ).penumbraEnter(context),
                      const SizedBox(height: 16),
                    ],
                    if (_info != null) ...[
                      FAlert(title: Text(_info!)).penumbraEnter(context),
                      const SizedBox(height: 16),
                    ],
                    if (swedish) ...[
                      bankIdButton,
                      const SizedBox(height: 10),
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: _busy
                            ? null
                            : () => _run(
                                'passkey',
                                () => ref
                                    .read(authControllerProvider.notifier)
                                    .passkey(),
                              ),
                        prefix: _prefix(
                          'passkey',
                          const Icon(FLucideIcons.fingerprint),
                        ),
                        child: Text(l10n.continuePasskey),
                      ).penumbraEnter(context, delayMs: 95),
                    ] else ...[
                      FButton(
                        onPress: _busy
                            ? null
                            : () => _run(
                                'passkey',
                                () => ref
                                    .read(authControllerProvider.notifier)
                                    .passkey(),
                              ),
                        prefix: _prefix(
                          'passkey',
                          const Icon(FLucideIcons.fingerprint),
                        ),
                        child: Text(l10n.continuePasskey),
                      ).penumbraEnter(context, delayMs: 80),
                      const SizedBox(height: 10),
                      bankIdButton,
                    ],
                    const SizedBox(height: 10),
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _busy
                          ? null
                          : () => _run(
                              'google',
                              () => ref
                                  .read(authControllerProvider.notifier)
                                  .google(),
                            ),
                      prefix: _prefix('google', const Icon(FLucideIcons.globe)),
                      child: Text(l10n.continueGoogle),
                    ).penumbraEnter(context, delayMs: 110),
                    const SizedBox(height: 10),
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _busy
                          ? null
                          : () => _run(
                              'github',
                              () => ref
                                  .read(authControllerProvider.notifier)
                                  .github(),
                            ),
                      prefix: _prefix('github', const Icon(FLucideIcons.code)),
                      child: Text(l10n.continueGitHub),
                    ).penumbraEnter(context, delayMs: 140),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: FDivider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.orDivider,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        const Expanded(child: FDivider()),
                      ],
                    ).penumbraEnter(context, delayMs: 160),
                    const SizedBox(height: 24),
                    FTextField.email(
                      control: FTextFieldControl.managed(controller: _email),
                      description: Text(l10n.emailRestoreHint),
                    ).penumbraEnter(context, delayMs: 180),
                    const SizedBox(height: 12),
                    FButton(
                      variant: FButtonVariant.ghost,
                      onPress: _busy
                          ? null
                          : () async {
                              setState(() => _busyId = 'magic');
                              final failure = await ref
                                  .read(authControllerProvider.notifier)
                                  .magicLink(_email.text);
                              if (!mounted) return;
                              final signedIn =
                                  ref.read(authControllerProvider).value !=
                                  null;
                              setState(() {
                                _busyId = null;
                                _error = failure?.message;
                                _info = failure == null
                                    ? (signedIn
                                          ? l10n.magicLinkDemo
                                          : l10n.magicLinkEmail)
                                    : null;
                              });
                              if (!context.mounted) return;
                              if (failure == null && signedIn) {
                                context.go('/boards');
                              }
                            },
                      prefix: _prefix('magic', const Icon(FLucideIcons.mail)),
                      child: Text(l10n.emailMagicLink),
                    ).penumbraEnter(context, delayMs: 200),
                    const SizedBox(height: 8),
                    FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () =>
                          setState(() => _passwordOpen = !_passwordOpen),
                      child: Text(
                        _passwordOpen
                            ? l10n.hidePassword
                            : l10n.usePasswordInstead,
                      ),
                    ).penumbraEnter(context, delayMs: 220),
                    if (_passwordOpen) ...[
                      const SizedBox(height: 12),
                      FTextField(
                        label: Text(l10n.passwordLabel),
                        obscureText: true,
                        control: FTextFieldControl.managed(
                          controller: _password,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FButton(
                        variant: FButtonVariant.secondary,
                        onPress: _busy
                            ? null
                            : () => _run(
                                'password',
                                () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInPassword(
                                      _email.text,
                                      _password.text,
                                    ),
                              ),
                        prefix: _prefix('password', const SizedBox.shrink()),
                        child: Text(l10n.signInWithPassword),
                      ),
                      const SizedBox(height: 8),
                      FButton(
                        variant: FButtonVariant.ghost,
                        onPress: _busy
                            ? null
                            : () => _run(
                                'signup',
                                () => ref
                                    .read(authControllerProvider.notifier)
                                    .signUpPassword(
                                      _email.text,
                                      _password.text,
                                    ),
                              ),
                        child: Text(l10n.createAccount),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.visibleOnlyToYou,
                      textAlign: TextAlign.center,
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                        fontFamily: PenumbraInk.displayFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
