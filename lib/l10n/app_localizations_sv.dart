// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwedish => 'Svenska';

  @override
  String get languageSwitchToEnglish => 'Språk: svenska. Byt till engelska.';

  @override
  String get languageSwitchToSwedish => 'Språk: engelska. Byt till svenska.';

  @override
  String get languageAnnouncedEnglish => 'Språk: engelska.';

  @override
  String get languageAnnouncedSwedish => 'Språk: svenska.';

  @override
  String get navMakingOf => 'Tillkomst';

  @override
  String get navLegal => 'Juridik';

  @override
  String get navBoards => 'Tavlor';

  @override
  String get navPrivacy => 'Integritet';

  @override
  String get navSignIn => 'Logga in';

  @override
  String get navSignOut => 'Logga ut';

  @override
  String get navHome => 'Penumbra hem';

  @override
  String get navMenu => 'Öppna meny';

  @override
  String get skipToContent => 'Hoppa till innehållet';

  @override
  String get mainContent => 'Huvudinnehåll';

  @override
  String appearanceSemantics(String current, String next) {
    return 'Utseende: $current. Byt till $next.';
  }

  @override
  String appearanceAnnounced(String name) {
    return 'Utseende: $name';
  }

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Ljust';

  @override
  String get appearanceDark => 'Mörkt';

  @override
  String get appearanceHighContrast => 'Hög kontrast';

  @override
  String get landingHeadline => 'En tyst ateljé för att tänka i rummet.';

  @override
  String get landingLede =>
      'Ett rumsligt anteckningsblock för tankar som inte är redo att lämna rummet. Anteckningar krypteras i webbläsaren; du håller nyckeln. Ateljén är bara din.';

  @override
  String get enterStudio => 'Gå in i ateljén';

  @override
  String get readMakingOf => 'Läs tillkomsten';

  @override
  String get factPrivateTitle => 'Privat som standard';

  @override
  String get factPrivateBody =>
      'Tavlans innehåll krypteras i webbläsaren innan det når en server.';

  @override
  String get factA11yTitle => 'Tillgängligt från början';

  @override
  String get factA11yBody =>
      'Duken har dokumentordning, namn och ett högkontrasttema.';

  @override
  String get factLegalTitle => 'Juridiskt körbart';

  @override
  String get factLegalBody =>
      'GDPR-rättigheter, en SBOM och en ärlig notis om att vi inte är CE-märkta.';

  @override
  String get teaserPrivate => 'Privat som standard.';

  @override
  String get teaserAccessible => 'Tillgängligt från början.';

  @override
  String get teaserSwatch => 'Färgprov';

  @override
  String get signInTitle => 'Logga in';

  @override
  String get signInHeadline => 'Steg in i halvskuggan.';

  @override
  String get signInLede =>
      'Passnycklar föredras. Lösenord är den svagaste vägen och måste vara minst 12 tecken.';

  @override
  String get continuePasskey => 'Fortsätt med en passnyckel';

  @override
  String get continueBankId => 'Fortsätt med BankID';

  @override
  String get continueGoogle => 'Fortsätt med Google';

  @override
  String get continueGitHub => 'Fortsätt med GitHub';

  @override
  String get orDivider => 'eller';

  @override
  String get emailRestoreHint => 'Används bara för att återställa ateljén.';

  @override
  String get emailMagicLink => 'Maila mig en magisk länk';

  @override
  String get magicLinkDemo =>
      'Magisk länk skickad (i den här demon öppnas sessionen direkt).';

  @override
  String get magicLinkEmail => 'Kolla mejlen. Låt den här fliken vara öppen.';

  @override
  String get hidePassword => 'Dölj lösenord';

  @override
  String get usePasswordInstead => 'Använd lösenord i stället';

  @override
  String get passwordLabel => 'Lösenord';

  @override
  String get signInWithPassword => 'Logga in med lösenord';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get visibleOnlyToYou => 'Synlig bara för dig.';

  @override
  String get unlockTitle => 'Lås upp ateljén';

  @override
  String get unlockBody =>
      'Den här enheten har inte omslagsnyckeln. Ange den tolvordiga återställningsfrasen som visades när du loggade in första gången.';

  @override
  String get recoveryPhraseLabel => 'Återställningsfras';

  @override
  String get recoveryPhraseHint => 'Tolv ord, i ordning.';

  @override
  String get unlock => 'Lås upp';

  @override
  String get unlockSemantics => 'Lås upp med återställningsfras';

  @override
  String get notesUnlocked => 'Anteckningarna är upplåsta.';

  @override
  String get boardsTitle => 'Tavlor';

  @override
  String get boardsLede =>
      'Varje tavla är bara din. Titlar är metadata; korten inuti är chiffertext.';

  @override
  String get newBoard => 'Ny tavla';

  @override
  String get newBoardHint => 'Tysta tankar';

  @override
  String get create => 'Skapa';

  @override
  String get open => 'Öppna';

  @override
  String get rename => 'Byt namn';

  @override
  String get restrict => 'Begränsa';

  @override
  String get unrestrict => 'Häv begränsning';

  @override
  String get delete => 'Ta bort';

  @override
  String get renameDialogTitle => 'Byt namn på tavlan';

  @override
  String get titleLabel => 'Titel';

  @override
  String get saveTitle => 'Spara titel';

  @override
  String get cancel => 'Avbryt';

  @override
  String get deleteBoardTitle => 'Ta bort tavlan';

  @override
  String get deleteBoardBody =>
      'Tavlan och korten tas bort. Det går inte att ångra.';

  @override
  String get deleteThisBoard => 'Ta bort tavlan';

  @override
  String get keepIt => 'Behåll den';

  @override
  String get emptyBoards =>
      'Inget här än. Namnge en tavla, eller gå in i demoateljén från startsidan.';

  @override
  String openBoard(String title) {
    return 'Öppna $title';
  }

  @override
  String renameBoard(String title) {
    return 'Byt namn på $title';
  }

  @override
  String restrictBoard(String title) {
    return 'Begränsa $title';
  }

  @override
  String unrestrictBoard(String title) {
    return 'Häv begränsning av $title';
  }

  @override
  String deleteBoard(String title) {
    return 'Ta bort $title';
  }

  @override
  String get composeHint => 'En tanke, privat hållen';

  @override
  String get place => 'Placera';

  @override
  String get swatch => 'Prov';

  @override
  String get summonEcho => 'Kalla fram ett eko';

  @override
  String get index => 'Index';

  @override
  String get indexHint =>
      'Ett samtal. Piltangenter eller Flytta flyttar det valda kortet.';

  @override
  String get edit => 'Redigera';

  @override
  String get save => 'Spara';

  @override
  String get move => 'Flytta';

  @override
  String get dismiss => 'Avfärda';

  @override
  String get privacyTitle => 'Integritet';

  @override
  String get yourRights => 'Dina rättigheter';

  @override
  String controllerLine(String name, String email) {
    return 'Personuppgiftsansvarig: $name. Kontakt: $email. Ålder: 16+. Endast nödvändig lagring — inga marknadsföringskakor.';
  }

  @override
  String get displayName => 'Visningsnamn';

  @override
  String get displayNameHint => 'Art. 16 rättelse. Valfritt.';

  @override
  String get saveDisplayName => 'Spara visningsnamn';

  @override
  String get passwordToErase => 'Lösenord för radering';

  @override
  String get passwordToEraseHint =>
      'Art. 17 radering kräver en färsk lösenordsbekräftelse.';

  @override
  String get oauthEraseHint =>
      'BankID-, OAuth- och passnyckelkonton kan raderas bara med en inloggning från de senaste fem minuterna. Logga in igen om fönstret har stängt.';

  @override
  String get exportMyData => 'Exportera mina data';

  @override
  String get eraseMyAccount => 'Radera mitt konto';

  @override
  String get withdrawEchoConsent => 'Återkalla ekonsamtycke';

  @override
  String get addPasskey => 'Lägg till en passnyckel';

  @override
  String get passkeyAlready => 'Kontot har redan en passnyckel.';

  @override
  String get copyJson => 'Kopiera JSON';

  @override
  String get downloadJson => 'Ladda ner JSON';

  @override
  String get downloadExportSemantics => 'Ladda ner export som JSON';

  @override
  String get securityEvents => 'Säkerhetshändelser';

  @override
  String get securityEventsHint =>
      'Grov revisionsspårning. Inga korttexter, fraser eller personnummer.';

  @override
  String get noSecurityEvents => 'Inga säkerhetshändelser på kontot ännu.';

  @override
  String get withdrawEchoTitle => 'Återkalla ekonsamtycke';

  @override
  String get withdrawEchoBody =>
      'Nästa fjärr-eko frågar igen. Kort som redan ligger kvar. Tidigare samtyckesrader raderas inte (art. 7.3).';

  @override
  String get withdrawConsent => 'Återkalla samtycke';

  @override
  String get keepConsent => 'Behåll samtycke';

  @override
  String get compose => 'Komponera';

  @override
  String get sendThisThought => 'Skicka den här tanken';

  @override
  String get keepItHere => 'Behåll den här';

  @override
  String get echoConsentBody =>
      'Den här tanken går till Google en gång. Resten av tavlan stannar här. Google LLC behandlar det kortet med ditt samtycke (art. 6.1 a).';

  @override
  String get boardRestrictedArt18 => 'Tavlan är begränsad (art. 18).';

  @override
  String get boardRestrictedSubtitle =>
      'Placera, redigera, ta bort och flytta är pausade tills du häver begränsningen.';

  @override
  String addedCard(int count) {
    return 'Lade till kort $count av $count';
  }

  @override
  String get echoPlaced => 'Ett eko lades intill.';

  @override
  String get echoDismissed => 'Ekot avfärdat.';

  @override
  String get noteSaved => 'Anteckningen sparad.';

  @override
  String get noteDeleted => 'Anteckningen borttagen.';

  @override
  String get phraseSaved => 'Återställningsfrasen sparad.';

  @override
  String movedCard(String numeral) {
    return 'Flyttad. Kort $numeral.';
  }

  @override
  String get removeSlipTitle => 'Ta bort kortet';

  @override
  String get removeSlipBody =>
      'Anteckningen och eventuellt eko intill tas bort.';

  @override
  String get deleteThisNote => 'Ta bort anteckningen';

  @override
  String get savePhraseTitle => 'Spara den här återställningsfrasen';

  @override
  String get savePhraseBody =>
      'BankID-, OAuth- och passnyckelkonton slår in nyckeln med den här frasen. Vi kan inte återskapa den.';

  @override
  String get savedPhrase => 'Jag har sparat frasen';

  @override
  String get moveThisNote => 'Flytta anteckningen';

  @override
  String get dismissThisEcho => 'Avfärda ekot';

  @override
  String get editThisNote => 'Redigera anteckningen';

  @override
  String get saveThisNote => 'Spara anteckningen';

  @override
  String get deleteThisNoteSpoken => 'Ta bort anteckningen';

  @override
  String get cancelEditing => 'Avbryt redigering';

  @override
  String get specimen => 'Prov';

  @override
  String get untitledNote => 'Namnlös anteckning';

  @override
  String get echoLabel => 'Eko';

  @override
  String get cardCountOne => '1 kort';

  @override
  String cardCountMany(int count) {
    return '$count kort';
  }

  @override
  String get restricted => 'Begränsad';

  @override
  String get justNow => 'just nu';

  @override
  String minutesAgo(int count) {
    return '$count min sedan';
  }

  @override
  String hoursAgo(int count) {
    return '$count tim sedan';
  }

  @override
  String daysAgo(int count) {
    return '$count d sedan';
  }

  @override
  String get boardRenamed => 'Tavlan bytte namn.';

  @override
  String get boardRestrictedAnnounce => 'Tavlan begränsad (art. 18).';

  @override
  String get boardUnrestricted => 'Begränsningen hävd.';

  @override
  String get boardDeleted => 'Tavlan borttagen.';

  @override
  String get legalIncompleteSv =>
      'Fullständig svensk rättslig text för användarvillkor och impressum hävdas inte i den här versionen. Integritet och tillgänglighet finns på svenska.';

  @override
  String get exportReady =>
      'Exporten är klar. Det här är din kopia enligt art. 15 / 20.';

  @override
  String get exportDownloaded => 'Exporten nedladdad.';

  @override
  String get exportCopied => 'Exporten kopierad till urklipp';

  @override
  String get displayNameSaved => 'Visningsnamnet sparat.';

  @override
  String get passkeyAdded => 'Passnyckel tillagd.';

  @override
  String get echoConsentWithdrawn => 'Ekonsamtycke återkallat.';

  @override
  String get reenterPassword => 'Ange lösenordet igen för att radera kontot.';

  @override
  String get accountErased => 'Kontot raderat.';

  @override
  String get catAccountName => 'Kontoidentifierare';

  @override
  String get catAccountPurpose => 'Autentisera dig och återställa sessionen';

  @override
  String get catAccountBasis => 'Avtal (GDPR art. 6.1 b)';

  @override
  String get catAccountRetention => 'Kontots livstid, därefter radering';

  @override
  String get catBoardName => 'Tavlans metadata';

  @override
  String get catBoardPurpose => 'Lista och organisera dina tavlor';

  @override
  String get catBoardBasis => 'Avtal (GDPR art. 6.1 b)';

  @override
  String get catBoardRetention => 'Kontots livstid, därefter radering';

  @override
  String get catNodesName => 'Krypterade tavlkort';

  @override
  String get catNodesPurpose =>
      'Lagra anteckningar som chiffertext som servern inte kan läsa';

  @override
  String get catNodesBasis => 'Avtal (GDPR art. 6.1 b)';

  @override
  String get catNodesRetention => 'Kontots livstid, därefter radering';

  @override
  String get catEventsName => 'Samtycke och säkerhetshändelser';

  @override
  String get catEventsPurpose => 'Visa samtycke och upptäcka missbruk';

  @override
  String get catEventsBasis => 'Rättslig förpliktelse / avtal';

  @override
  String get catEventsRetention =>
      '90 dagar för säkerhetsloggar; samtycken under kontots livstid';

  @override
  String get catEchoName => 'Valfritt eko (Gemini)';

  @override
  String get catEchoPurpose =>
      'En kort följeslagare till ett kallat kort, aldrig resten av tavlan';

  @override
  String get catEchoBasis =>
      'Samtycke (GDPR art. 6.1 a); lokal röst utan nyckel';

  @override
  String get catEchoRetention =>
      'Lagras inte hos Google av oss; ekokortet krypteras som övriga kort';
}
