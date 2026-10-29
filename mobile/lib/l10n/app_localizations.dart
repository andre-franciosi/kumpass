import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Kumpas'**
  String get appTitle;

  /// No description provided for @continue_.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continue_;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// No description provided for @loginTagline.
  ///
  /// In pt, this message translates to:
  /// **'Trilhas, histórias e recompensas\nna Grande Lisboa.'**
  String get loginTagline;

  /// No description provided for @loginPanelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na expedição'**
  String get loginPanelTitle;

  /// No description provided for @loginPanelHint.
  ///
  /// In pt, this message translates to:
  /// **'Usa o teu email para guardar progresso e recompensas.'**
  String get loginPanelHint;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Introduz um email válido.'**
  String get emailInvalid;

  /// No description provided for @nameOptional.
  ///
  /// In pt, this message translates to:
  /// **'Nome (opcional)'**
  String get nameOptional;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar / Criar conta'**
  String get loginButton;

  /// No description provided for @demoAccountHint.
  ///
  /// In pt, this message translates to:
  /// **'Conta de demonstração: tester@kumpas.dev'**
  String get demoAccountHint;

  /// No description provided for @gpsTestAccount.
  ///
  /// In pt, this message translates to:
  /// **'Usar conta de teste com GPS simulado'**
  String get gpsTestAccount;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languagePt.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePt;

  /// No description provided for @languageEn.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logout;

  /// No description provided for @allRegions.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get allRegions;

  /// No description provided for @trails.
  ///
  /// In pt, this message translates to:
  /// **'Trilhas'**
  String get trails;

  /// No description provided for @trailsAvailable.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 disponível} other{{count} disponíveis}}'**
  String trailsAvailable(num count);

  /// No description provided for @emptyRegion.
  ///
  /// In pt, this message translates to:
  /// **'Sem trilhas nesta região.'**
  String get emptyRegion;

  /// No description provided for @homeGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}!'**
  String homeGreeting(Object name);

  /// No description provided for @homeXpCheckpoints.
  ///
  /// In pt, this message translates to:
  /// **'{xp} XP · {count} checkpoints'**
  String homeXpCheckpoints(Object count, Object xp);

  /// No description provided for @homeXpToNextLevel.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {remaining} XP para o nível {level}'**
  String homeXpToNextLevel(Object level, Object remaining);

  /// No description provided for @levelShort.
  ///
  /// In pt, this message translates to:
  /// **'Nv'**
  String get levelShort;

  /// No description provided for @mapRegion.
  ///
  /// In pt, this message translates to:
  /// **'MAPA DA REGIÃO'**
  String get mapRegion;

  /// No description provided for @tapPin.
  ///
  /// In pt, this message translates to:
  /// **'Toca num pino'**
  String get tapPin;

  /// No description provided for @loadRegionError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a região.'**
  String get loadRegionError;

  /// No description provided for @badgeFirstStep.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro Passo'**
  String get badgeFirstStep;

  /// No description provided for @badgeExplorer.
  ///
  /// In pt, this message translates to:
  /// **'Explorador'**
  String get badgeExplorer;

  /// No description provided for @badgeCollector.
  ///
  /// In pt, this message translates to:
  /// **'Colecionador de Histórias'**
  String get badgeCollector;

  /// No description provided for @badgeGuardian.
  ///
  /// In pt, this message translates to:
  /// **'Guardião de {region}'**
  String badgeGuardian(Object region);

  /// No description provided for @badgeVoice.
  ///
  /// In pt, this message translates to:
  /// **'Voz da Montanha'**
  String get badgeVoice;

  /// No description provided for @badgeSunChaser.
  ///
  /// In pt, this message translates to:
  /// **'Caçador de Sol'**
  String get badgeSunChaser;

  /// No description provided for @statusNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova'**
  String get statusNew;

  /// No description provided for @statusInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em progresso'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluída'**
  String get statusCompleted;

  /// No description provided for @ctaView.
  ///
  /// In pt, this message translates to:
  /// **'Ver missão'**
  String get ctaView;

  /// No description provided for @ctaContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar missão'**
  String get ctaContinue;

  /// No description provided for @ctaReview.
  ///
  /// In pt, this message translates to:
  /// **'Rever trilha'**
  String get ctaReview;

  /// No description provided for @questCheckpoints.
  ///
  /// In pt, this message translates to:
  /// **'{done}/{total} checkpoints'**
  String questCheckpoints(Object done, Object total);

  /// No description provided for @offlineBadge.
  ///
  /// In pt, this message translates to:
  /// **'Offline'**
  String get offlineBadge;

  /// No description provided for @difficulty1.
  ///
  /// In pt, this message translates to:
  /// **'Fácil'**
  String get difficulty1;

  /// No description provided for @difficulty2.
  ///
  /// In pt, this message translates to:
  /// **'Moderado'**
  String get difficulty2;

  /// No description provided for @difficulty3.
  ///
  /// In pt, this message translates to:
  /// **'Desafiante'**
  String get difficulty3;

  /// No description provided for @difficulty4.
  ///
  /// In pt, this message translates to:
  /// **'Expert'**
  String get difficulty4;

  /// No description provided for @difficulty5.
  ///
  /// In pt, this message translates to:
  /// **'Lendário'**
  String get difficulty5;

  /// No description provided for @difficultyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level} · {label}'**
  String difficultyTitle(Object label, Object level);

  /// No description provided for @weatherIdeal.
  ///
  /// In pt, this message translates to:
  /// **'Ideal'**
  String get weatherIdeal;

  /// No description provided for @weatherGood.
  ///
  /// In pt, this message translates to:
  /// **'Bom'**
  String get weatherGood;

  /// No description provided for @weatherAvoid.
  ///
  /// In pt, this message translates to:
  /// **'Evitar'**
  String get weatherAvoid;

  /// No description provided for @weatherClear.
  ///
  /// In pt, this message translates to:
  /// **'Céu limpo'**
  String get weatherClear;

  /// No description provided for @weatherMostlyClear.
  ///
  /// In pt, this message translates to:
  /// **'Pouco nublado'**
  String get weatherMostlyClear;

  /// No description provided for @weatherCloudy.
  ///
  /// In pt, this message translates to:
  /// **'Nublado'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In pt, this message translates to:
  /// **'Nevoeiro'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In pt, this message translates to:
  /// **'Chuvisco'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In pt, this message translates to:
  /// **'Chuva'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In pt, this message translates to:
  /// **'Neve'**
  String get weatherSnow;

  /// No description provided for @weatherShowers.
  ///
  /// In pt, this message translates to:
  /// **'Aguaceiros'**
  String get weatherShowers;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In pt, this message translates to:
  /// **'Trovoada'**
  String get weatherThunderstorm;

  /// No description provided for @weatherVariable.
  ///
  /// In pt, this message translates to:
  /// **'Condições variáveis'**
  String get weatherVariable;

  /// No description provided for @catTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica'**
  String get catTip;

  /// No description provided for @catWarning.
  ///
  /// In pt, this message translates to:
  /// **'Aviso'**
  String get catWarning;

  /// No description provided for @catDanger.
  ///
  /// In pt, this message translates to:
  /// **'Perigo'**
  String get catDanger;

  /// No description provided for @loreUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'LORE DESBLOQUEADO'**
  String get loreUnlocked;

  /// No description provided for @trailCompleted.
  ///
  /// In pt, this message translates to:
  /// **'TRILHA CONCLUÍDA'**
  String get trailCompleted;

  /// No description provided for @loreXpGained.
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP'**
  String loreXpGained(Object xp);

  /// No description provided for @loreRewardNote.
  ///
  /// In pt, this message translates to:
  /// **'Missão completa! A recompensa de parceiro está disponível no teu perfil.'**
  String get loreRewardNote;

  /// No description provided for @loreSource.
  ///
  /// In pt, this message translates to:
  /// **'Fonte: {source}'**
  String loreSource(Object source);

  /// No description provided for @photoCredit.
  ///
  /// In pt, this message translates to:
  /// **'Foto: {credit}'**
  String photoCredit(Object credit);

  /// No description provided for @statDistance.
  ///
  /// In pt, this message translates to:
  /// **'distância'**
  String get statDistance;

  /// No description provided for @statDuration.
  ///
  /// In pt, this message translates to:
  /// **'duração'**
  String get statDuration;

  /// No description provided for @statElevation.
  ///
  /// In pt, this message translates to:
  /// **'desnível'**
  String get statElevation;

  /// No description provided for @statXp.
  ///
  /// In pt, this message translates to:
  /// **'XP'**
  String get statXp;

  /// No description provided for @pointsLabel.
  ///
  /// In pt, this message translates to:
  /// **'{score} pts'**
  String pointsLabel(Object score);

  /// No description provided for @levelExplainer.
  ///
  /// In pt, this message translates to:
  /// **'O nível é calculado com base em tudo o que a trilha exige — não é escolhido à mão.'**
  String get levelExplainer;

  /// No description provided for @terrainLabel.
  ///
  /// In pt, this message translates to:
  /// **'terreno'**
  String get terrainLabel;

  /// No description provided for @completedRewardBanner.
  ///
  /// In pt, this message translates to:
  /// **'Trilha concluída! Recompensa de parceiro desbloqueada.'**
  String get completedRewardBanner;

  /// No description provided for @mapTrailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mapa da trilha'**
  String get mapTrailTitle;

  /// No description provided for @offlineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mapa offline'**
  String get offlineTitle;

  /// No description provided for @offlineSaved.
  ///
  /// In pt, this message translates to:
  /// **'Guardado'**
  String get offlineSaved;

  /// No description provided for @offlineSavedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Os tiles desta região estão no dispositivo. Podes navegar sem rede.'**
  String get offlineSavedDesc;

  /// No description provided for @offlineDownloadDesc.
  ///
  /// In pt, this message translates to:
  /// **'Descarrega os tiles desta trilha (zoom 10-16) para usar o mapa sem internet.'**
  String get offlineDownloadDesc;

  /// No description provided for @offlineUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Cache offline indisponível neste dispositivo. O mapa continua a funcionar online.'**
  String get offlineUnavailable;

  /// No description provided for @offlineDownloading.
  ///
  /// In pt, this message translates to:
  /// **'A descarregar… {percent}%'**
  String offlineDownloading(Object percent);

  /// No description provided for @offlineDeleteMaps.
  ///
  /// In pt, this message translates to:
  /// **'Apagar mapas'**
  String get offlineDeleteMaps;

  /// No description provided for @offlineDownloadMap.
  ///
  /// In pt, this message translates to:
  /// **'Descarregar mapa'**
  String get offlineDownloadMap;

  /// No description provided for @offlineDownloaded.
  ///
  /// In pt, this message translates to:
  /// **'Mapa offline descarregado.'**
  String get offlineDownloaded;

  /// No description provided for @offlineDownloadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível descarregar: {error}'**
  String offlineDownloadError(Object error);

  /// No description provided for @offlineDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar mapas offline?'**
  String get offlineDeleteTitle;

  /// No description provided for @offlineDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Os tiles guardados de todas as trilhas serão removidos. Os planos e o progresso mantêm-se.'**
  String get offlineDeleteBody;

  /// No description provided for @offlineDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Mapas offline apagados.'**
  String get offlineDeleted;

  /// No description provided for @offlineDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível apagar: {error}'**
  String offlineDeleteError(Object error);

  /// No description provided for @planTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planear o passeio'**
  String get planTitle;

  /// No description provided for @planPrepBadge.
  ///
  /// In pt, this message translates to:
  /// **'+50 XP preparador'**
  String get planPrepBadge;

  /// No description provided for @planPickDate.
  ///
  /// In pt, this message translates to:
  /// **'Escolher data'**
  String get planPickDate;

  /// No description provided for @planDateHelp.
  ///
  /// In pt, this message translates to:
  /// **'Quando vais fazer a trilha?'**
  String get planDateHelp;

  /// No description provided for @planLessPeople.
  ///
  /// In pt, this message translates to:
  /// **'Menos pessoas'**
  String get planLessPeople;

  /// No description provided for @planMorePeople.
  ///
  /// In pt, this message translates to:
  /// **'Mais pessoas'**
  String get planMorePeople;

  /// No description provided for @planHowGo.
  ///
  /// In pt, this message translates to:
  /// **'Como vais?'**
  String get planHowGo;

  /// No description provided for @transportWalk.
  ///
  /// In pt, this message translates to:
  /// **'A pé'**
  String get transportWalk;

  /// No description provided for @transportCar.
  ///
  /// In pt, this message translates to:
  /// **'Carro'**
  String get transportCar;

  /// No description provided for @transportTrain.
  ///
  /// In pt, this message translates to:
  /// **'Comboio'**
  String get transportTrain;

  /// No description provided for @transportBus.
  ///
  /// In pt, this message translates to:
  /// **'Autocarro'**
  String get transportBus;

  /// No description provided for @planChecklist.
  ///
  /// In pt, this message translates to:
  /// **'Checklist ({done}/{total})'**
  String planChecklist(Object done, Object total);

  /// No description provided for @planSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar plano'**
  String get planSave;

  /// No description provided for @planSavedPrep.
  ///
  /// In pt, this message translates to:
  /// **'Plano guardado! Preparação completa num dia {rating}: +50 XP de preparador.'**
  String planSavedPrep(Object rating);

  /// No description provided for @planSavedLocal.
  ///
  /// In pt, this message translates to:
  /// **'Plano guardado localmente.'**
  String get planSavedLocal;

  /// No description provided for @planLocalNote.
  ///
  /// In pt, this message translates to:
  /// **'Guardado localmente neste dispositivo. Sincronização na nuvem chega na próxima versão.'**
  String get planLocalNote;

  /// No description provided for @planChecklistWater.
  ///
  /// In pt, this message translates to:
  /// **'Água (1,5 L por pessoa)'**
  String get planChecklistWater;

  /// No description provided for @planChecklistSnacks.
  ///
  /// In pt, this message translates to:
  /// **'Snacks e fruta'**
  String get planChecklistSnacks;

  /// No description provided for @planChecklistBattery.
  ///
  /// In pt, this message translates to:
  /// **'Bateria externa / telemóvel carregado'**
  String get planChecklistBattery;

  /// No description provided for @planChecklistShoes.
  ///
  /// In pt, this message translates to:
  /// **'Calçado de trilho'**
  String get planChecklistShoes;

  /// No description provided for @planChecklistSun.
  ///
  /// In pt, this message translates to:
  /// **'Proteção solar e chapéu'**
  String get planChecklistSun;

  /// No description provided for @forecastPickDate.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe uma data para veres a previsão do tempo nesta trilha.'**
  String get forecastPickDate;

  /// No description provided for @forecastLoading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar previsão…'**
  String get forecastLoading;

  /// No description provided for @forecastUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Previsão indisponível agora. O plano continua válido.'**
  String get forecastUnavailable;

  /// No description provided for @forecastRainWind.
  ///
  /// In pt, this message translates to:
  /// **'Chuva {rain}% · vento {wind} km/h · {date}'**
  String forecastRainWind(Object date, Object rain, Object wind);

  /// No description provided for @forecastBestDays.
  ///
  /// In pt, this message translates to:
  /// **'Melhores dias (próximos 16 dias)'**
  String get forecastBestDays;

  /// No description provided for @checkpointsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Checkpoints'**
  String get checkpointsTitle;

  /// No description provided for @checkpointLocked.
  ///
  /// In pt, this message translates to:
  /// **'Lore bloqueado — valida este checkpoint no local para revelar a história.'**
  String get checkpointLocked;

  /// No description provided for @checkpointRadius.
  ///
  /// In pt, this message translates to:
  /// **'Raio {meters} m'**
  String checkpointRadius(Object meters);

  /// No description provided for @checkpointValidate.
  ///
  /// In pt, this message translates to:
  /// **'Validar'**
  String get checkpointValidate;

  /// No description provided for @checkpointDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get checkpointDone;

  /// No description provided for @rewardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa de parceiro'**
  String get rewardTitle;

  /// No description provided for @rewardBody.
  ///
  /// In pt, this message translates to:
  /// **'Conclui todos os checkpoints para desbloquear ofertas em parceiros locais.'**
  String get rewardBody;

  /// No description provided for @reviewsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewRate.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar'**
  String get reviewRate;

  /// No description provided for @reviewEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar review'**
  String get reviewEdit;

  /// No description provided for @reviewEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há reviews. Sê o primeiro a partilhar a tua experiência.'**
  String get reviewEmpty;

  /// No description provided for @reviewSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'A tua review'**
  String get reviewSheetTitle;

  /// No description provided for @reviewSheetHint.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda outros exploradores a escolher a próxima missão.'**
  String get reviewSheetHint;

  /// No description provided for @reviewComment.
  ///
  /// In pt, this message translates to:
  /// **'Comentário (opcional)'**
  String get reviewComment;

  /// No description provided for @reviewPublish.
  ///
  /// In pt, this message translates to:
  /// **'Publicar review'**
  String get reviewPublish;

  /// No description provided for @reviewPublished.
  ///
  /// In pt, this message translates to:
  /// **'Review publicada. Obrigado!'**
  String get reviewPublished;

  /// No description provided for @liveInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Trilha em curso'**
  String get liveInProgress;

  /// No description provided for @liveRerun.
  ///
  /// In pt, this message translates to:
  /// **'Rever o percurso'**
  String get liveRerun;

  /// No description provided for @liveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trilha ao vivo'**
  String get liveTitle;

  /// No description provided for @liveStats.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min · {distance} km percorridos'**
  String liveStats(Object distance, Object minutes);

  /// No description provided for @liveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'GPS em tempo real, checkpoints automáticos e recados no caminho.'**
  String get liveSubtitle;

  /// No description provided for @liveResume.
  ///
  /// In pt, this message translates to:
  /// **'Retomar trilha'**
  String get liveResume;

  /// No description provided for @liveStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar trilha ao vivo'**
  String get liveStart;

  /// No description provided for @messagesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recados do caminho'**
  String get messagesTitle;

  /// No description provided for @messagesEmptyPreview.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há recados. Inicia a trilha para deixar o primeiro.'**
  String get messagesEmptyPreview;

  /// No description provided for @messagesStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar'**
  String get messagesStart;

  /// No description provided for @messagesSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver os {count} recados no mapa'**
  String messagesSeeAll(Object count);

  /// No description provided for @messagesSee.
  ///
  /// In pt, this message translates to:
  /// **'Ver recados no mapa'**
  String get messagesSee;

  /// No description provided for @messagesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há recados nesta trilha.\nSê o primeiro a deixar uma dica.'**
  String get messagesEmpty;

  /// No description provided for @messagesHeader.
  ///
  /// In pt, this message translates to:
  /// **'Recados do caminho'**
  String get messagesHeader;

  /// No description provided for @messagesPositionUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não temos a tua posição.'**
  String get messagesPositionUnknown;

  /// No description provided for @messagesPosted.
  ///
  /// In pt, this message translates to:
  /// **'Recado deixado no caminho!'**
  String get messagesPosted;

  /// No description provided for @messagesReported.
  ///
  /// In pt, this message translates to:
  /// **'Recado denunciado. Obrigado.'**
  String get messagesReported;

  /// No description provided for @messagesCompose.
  ///
  /// In pt, this message translates to:
  /// **'Deixar recado no caminho'**
  String get messagesCompose;

  /// No description provided for @messagesComposeHint.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda quem vem depois (máx. 280 caracteres).'**
  String get messagesComposeHint;

  /// No description provided for @messagesComposePlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Fonte seca — leva água extra.'**
  String get messagesComposePlaceholder;

  /// No description provided for @messagesPublish.
  ///
  /// In pt, this message translates to:
  /// **'Publicar recado'**
  String get messagesPublish;

  /// No description provided for @messagesReport.
  ///
  /// In pt, this message translates to:
  /// **'Denunciar'**
  String get messagesReport;

  /// No description provided for @timeNow.
  ///
  /// In pt, this message translates to:
  /// **'agora'**
  String get timeNow;

  /// No description provided for @timeMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{count}min'**
  String timeMinutes(Object count);

  /// No description provided for @timeHours.
  ///
  /// In pt, this message translates to:
  /// **'{count}h'**
  String timeHours(Object count);

  /// No description provided for @timeDays.
  ///
  /// In pt, this message translates to:
  /// **'{count}d'**
  String timeDays(Object count);

  /// No description provided for @liveBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get liveBack;

  /// No description provided for @liveSimulatedGps.
  ///
  /// In pt, this message translates to:
  /// **'GPS simulado'**
  String get liveSimulatedGps;

  /// No description provided for @liveFollow.
  ///
  /// In pt, this message translates to:
  /// **'Seguir-me'**
  String get liveFollow;

  /// No description provided for @liveOffRoute.
  ///
  /// In pt, this message translates to:
  /// **'Estás fora da rota. Segue o traço verde.'**
  String get liveOffRoute;

  /// No description provided for @liveNextCheckpoint.
  ///
  /// In pt, this message translates to:
  /// **'Próximo checkpoint'**
  String get liveNextCheckpoint;

  /// No description provided for @liveAllValidated.
  ///
  /// In pt, this message translates to:
  /// **'Todos validados'**
  String get liveAllValidated;

  /// No description provided for @liveTrailComplete.
  ///
  /// In pt, this message translates to:
  /// **'Trilha completa!'**
  String get liveTrailComplete;

  /// No description provided for @liveCheckpointsValidated.
  ///
  /// In pt, this message translates to:
  /// **'{done}/{total} checkpoints validados'**
  String liveCheckpointsValidated(Object done, Object total);

  /// No description provided for @liveRecado.
  ///
  /// In pt, this message translates to:
  /// **'Recado'**
  String get liveRecado;

  /// No description provided for @liveGpsButton.
  ///
  /// In pt, this message translates to:
  /// **'GPS'**
  String get liveGpsButton;

  /// No description provided for @liveFinish.
  ///
  /// In pt, this message translates to:
  /// **'Terminar'**
  String get liveFinish;

  /// No description provided for @liveFinishTitle.
  ///
  /// In pt, this message translates to:
  /// **'Terminar trilha?'**
  String get liveFinishTitle;

  /// No description provided for @liveFinishBody.
  ///
  /// In pt, this message translates to:
  /// **'Percorrestes {distance} em {duration}. O progresso dos checkpoints já está guardado.'**
  String liveFinishBody(Object distance, Object duration);

  /// No description provided for @liveKeepGoing.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get liveKeepGoing;

  /// No description provided for @liveOfflineSync.
  ///
  /// In pt, this message translates to:
  /// **'Sem rede: check-in guardado para sincronizar.'**
  String get liveOfflineSync;

  /// No description provided for @simulatorTitle.
  ///
  /// In pt, this message translates to:
  /// **'GPS simulado (conta de teste)'**
  String get simulatorTitle;

  /// No description provided for @simulatorHint.
  ///
  /// In pt, this message translates to:
  /// **'Toca longo no mapa para teletransportar, ou usa os atalhos.'**
  String get simulatorHint;

  /// No description provided for @simulatorTeleported.
  ///
  /// In pt, this message translates to:
  /// **'Teleportado para {name}'**
  String simulatorTeleported(Object name);

  /// No description provided for @simulatorMoved.
  ///
  /// In pt, this message translates to:
  /// **'GPS simulado movido.'**
  String get simulatorMoved;

  /// No description provided for @simulatorStart.
  ///
  /// In pt, this message translates to:
  /// **'Simular percurso'**
  String get simulatorStart;

  /// No description provided for @simulatorStarting.
  ///
  /// In pt, this message translates to:
  /// **'A simular caminhada…'**
  String get simulatorStarting;

  /// No description provided for @simulatorStop.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get simulatorStop;

  /// No description provided for @detailError.
  ///
  /// In pt, this message translates to:
  /// **'Perdido na trilha?'**
  String get detailError;

  /// No description provided for @locationDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Serviço de localização desativado.'**
  String get locationDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de localização negada.'**
  String get locationDenied;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
