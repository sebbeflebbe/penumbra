import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwedish.
  ///
  /// In en, this message translates to:
  /// **'Svenska'**
  String get languageSwedish;

  /// No description provided for @languageSwitchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language: Swedish. Switch to English.'**
  String get languageSwitchToEnglish;

  /// No description provided for @languageSwitchToSwedish.
  ///
  /// In en, this message translates to:
  /// **'Language: English. Switch to Swedish.'**
  String get languageSwitchToSwedish;

  /// No description provided for @languageAnnouncedEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language: English.'**
  String get languageAnnouncedEnglish;

  /// No description provided for @languageAnnouncedSwedish.
  ///
  /// In en, this message translates to:
  /// **'Language: Swedish.'**
  String get languageAnnouncedSwedish;

  /// No description provided for @navMakingOf.
  ///
  /// In en, this message translates to:
  /// **'Making of'**
  String get navMakingOf;

  /// No description provided for @navLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get navLegal;

  /// No description provided for @navBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get navBoards;

  /// No description provided for @navPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get navPrivacy;

  /// No description provided for @navSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get navSignIn;

  /// No description provided for @navSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get navSignOut;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Penumbra home'**
  String get navHome;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get navMenu;

  /// No description provided for @skipToContent.
  ///
  /// In en, this message translates to:
  /// **'Skip to content'**
  String get skipToContent;

  /// No description provided for @mainContent.
  ///
  /// In en, this message translates to:
  /// **'Main content'**
  String get mainContent;

  /// No description provided for @appearanceSemantics.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {current}. Switch to {next}.'**
  String appearanceSemantics(String current, String next);

  /// No description provided for @appearanceAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {name}'**
  String appearanceAnnounced(String name);

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get appearanceHighContrast;

  /// No description provided for @landingHeadline.
  ///
  /// In en, this message translates to:
  /// **'A quiet studio for thinking in space.'**
  String get landingHeadline;

  /// No description provided for @landingLede.
  ///
  /// In en, this message translates to:
  /// **'A spatial notebook for thoughts that aren\'t ready to leave the room. Notes stay encrypted in the browser; you hold the key. The studio is yours alone.'**
  String get landingLede;

  /// No description provided for @enterStudio.
  ///
  /// In en, this message translates to:
  /// **'Enter the studio'**
  String get enterStudio;

  /// No description provided for @readMakingOf.
  ///
  /// In en, this message translates to:
  /// **'Read the making of'**
  String get readMakingOf;

  /// No description provided for @factPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get factPrivateTitle;

  /// No description provided for @factPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Board bodies are encrypted in the browser before they touch a server.'**
  String get factPrivateBody;

  /// No description provided for @factA11yTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessible by design'**
  String get factA11yTitle;

  /// No description provided for @factA11yBody.
  ///
  /// In en, this message translates to:
  /// **'The canvas has a document order, names, and a high-contrast theme.'**
  String get factA11yBody;

  /// No description provided for @factLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legally operable'**
  String get factLegalTitle;

  /// No description provided for @factLegalBody.
  ///
  /// In en, this message translates to:
  /// **'GDPR rights, an SBOM, and an honest “we are not CE-marked” note.'**
  String get factLegalBody;

  /// No description provided for @teaserPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private by default.'**
  String get teaserPrivate;

  /// No description provided for @teaserAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible by design.'**
  String get teaserAccessible;

  /// No description provided for @teaserSwatch.
  ///
  /// In en, this message translates to:
  /// **'Colour swatch'**
  String get teaserSwatch;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInHeadline.
  ///
  /// In en, this message translates to:
  /// **'Enter the half-light.'**
  String get signInHeadline;

  /// No description provided for @signInLede.
  ///
  /// In en, this message translates to:
  /// **'Passkeys are preferred. Passwords are the weakest path and must be at least 12 characters.'**
  String get signInLede;

  /// No description provided for @continuePasskey.
  ///
  /// In en, this message translates to:
  /// **'Continue with a passkey'**
  String get continuePasskey;

  /// No description provided for @continueBankId.
  ///
  /// In en, this message translates to:
  /// **'Continue with BankID'**
  String get continueBankId;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueGitHub.
  ///
  /// In en, this message translates to:
  /// **'Continue with GitHub'**
  String get continueGitHub;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @emailRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Used only to restore your studio.'**
  String get emailRestoreHint;

  /// No description provided for @emailMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a magic link'**
  String get emailMagicLink;

  /// No description provided for @magicLinkDemo.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent (in this demo the session is opened immediately).'**
  String get magicLinkDemo;

  /// No description provided for @magicLinkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a link. Keep this tab open.'**
  String get magicLinkEmail;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use a password instead'**
  String get usePasswordInstead;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get signInWithPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @visibleOnlyToYou.
  ///
  /// In en, this message translates to:
  /// **'Visible only to you.'**
  String get visibleOnlyToYou;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this studio'**
  String get unlockTitle;

  /// No description provided for @unlockBody.
  ///
  /// In en, this message translates to:
  /// **'This device does not have the wrapping key. Enter the twelve-word recovery phrase shown when you first signed in.'**
  String get unlockBody;

  /// No description provided for @recoveryPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get recoveryPhraseLabel;

  /// No description provided for @recoveryPhraseHint.
  ///
  /// In en, this message translates to:
  /// **'Twelve words, in order.'**
  String get recoveryPhraseHint;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockSemantics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with recovery phrase'**
  String get unlockSemantics;

  /// No description provided for @notesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Notes unlocked.'**
  String get notesUnlocked;

  /// No description provided for @boardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boardsTitle;

  /// No description provided for @boardsLede.
  ///
  /// In en, this message translates to:
  /// **'Each board is yours alone. Titles are metadata; the cards inside are ciphertext.'**
  String get boardsLede;

  /// No description provided for @newBoard.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get newBoard;

  /// No description provided for @newBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Quiet thoughts'**
  String get newBoardHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @restrict.
  ///
  /// In en, this message translates to:
  /// **'Restrict'**
  String get restrict;

  /// No description provided for @unrestrict.
  ///
  /// In en, this message translates to:
  /// **'Unrestrict'**
  String get unrestrict;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @renameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename this board'**
  String get renameDialogTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save title'**
  String get saveTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this board'**
  String get deleteBoardTitle;

  /// No description provided for @deleteBoardBody.
  ///
  /// In en, this message translates to:
  /// **'The board and its cards will be removed. This cannot be undone.'**
  String get deleteBoardBody;

  /// No description provided for @deleteThisBoard.
  ///
  /// In en, this message translates to:
  /// **'Delete this board'**
  String get deleteThisBoard;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @emptyBoards.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Name a board, or enter the demo studio from home.'**
  String get emptyBoards;

  /// No description provided for @openBoard.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String openBoard(String title);

  /// No description provided for @renameBoard.
  ///
  /// In en, this message translates to:
  /// **'Rename {title}'**
  String renameBoard(String title);

  /// No description provided for @restrictBoard.
  ///
  /// In en, this message translates to:
  /// **'Restrict {title}'**
  String restrictBoard(String title);

  /// No description provided for @unrestrictBoard.
  ///
  /// In en, this message translates to:
  /// **'Unrestrict {title}'**
  String unrestrictBoard(String title);

  /// No description provided for @deleteBoard.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}'**
  String deleteBoard(String title);

  /// No description provided for @composeHint.
  ///
  /// In en, this message translates to:
  /// **'A thought, privately held'**
  String get composeHint;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @swatch.
  ///
  /// In en, this message translates to:
  /// **'Swatch'**
  String get swatch;

  /// No description provided for @summonEcho.
  ///
  /// In en, this message translates to:
  /// **'Summon an echo'**
  String get summonEcho;

  /// No description provided for @index.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get index;

  /// No description provided for @indexHint.
  ///
  /// In en, this message translates to:
  /// **'A conversation. Arrow keys or Move reposition the selected slip.'**
  String get indexHint;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get yourRights;

  /// No description provided for @controllerLine.
  ///
  /// In en, this message translates to:
  /// **'Controller: {name}. Contact: {email}. Age: 16+. Necessary storage only — no marketing cookies.'**
  String controllerLine(String name, String email);

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Art. 16 rectification. Optional.'**
  String get displayNameHint;

  /// No description provided for @saveDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Save display name'**
  String get saveDisplayName;

  /// No description provided for @passwordToErase.
  ///
  /// In en, this message translates to:
  /// **'Password to erase'**
  String get passwordToErase;

  /// No description provided for @passwordToEraseHint.
  ///
  /// In en, this message translates to:
  /// **'Art. 17 erasure requires a recent password confirmation.'**
  String get passwordToEraseHint;

  /// No description provided for @oauthEraseHint.
  ///
  /// In en, this message translates to:
  /// **'OAuth, BankID, and passkey accounts can erase only with a sign-in from the last five minutes. Sign in again first if that window has closed.'**
  String get oauthEraseHint;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyData;

  /// No description provided for @eraseMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Erase my account'**
  String get eraseMyAccount;

  /// No description provided for @withdrawEchoConsent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw echo consent'**
  String get withdrawEchoConsent;

  /// No description provided for @addPasskey.
  ///
  /// In en, this message translates to:
  /// **'Add a passkey'**
  String get addPasskey;

  /// No description provided for @passkeyAlready.
  ///
  /// In en, this message translates to:
  /// **'A passkey is already on this account.'**
  String get passkeyAlready;

  /// No description provided for @copyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get copyJson;

  /// No description provided for @downloadJson.
  ///
  /// In en, this message translates to:
  /// **'Download JSON'**
  String get downloadJson;

  /// No description provided for @downloadExportSemantics.
  ///
  /// In en, this message translates to:
  /// **'Download export as JSON'**
  String get downloadExportSemantics;

  /// No description provided for @securityEvents.
  ///
  /// In en, this message translates to:
  /// **'Security events'**
  String get securityEvents;

  /// No description provided for @securityEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Coarse audit trail. No note bodies, recovery phrases, or national identity numbers.'**
  String get securityEventsHint;

  /// No description provided for @noSecurityEvents.
  ///
  /// In en, this message translates to:
  /// **'No security events on this account yet.'**
  String get noSecurityEvents;

  /// No description provided for @withdrawEchoTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw echo consent'**
  String get withdrawEchoTitle;

  /// No description provided for @withdrawEchoBody.
  ///
  /// In en, this message translates to:
  /// **'Future remote echoes will ask again. Notes already on the board stay. This does not erase past consent records (Art. 7(3)).'**
  String get withdrawEchoBody;

  /// No description provided for @withdrawConsent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get withdrawConsent;

  /// No description provided for @keepConsent.
  ///
  /// In en, this message translates to:
  /// **'Keep consent'**
  String get keepConsent;

  /// No description provided for @compose.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get compose;

  /// No description provided for @sendThisThought.
  ///
  /// In en, this message translates to:
  /// **'Send this thought'**
  String get sendThisThought;

  /// No description provided for @keepItHere.
  ///
  /// In en, this message translates to:
  /// **'Keep it here'**
  String get keepItHere;

  /// No description provided for @echoConsentBody.
  ///
  /// In en, this message translates to:
  /// **'This thought will go to Google once. The rest of the board stays here. Google LLC processes that one slip under your consent (Art. 6(1)(a)).'**
  String get echoConsentBody;

  /// No description provided for @boardRestrictedArt18.
  ///
  /// In en, this message translates to:
  /// **'This board is restricted (Art. 18).'**
  String get boardRestrictedArt18;

  /// No description provided for @boardRestrictedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Place, edit, delete, and move are paused until you unrestrict it.'**
  String get boardRestrictedSubtitle;

  /// No description provided for @addedCard.
  ///
  /// In en, this message translates to:
  /// **'Added card {count} of {count}'**
  String addedCard(int count);

  /// No description provided for @echoPlaced.
  ///
  /// In en, this message translates to:
  /// **'An echo was placed nearby.'**
  String get echoPlaced;

  /// No description provided for @echoDismissed.
  ///
  /// In en, this message translates to:
  /// **'Echo dismissed.'**
  String get echoDismissed;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted.'**
  String get noteDeleted;

  /// No description provided for @phraseSaved.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase saved.'**
  String get phraseSaved;

  /// No description provided for @movedCard.
  ///
  /// In en, this message translates to:
  /// **'Moved. Card {numeral}.'**
  String movedCard(String numeral);

  /// No description provided for @removeSlipTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this slip'**
  String get removeSlipTitle;

  /// No description provided for @removeSlipBody.
  ///
  /// In en, this message translates to:
  /// **'The note and its echo, if any, will be removed from this board.'**
  String get removeSlipBody;

  /// No description provided for @deleteThisNote.
  ///
  /// In en, this message translates to:
  /// **'Delete this note'**
  String get deleteThisNote;

  /// No description provided for @savePhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this recovery phrase'**
  String get savePhraseTitle;

  /// No description provided for @savePhraseBody.
  ///
  /// In en, this message translates to:
  /// **'OAuth, BankID, and passkey accounts wrap your key with this phrase. We cannot recover it.'**
  String get savePhraseBody;

  /// No description provided for @savedPhrase.
  ///
  /// In en, this message translates to:
  /// **'I have saved this phrase'**
  String get savedPhrase;

  /// No description provided for @moveThisNote.
  ///
  /// In en, this message translates to:
  /// **'Move this note'**
  String get moveThisNote;

  /// No description provided for @dismissThisEcho.
  ///
  /// In en, this message translates to:
  /// **'Dismiss this echo'**
  String get dismissThisEcho;

  /// No description provided for @editThisNote.
  ///
  /// In en, this message translates to:
  /// **'Edit this note'**
  String get editThisNote;

  /// No description provided for @saveThisNote.
  ///
  /// In en, this message translates to:
  /// **'Save this note'**
  String get saveThisNote;

  /// No description provided for @deleteThisNoteSpoken.
  ///
  /// In en, this message translates to:
  /// **'Delete this note'**
  String get deleteThisNoteSpoken;

  /// No description provided for @cancelEditing.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get cancelEditing;

  /// No description provided for @specimen.
  ///
  /// In en, this message translates to:
  /// **'Specimen'**
  String get specimen;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get untitledNote;

  /// No description provided for @echoLabel.
  ///
  /// In en, this message translates to:
  /// **'Echo'**
  String get echoLabel;

  /// No description provided for @cardCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 card'**
  String get cardCountOne;

  /// No description provided for @cardCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String cardCountMany(int count);

  /// No description provided for @restricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get restricted;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @boardRenamed.
  ///
  /// In en, this message translates to:
  /// **'Board renamed.'**
  String get boardRenamed;

  /// No description provided for @boardRestrictedAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Board restricted (Art. 18).'**
  String get boardRestrictedAnnounce;

  /// No description provided for @boardUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Board unrestricted.'**
  String get boardUnrestricted;

  /// No description provided for @boardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Board deleted.'**
  String get boardDeleted;

  /// No description provided for @legalIncompleteSv.
  ///
  /// In en, this message translates to:
  /// **'Fullständig svensk rättslig text för användarvillkor och impressum hävdas inte i den här versionen. Integritet och tillgänglighet finns på svenska.'**
  String get legalIncompleteSv;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready. This is your Art. 15 / 20 copy.'**
  String get exportReady;

  /// No description provided for @exportDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Export downloaded.'**
  String get exportDownloaded;

  /// No description provided for @exportCopied.
  ///
  /// In en, this message translates to:
  /// **'Export copied to clipboard'**
  String get exportCopied;

  /// No description provided for @displayNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Display name saved.'**
  String get displayNameSaved;

  /// No description provided for @passkeyAdded.
  ///
  /// In en, this message translates to:
  /// **'Passkey added.'**
  String get passkeyAdded;

  /// No description provided for @echoConsentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Echo consent withdrawn.'**
  String get echoConsentWithdrawn;

  /// No description provided for @reenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password to erase this account.'**
  String get reenterPassword;

  /// No description provided for @accountErased.
  ///
  /// In en, this message translates to:
  /// **'Account erased.'**
  String get accountErased;

  /// No description provided for @catAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account identifiers'**
  String get catAccountName;

  /// No description provided for @catAccountPurpose.
  ///
  /// In en, this message translates to:
  /// **'Authenticate you and restore your session'**
  String get catAccountPurpose;

  /// No description provided for @catAccountBasis.
  ///
  /// In en, this message translates to:
  /// **'Contract (GDPR Art. 6(1)(b))'**
  String get catAccountBasis;

  /// No description provided for @catAccountRetention.
  ///
  /// In en, this message translates to:
  /// **'Life of the account, then erased'**
  String get catAccountRetention;

  /// No description provided for @catBoardName.
  ///
  /// In en, this message translates to:
  /// **'Board metadata'**
  String get catBoardName;

  /// No description provided for @catBoardPurpose.
  ///
  /// In en, this message translates to:
  /// **'List and organise your studio boards'**
  String get catBoardPurpose;

  /// No description provided for @catBoardBasis.
  ///
  /// In en, this message translates to:
  /// **'Contract (GDPR Art. 6(1)(b))'**
  String get catBoardBasis;

  /// No description provided for @catBoardRetention.
  ///
  /// In en, this message translates to:
  /// **'Life of the account, then erased'**
  String get catBoardRetention;

  /// No description provided for @catNodesName.
  ///
  /// In en, this message translates to:
  /// **'Encrypted board nodes'**
  String get catNodesName;

  /// No description provided for @catNodesPurpose.
  ///
  /// In en, this message translates to:
  /// **'Store your notes as ciphertext the server cannot read'**
  String get catNodesPurpose;

  /// No description provided for @catNodesBasis.
  ///
  /// In en, this message translates to:
  /// **'Contract (GDPR Art. 6(1)(b))'**
  String get catNodesBasis;

  /// No description provided for @catNodesRetention.
  ///
  /// In en, this message translates to:
  /// **'Life of the account, then erased'**
  String get catNodesRetention;

  /// No description provided for @catEventsName.
  ///
  /// In en, this message translates to:
  /// **'Consent and security events'**
  String get catEventsName;

  /// No description provided for @catEventsPurpose.
  ///
  /// In en, this message translates to:
  /// **'Demonstrate consent and detect abuse'**
  String get catEventsPurpose;

  /// No description provided for @catEventsBasis.
  ///
  /// In en, this message translates to:
  /// **'Legal obligation / contract'**
  String get catEventsBasis;

  /// No description provided for @catEventsRetention.
  ///
  /// In en, this message translates to:
  /// **'90 days for security logs; consents for the life of the account'**
  String get catEventsRetention;

  /// No description provided for @catEchoName.
  ///
  /// In en, this message translates to:
  /// **'Optional echo (Gemini)'**
  String get catEchoName;

  /// No description provided for @catEchoPurpose.
  ///
  /// In en, this message translates to:
  /// **'A short companion to one summoned slip, never the rest of the board'**
  String get catEchoPurpose;

  /// No description provided for @catEchoBasis.
  ///
  /// In en, this message translates to:
  /// **'Consent (GDPR Art. 6(1)(a)); local fallback if no key'**
  String get catEchoBasis;

  /// No description provided for @catEchoRetention.
  ///
  /// In en, this message translates to:
  /// **'Not stored at Google by us; the echo slip is encrypted like any other card'**
  String get catEchoRetention;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
