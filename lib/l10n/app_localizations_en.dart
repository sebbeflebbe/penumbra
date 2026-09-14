// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwedish => 'Svenska';

  @override
  String get languageSwitchToEnglish => 'Language: Swedish. Switch to English.';

  @override
  String get languageSwitchToSwedish => 'Language: English. Switch to Swedish.';

  @override
  String get languageAnnouncedEnglish => 'Language: English.';

  @override
  String get languageAnnouncedSwedish => 'Language: Swedish.';

  @override
  String get navMakingOf => 'Making of';

  @override
  String get navLegal => 'Legal';

  @override
  String get navBoards => 'Boards';

  @override
  String get navPrivacy => 'Privacy';

  @override
  String get navSignIn => 'Sign in';

  @override
  String get navSignOut => 'Sign out';

  @override
  String get navHome => 'Penumbra home';

  @override
  String get navMenu => 'Open menu';

  @override
  String get skipToContent => 'Skip to content';

  @override
  String get mainContent => 'Main content';

  @override
  String appearanceSemantics(String current, String next) {
    return 'Appearance: $current. Switch to $next.';
  }

  @override
  String appearanceAnnounced(String name) {
    return 'Appearance: $name';
  }

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceHighContrast => 'High contrast';

  @override
  String get landingHeadline => 'A quiet studio for thinking in space.';

  @override
  String get landingLede =>
      'A spatial notebook for thoughts that aren\'t ready to leave the room. Notes stay encrypted in the browser; you hold the key. The studio is yours alone.';

  @override
  String get enterStudio => 'Enter the studio';

  @override
  String get readMakingOf => 'Read the making of';

  @override
  String get factPrivateTitle => 'Private by default';

  @override
  String get factPrivateBody =>
      'Board bodies are encrypted in the browser before they touch a server.';

  @override
  String get factA11yTitle => 'Accessible by design';

  @override
  String get factA11yBody =>
      'The canvas has a document order, names, and a high-contrast theme.';

  @override
  String get factLegalTitle => 'Legally operable';

  @override
  String get factLegalBody =>
      'GDPR rights, an SBOM, and an honest “we are not CE-marked” note.';

  @override
  String get teaserPrivate => 'Private by default.';

  @override
  String get teaserAccessible => 'Accessible by design.';

  @override
  String get teaserSwatch => 'Colour swatch';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInHeadline => 'Enter the half-light.';

  @override
  String get signInLede =>
      'Passkeys are preferred. Passwords are the weakest path and must be at least 12 characters.';

  @override
  String get continuePasskey => 'Continue with a passkey';

  @override
  String get continueBankId => 'Continue with BankID';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueGitHub => 'Continue with GitHub';

  @override
  String get orDivider => 'or';

  @override
  String get emailRestoreHint => 'Used only to restore your studio.';

  @override
  String get emailMagicLink => 'Email me a magic link';

  @override
  String get magicLinkDemo =>
      'Magic link sent (in this demo the session is opened immediately).';

  @override
  String get magicLinkEmail =>
      'Check your email for a link. Keep this tab open.';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get usePasswordInstead => 'Use a password instead';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInWithPassword => 'Sign in with password';

  @override
  String get createAccount => 'Create an account';

  @override
  String get visibleOnlyToYou => 'Visible only to you.';

  @override
  String get unlockTitle => 'Unlock this studio';

  @override
  String get unlockBody =>
      'This device does not have the wrapping key. Enter the twelve-word recovery phrase shown when you first signed in.';

  @override
  String get recoveryPhraseLabel => 'Recovery phrase';

  @override
  String get recoveryPhraseHint => 'Twelve words, in order.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockSemantics => 'Unlock with recovery phrase';

  @override
  String get notesUnlocked => 'Notes unlocked.';

  @override
  String get boardsTitle => 'Boards';

  @override
  String get boardsLede =>
      'Each board is yours alone. Titles are metadata; the cards inside are ciphertext.';

  @override
  String get newBoard => 'New board';

  @override
  String get newBoardHint => 'Quiet thoughts';

  @override
  String get create => 'Create';

  @override
  String get open => 'Open';

  @override
  String get rename => 'Rename';

  @override
  String get restrict => 'Restrict';

  @override
  String get unrestrict => 'Unrestrict';

  @override
  String get delete => 'Delete';

  @override
  String get renameDialogTitle => 'Rename this board';

  @override
  String get titleLabel => 'Title';

  @override
  String get saveTitle => 'Save title';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteBoardTitle => 'Delete this board';

  @override
  String get deleteBoardBody =>
      'The board and its cards will be removed. This cannot be undone.';

  @override
  String get deleteThisBoard => 'Delete this board';

  @override
  String get keepIt => 'Keep it';

  @override
  String get emptyBoards =>
      'Nothing here yet. Name a board, or enter the demo studio from home.';

  @override
  String openBoard(String title) {
    return 'Open $title';
  }

  @override
  String renameBoard(String title) {
    return 'Rename $title';
  }

  @override
  String restrictBoard(String title) {
    return 'Restrict $title';
  }

  @override
  String unrestrictBoard(String title) {
    return 'Unrestrict $title';
  }

  @override
  String deleteBoard(String title) {
    return 'Delete $title';
  }

  @override
  String get composeHint => 'A thought, privately held';

  @override
  String get place => 'Place';

  @override
  String get swatch => 'Swatch';

  @override
  String get summonEcho => 'Summon an echo';

  @override
  String get index => 'Index';

  @override
  String get indexHint =>
      'A conversation. Arrow keys or Move reposition the selected slip.';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get move => 'Move';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get yourRights => 'Your rights';

  @override
  String controllerLine(String name, String email) {
    return 'Controller: $name. Contact: $email. Age: 16+. Necessary storage only — no marketing cookies.';
  }

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'Art. 16 rectification. Optional.';

  @override
  String get saveDisplayName => 'Save display name';

  @override
  String get passwordToErase => 'Password to erase';

  @override
  String get passwordToEraseHint =>
      'Art. 17 erasure requires a recent password confirmation.';

  @override
  String get oauthEraseHint =>
      'OAuth, BankID, and passkey accounts can erase only with a sign-in from the last five minutes. Sign in again first if that window has closed.';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get eraseMyAccount => 'Erase my account';

  @override
  String get withdrawEchoConsent => 'Withdraw echo consent';

  @override
  String get addPasskey => 'Add a passkey';

  @override
  String get passkeyAlready => 'A passkey is already on this account.';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get downloadJson => 'Download JSON';

  @override
  String get downloadExportSemantics => 'Download export as JSON';

  @override
  String get securityEvents => 'Security events';

  @override
  String get securityEventsHint =>
      'Coarse audit trail. No note bodies, recovery phrases, or national identity numbers.';

  @override
  String get noSecurityEvents => 'No security events on this account yet.';

  @override
  String get withdrawEchoTitle => 'Withdraw echo consent';

  @override
  String get withdrawEchoBody =>
      'Future remote echoes will ask again. Notes already on the board stay. This does not erase past consent records (Art. 7(3)).';

  @override
  String get withdrawConsent => 'Withdraw consent';

  @override
  String get keepConsent => 'Keep consent';

  @override
  String get compose => 'Compose';

  @override
  String get sendThisThought => 'Send this thought';

  @override
  String get keepItHere => 'Keep it here';

  @override
  String get echoConsentBody =>
      'This thought will go to Google once. The rest of the board stays here. Google LLC processes that one slip under your consent (Art. 6(1)(a)).';

  @override
  String get boardRestrictedArt18 => 'This board is restricted (Art. 18).';

  @override
  String get boardRestrictedSubtitle =>
      'Place, edit, delete, and move are paused until you unrestrict it.';

  @override
  String addedCard(int count) {
    return 'Added card $count of $count';
  }

  @override
  String get echoPlaced => 'An echo was placed nearby.';

  @override
  String get echoDismissed => 'Echo dismissed.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get noteDeleted => 'Note deleted.';

  @override
  String get phraseSaved => 'Recovery phrase saved.';

  @override
  String movedCard(String numeral) {
    return 'Moved. Card $numeral.';
  }

  @override
  String get removeSlipTitle => 'Remove this slip';

  @override
  String get removeSlipBody =>
      'The note and its echo, if any, will be removed from this board.';

  @override
  String get deleteThisNote => 'Delete this note';

  @override
  String get savePhraseTitle => 'Save this recovery phrase';

  @override
  String get savePhraseBody =>
      'OAuth, BankID, and passkey accounts wrap your key with this phrase. We cannot recover it.';

  @override
  String get savedPhrase => 'I have saved this phrase';

  @override
  String get moveThisNote => 'Move this note';

  @override
  String get dismissThisEcho => 'Dismiss this echo';

  @override
  String get editThisNote => 'Edit this note';

  @override
  String get saveThisNote => 'Save this note';

  @override
  String get deleteThisNoteSpoken => 'Delete this note';

  @override
  String get cancelEditing => 'Cancel editing';

  @override
  String get specimen => 'Specimen';

  @override
  String get untitledNote => 'Untitled note';

  @override
  String get echoLabel => 'Echo';

  @override
  String get cardCountOne => '1 card';

  @override
  String cardCountMany(int count) {
    return '$count cards';
  }

  @override
  String get restricted => 'Restricted';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get boardRenamed => 'Board renamed.';

  @override
  String get boardRestrictedAnnounce => 'Board restricted (Art. 18).';

  @override
  String get boardUnrestricted => 'Board unrestricted.';

  @override
  String get boardDeleted => 'Board deleted.';

  @override
  String get legalIncompleteSv =>
      'Fullständig svensk rättslig text för användarvillkor och impressum hävdas inte i den här versionen. Integritet och tillgänglighet finns på svenska.';

  @override
  String get exportReady => 'Export ready. This is your Art. 15 / 20 copy.';

  @override
  String get exportDownloaded => 'Export downloaded.';

  @override
  String get exportCopied => 'Export copied to clipboard';

  @override
  String get displayNameSaved => 'Display name saved.';

  @override
  String get passkeyAdded => 'Passkey added.';

  @override
  String get echoConsentWithdrawn => 'Echo consent withdrawn.';

  @override
  String get reenterPassword => 'Re-enter your password to erase this account.';

  @override
  String get accountErased => 'Account erased.';

  @override
  String get catAccountName => 'Account identifiers';

  @override
  String get catAccountPurpose => 'Authenticate you and restore your session';

  @override
  String get catAccountBasis => 'Contract (GDPR Art. 6(1)(b))';

  @override
  String get catAccountRetention => 'Life of the account, then erased';

  @override
  String get catBoardName => 'Board metadata';

  @override
  String get catBoardPurpose => 'List and organise your studio boards';

  @override
  String get catBoardBasis => 'Contract (GDPR Art. 6(1)(b))';

  @override
  String get catBoardRetention => 'Life of the account, then erased';

  @override
  String get catNodesName => 'Encrypted board nodes';

  @override
  String get catNodesPurpose =>
      'Store your notes as ciphertext the server cannot read';

  @override
  String get catNodesBasis => 'Contract (GDPR Art. 6(1)(b))';

  @override
  String get catNodesRetention => 'Life of the account, then erased';

  @override
  String get catEventsName => 'Consent and security events';

  @override
  String get catEventsPurpose => 'Demonstrate consent and detect abuse';

  @override
  String get catEventsBasis => 'Legal obligation / contract';

  @override
  String get catEventsRetention =>
      '90 days for security logs; consents for the life of the account';

  @override
  String get catEchoName => 'Optional echo (Gemini)';

  @override
  String get catEchoPurpose =>
      'A short companion to one summoned slip, never the rest of the board';

  @override
  String get catEchoBasis =>
      'Consent (GDPR Art. 6(1)(a)); local fallback if no key';

  @override
  String get catEchoRetention =>
      'Not stored at Google by us; the echo slip is encrypted like any other card';
}
