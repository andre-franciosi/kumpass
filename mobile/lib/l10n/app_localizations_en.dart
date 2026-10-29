// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kumpas';

  @override
  String get continue_ => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get error => 'Error';

  @override
  String get loginTagline =>
      'Trails, stories and rewards\nacross Greater Lisbon.';

  @override
  String get loginPanelTitle => 'Join the expedition';

  @override
  String get loginPanelHint =>
      'Use your email to keep your progress and rewards.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email.';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get loginButton => 'Sign in / Create account';

  @override
  String get demoAccountHint => 'Demo account: tester@kumpas.dev';

  @override
  String get gpsTestAccount => 'Use test account with simulated GPS';

  @override
  String get language => 'Language';

  @override
  String get languagePt => 'Português';

  @override
  String get languageEn => 'English';

  @override
  String get refresh => 'Refresh';

  @override
  String get logout => 'Log out';

  @override
  String get allRegions => 'All';

  @override
  String get trails => 'Trails';

  @override
  String trailsAvailable(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count available',
      one: '1 available',
    );
    return '$_temp0';
  }

  @override
  String get emptyRegion => 'No trails in this region.';

  @override
  String homeGreeting(Object name) {
    return 'Hi, $name!';
  }

  @override
  String homeXpCheckpoints(Object count, Object xp) {
    return '$xp XP · $count checkpoints';
  }

  @override
  String homeXpToNextLevel(Object level, Object remaining) {
    return '$remaining XP to level $level';
  }

  @override
  String get levelShort => 'Lv';

  @override
  String get mapRegion => 'REGION MAP';

  @override
  String get tapPin => 'Tap a pin';

  @override
  String get loadRegionError => 'Could not load the region.';

  @override
  String get badgeFirstStep => 'First Step';

  @override
  String get badgeExplorer => 'Explorer';

  @override
  String get badgeCollector => 'Story Collector';

  @override
  String badgeGuardian(Object region) {
    return '$region Guardian';
  }

  @override
  String get badgeVoice => 'Mountain Voice';

  @override
  String get badgeSunChaser => 'Sun Chaser';

  @override
  String get statusNew => 'New';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get ctaView => 'View quest';

  @override
  String get ctaContinue => 'Continue quest';

  @override
  String get ctaReview => 'Revisit trail';

  @override
  String questCheckpoints(Object done, Object total) {
    return '$done/$total checkpoints';
  }

  @override
  String get offlineBadge => 'Offline';

  @override
  String get difficulty1 => 'Easy';

  @override
  String get difficulty2 => 'Moderate';

  @override
  String get difficulty3 => 'Challenging';

  @override
  String get difficulty4 => 'Expert';

  @override
  String get difficulty5 => 'Legendary';

  @override
  String difficultyTitle(Object label, Object level) {
    return 'Level $level · $label';
  }

  @override
  String get weatherIdeal => 'Ideal';

  @override
  String get weatherGood => 'Good';

  @override
  String get weatherAvoid => 'Avoid';

  @override
  String get weatherClear => 'Clear sky';

  @override
  String get weatherMostlyClear => 'Mostly clear';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherShowers => 'Showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherVariable => 'Variable conditions';

  @override
  String get catTip => 'Tip';

  @override
  String get catWarning => 'Warning';

  @override
  String get catDanger => 'Danger';

  @override
  String get loreUnlocked => 'LORE UNLOCKED';

  @override
  String get trailCompleted => 'TRAIL COMPLETED';

  @override
  String loreXpGained(Object xp) {
    return '+$xp XP';
  }

  @override
  String get loreRewardNote =>
      'Quest complete! Your partner reward is available in your profile.';

  @override
  String loreSource(Object source) {
    return 'Source: $source';
  }

  @override
  String photoCredit(Object credit) {
    return 'Photo: $credit';
  }

  @override
  String get statDistance => 'distance';

  @override
  String get statDuration => 'duration';

  @override
  String get statElevation => 'ascent';

  @override
  String get statXp => 'XP';

  @override
  String pointsLabel(Object score) {
    return '$score pts';
  }

  @override
  String get levelExplainer =>
      'The level is derived from everything the trail demands — it is not picked by hand.';

  @override
  String get terrainLabel => 'terrain';

  @override
  String get completedRewardBanner =>
      'Trail completed! Partner reward unlocked.';

  @override
  String get mapTrailTitle => 'Trail map';

  @override
  String get offlineTitle => 'Offline map';

  @override
  String get offlineSaved => 'Saved';

  @override
  String get offlineSavedDesc =>
      'This region\'s tiles are on your device. You can navigate without network.';

  @override
  String get offlineDownloadDesc =>
      'Download this trail\'s tiles (zoom 10-16) to use the map without internet.';

  @override
  String get offlineUnavailable =>
      'Offline cache unavailable on this device. The map keeps working online.';

  @override
  String offlineDownloading(Object percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get offlineDeleteMaps => 'Delete maps';

  @override
  String get offlineDownloadMap => 'Download map';

  @override
  String get offlineDownloaded => 'Offline map downloaded.';

  @override
  String offlineDownloadError(Object error) {
    return 'Could not download: $error';
  }

  @override
  String get offlineDeleteTitle => 'Delete offline maps?';

  @override
  String get offlineDeleteBody =>
      'Saved tiles from all trails will be removed. Plans and progress are kept.';

  @override
  String get offlineDeleted => 'Offline maps deleted.';

  @override
  String offlineDeleteError(Object error) {
    return 'Could not delete: $error';
  }

  @override
  String get planTitle => 'Plan the hike';

  @override
  String get planPrepBadge => '+50 XP prepared';

  @override
  String get planPickDate => 'Pick a date';

  @override
  String get planDateHelp => 'When are you hiking?';

  @override
  String get planLessPeople => 'Fewer people';

  @override
  String get planMorePeople => 'More people';

  @override
  String get planHowGo => 'How are you going?';

  @override
  String get transportWalk => 'On foot';

  @override
  String get transportCar => 'Car';

  @override
  String get transportTrain => 'Train';

  @override
  String get transportBus => 'Bus';

  @override
  String planChecklist(Object done, Object total) {
    return 'Checklist ($done/$total)';
  }

  @override
  String get planSave => 'Save plan';

  @override
  String planSavedPrep(Object rating) {
    return 'Plan saved! Fully prepared on an $rating day: +50 XP.';
  }

  @override
  String get planSavedLocal => 'Plan saved locally.';

  @override
  String get planLocalNote =>
      'Saved on this device. Cloud sync arrives in the next version.';

  @override
  String get planChecklistWater => 'Water (1.5 L per person)';

  @override
  String get planChecklistSnacks => 'Snacks and fruit';

  @override
  String get planChecklistBattery => 'Power bank / charged phone';

  @override
  String get planChecklistShoes => 'Hiking shoes';

  @override
  String get planChecklistSun => 'Sun protection and hat';

  @override
  String get forecastPickDate =>
      'Pick a date to see this trail\'s weather forecast.';

  @override
  String get forecastLoading => 'Loading forecast…';

  @override
  String get forecastUnavailable =>
      'Forecast unavailable right now. Your plan is still valid.';

  @override
  String forecastRainWind(Object date, Object rain, Object wind) {
    return 'Rain $rain% · wind $wind km/h · $date';
  }

  @override
  String get forecastBestDays => 'Best days (next 16 days)';

  @override
  String get checkpointsTitle => 'Checkpoints';

  @override
  String get checkpointLocked =>
      'Lore locked — check in at the spot to reveal the story.';

  @override
  String checkpointRadius(Object meters) {
    return 'Radius $meters m';
  }

  @override
  String get checkpointValidate => 'Check in';

  @override
  String get checkpointDone => 'Done';

  @override
  String get rewardTitle => 'Partner reward';

  @override
  String get rewardBody =>
      'Complete every checkpoint to unlock local partner offers.';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewRate => 'Rate';

  @override
  String get reviewEdit => 'Edit review';

  @override
  String get reviewEmpty =>
      'No reviews yet. Be the first to share your experience.';

  @override
  String get reviewSheetTitle => 'Your review';

  @override
  String get reviewSheetHint => 'Help other explorers pick their next quest.';

  @override
  String get reviewComment => 'Comment (optional)';

  @override
  String get reviewPublish => 'Publish review';

  @override
  String get reviewPublished => 'Review published. Thank you!';

  @override
  String get liveInProgress => 'Trail in progress';

  @override
  String get liveRerun => 'Revisit the route';

  @override
  String get liveTitle => 'Live trail';

  @override
  String liveStats(Object distance, Object minutes) {
    return '$minutes min · $distance km covered';
  }

  @override
  String get liveSubtitle =>
      'Real-time GPS, automatic checkpoints and messages along the way.';

  @override
  String get liveResume => 'Resume trail';

  @override
  String get liveStart => 'Start live trail';

  @override
  String get messagesTitle => 'Trail messages';

  @override
  String get messagesEmptyPreview =>
      'No messages yet. Start the trail to leave the first one.';

  @override
  String get messagesStart => 'Start';

  @override
  String messagesSeeAll(Object count) {
    return 'See all $count messages on the map';
  }

  @override
  String get messagesSee => 'See messages on the map';

  @override
  String get messagesEmpty =>
      'No messages on this trail yet.\nBe the first to leave a tip.';

  @override
  String get messagesHeader => 'Trail messages';

  @override
  String get messagesPositionUnknown => 'We don\'t have your position yet.';

  @override
  String get messagesPosted => 'Message left on the trail!';

  @override
  String get messagesReported => 'Message reported. Thank you.';

  @override
  String get messagesCompose => 'Leave a message on the trail';

  @override
  String get messagesComposeHint =>
      'Help those coming next (max. 280 characters).';

  @override
  String get messagesComposePlaceholder =>
      'E.g.: Fountain is dry — bring extra water.';

  @override
  String get messagesPublish => 'Publish message';

  @override
  String get messagesReport => 'Report';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutes(Object count) {
    return '${count}min';
  }

  @override
  String timeHours(Object count) {
    return '${count}h';
  }

  @override
  String timeDays(Object count) {
    return '${count}d';
  }

  @override
  String get liveBack => 'Back';

  @override
  String get liveSimulatedGps => 'Simulated GPS';

  @override
  String get liveFollow => 'Follow me';

  @override
  String get liveOffRoute => 'You are off route. Follow the green line.';

  @override
  String get liveNextCheckpoint => 'Next checkpoint';

  @override
  String get liveAllValidated => 'All checked in';

  @override
  String get liveTrailComplete => 'Trail complete!';

  @override
  String liveCheckpointsValidated(Object done, Object total) {
    return '$done/$total checkpoints checked in';
  }

  @override
  String get liveRecado => 'Message';

  @override
  String get liveGpsButton => 'GPS';

  @override
  String get liveFinish => 'Finish';

  @override
  String get liveFinishTitle => 'Finish the trail?';

  @override
  String liveFinishBody(Object distance, Object duration) {
    return 'You covered $distance in $duration. Checkpoint progress is already saved.';
  }

  @override
  String get liveKeepGoing => 'Keep going';

  @override
  String get liveOfflineSync => 'No network: check-in queued to sync.';

  @override
  String get simulatorTitle => 'Simulated GPS (test account)';

  @override
  String get simulatorHint =>
      'Long-press the map to teleport, or use the shortcuts.';

  @override
  String simulatorTeleported(Object name) {
    return 'Teleported to $name';
  }

  @override
  String get simulatorMoved => 'Simulated GPS moved.';

  @override
  String get simulatorStart => 'Simulate route';

  @override
  String get simulatorStarting => 'Simulating walk…';

  @override
  String get simulatorStop => 'Stop';

  @override
  String get detailError => 'Lost on the trail?';

  @override
  String get locationDisabled => 'Location services are disabled.';

  @override
  String get locationDenied => 'Location permission denied.';
}
