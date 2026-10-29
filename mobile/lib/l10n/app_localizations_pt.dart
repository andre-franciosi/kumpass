// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Kumpas';

  @override
  String get continue_ => 'Continuar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Apagar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get save => 'Guardar';

  @override
  String get error => 'Erro';

  @override
  String get loginTagline =>
      'Trilhas, histórias e recompensas\nna Grande Lisboa.';

  @override
  String get loginPanelTitle => 'Entrar na expedição';

  @override
  String get loginPanelHint =>
      'Usa o teu email para guardar progresso e recompensas.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Introduz um email válido.';

  @override
  String get nameOptional => 'Nome (opcional)';

  @override
  String get loginButton => 'Entrar / Criar conta';

  @override
  String get demoAccountHint => 'Conta de demonstração: tester@kumpas.dev';

  @override
  String get gpsTestAccount => 'Usar conta de teste com GPS simulado';

  @override
  String get language => 'Idioma';

  @override
  String get languagePt => 'Português';

  @override
  String get languageEn => 'English';

  @override
  String get refresh => 'Atualizar';

  @override
  String get logout => 'Sair';

  @override
  String get allRegions => 'Todas';

  @override
  String get trails => 'Trilhas';

  @override
  String trailsAvailable(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disponíveis',
      one: '1 disponível',
    );
    return '$_temp0';
  }

  @override
  String get emptyRegion => 'Sem trilhas nesta região.';

  @override
  String homeGreeting(Object name) {
    return 'Olá, $name!';
  }

  @override
  String homeXpCheckpoints(Object count, Object xp) {
    return '$xp XP · $count checkpoints';
  }

  @override
  String homeXpToNextLevel(Object level, Object remaining) {
    return 'Faltam $remaining XP para o nível $level';
  }

  @override
  String get levelShort => 'Nv';

  @override
  String get mapRegion => 'MAPA DA REGIÃO';

  @override
  String get tapPin => 'Toca num pino';

  @override
  String get loadRegionError => 'Não foi possível carregar a região.';

  @override
  String get badgeFirstStep => 'Primeiro Passo';

  @override
  String get badgeExplorer => 'Explorador';

  @override
  String get badgeCollector => 'Colecionador de Histórias';

  @override
  String badgeGuardian(Object region) {
    return 'Guardião de $region';
  }

  @override
  String get badgeVoice => 'Voz da Montanha';

  @override
  String get badgeSunChaser => 'Caçador de Sol';

  @override
  String get statusNew => 'Nova';

  @override
  String get statusInProgress => 'Em progresso';

  @override
  String get statusCompleted => 'Concluída';

  @override
  String get ctaView => 'Ver missão';

  @override
  String get ctaContinue => 'Continuar missão';

  @override
  String get ctaReview => 'Rever trilha';

  @override
  String questCheckpoints(Object done, Object total) {
    return '$done/$total checkpoints';
  }

  @override
  String get offlineBadge => 'Offline';

  @override
  String get difficulty1 => 'Fácil';

  @override
  String get difficulty2 => 'Moderado';

  @override
  String get difficulty3 => 'Desafiante';

  @override
  String get difficulty4 => 'Expert';

  @override
  String get difficulty5 => 'Lendário';

  @override
  String difficultyTitle(Object label, Object level) {
    return 'Nível $level · $label';
  }

  @override
  String get weatherIdeal => 'Ideal';

  @override
  String get weatherGood => 'Bom';

  @override
  String get weatherAvoid => 'Evitar';

  @override
  String get weatherClear => 'Céu limpo';

  @override
  String get weatherMostlyClear => 'Pouco nublado';

  @override
  String get weatherCloudy => 'Nublado';

  @override
  String get weatherFog => 'Nevoeiro';

  @override
  String get weatherDrizzle => 'Chuvisco';

  @override
  String get weatherRain => 'Chuva';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherShowers => 'Aguaceiros';

  @override
  String get weatherThunderstorm => 'Trovoada';

  @override
  String get weatherVariable => 'Condições variáveis';

  @override
  String get catTip => 'Dica';

  @override
  String get catWarning => 'Aviso';

  @override
  String get catDanger => 'Perigo';

  @override
  String get loreUnlocked => 'LORE DESBLOQUEADO';

  @override
  String get trailCompleted => 'TRILHA CONCLUÍDA';

  @override
  String loreXpGained(Object xp) {
    return '+$xp XP';
  }

  @override
  String get loreRewardNote =>
      'Missão completa! A recompensa de parceiro está disponível no teu perfil.';

  @override
  String loreSource(Object source) {
    return 'Fonte: $source';
  }

  @override
  String photoCredit(Object credit) {
    return 'Foto: $credit';
  }

  @override
  String get statDistance => 'distância';

  @override
  String get statDuration => 'duração';

  @override
  String get statElevation => 'desnível';

  @override
  String get statXp => 'XP';

  @override
  String pointsLabel(Object score) {
    return '$score pts';
  }

  @override
  String get levelExplainer =>
      'O nível é calculado com base em tudo o que a trilha exige — não é escolhido à mão.';

  @override
  String get terrainLabel => 'terreno';

  @override
  String get completedRewardBanner =>
      'Trilha concluída! Recompensa de parceiro desbloqueada.';

  @override
  String get mapTrailTitle => 'Mapa da trilha';

  @override
  String get offlineTitle => 'Mapa offline';

  @override
  String get offlineSaved => 'Guardado';

  @override
  String get offlineSavedDesc =>
      'Os tiles desta região estão no dispositivo. Podes navegar sem rede.';

  @override
  String get offlineDownloadDesc =>
      'Descarrega os tiles desta trilha (zoom 10-16) para usar o mapa sem internet.';

  @override
  String get offlineUnavailable =>
      'Cache offline indisponível neste dispositivo. O mapa continua a funcionar online.';

  @override
  String offlineDownloading(Object percent) {
    return 'A descarregar… $percent%';
  }

  @override
  String get offlineDeleteMaps => 'Apagar mapas';

  @override
  String get offlineDownloadMap => 'Descarregar mapa';

  @override
  String get offlineDownloaded => 'Mapa offline descarregado.';

  @override
  String offlineDownloadError(Object error) {
    return 'Não foi possível descarregar: $error';
  }

  @override
  String get offlineDeleteTitle => 'Apagar mapas offline?';

  @override
  String get offlineDeleteBody =>
      'Os tiles guardados de todas as trilhas serão removidos. Os planos e o progresso mantêm-se.';

  @override
  String get offlineDeleted => 'Mapas offline apagados.';

  @override
  String offlineDeleteError(Object error) {
    return 'Não foi possível apagar: $error';
  }

  @override
  String get planTitle => 'Planear o passeio';

  @override
  String get planPrepBadge => '+50 XP preparador';

  @override
  String get planPickDate => 'Escolher data';

  @override
  String get planDateHelp => 'Quando vais fazer a trilha?';

  @override
  String get planLessPeople => 'Menos pessoas';

  @override
  String get planMorePeople => 'Mais pessoas';

  @override
  String get planHowGo => 'Como vais?';

  @override
  String get transportWalk => 'A pé';

  @override
  String get transportCar => 'Carro';

  @override
  String get transportTrain => 'Comboio';

  @override
  String get transportBus => 'Autocarro';

  @override
  String planChecklist(Object done, Object total) {
    return 'Checklist ($done/$total)';
  }

  @override
  String get planSave => 'Guardar plano';

  @override
  String planSavedPrep(Object rating) {
    return 'Plano guardado! Preparação completa num dia $rating: +50 XP de preparador.';
  }

  @override
  String get planSavedLocal => 'Plano guardado localmente.';

  @override
  String get planLocalNote =>
      'Guardado localmente neste dispositivo. Sincronização na nuvem chega na próxima versão.';

  @override
  String get planChecklistWater => 'Água (1,5 L por pessoa)';

  @override
  String get planChecklistSnacks => 'Snacks e fruta';

  @override
  String get planChecklistBattery => 'Bateria externa / telemóvel carregado';

  @override
  String get planChecklistShoes => 'Calçado de trilho';

  @override
  String get planChecklistSun => 'Proteção solar e chapéu';

  @override
  String get forecastPickDate =>
      'Escolhe uma data para veres a previsão do tempo nesta trilha.';

  @override
  String get forecastLoading => 'A carregar previsão…';

  @override
  String get forecastUnavailable =>
      'Previsão indisponível agora. O plano continua válido.';

  @override
  String forecastRainWind(Object date, Object rain, Object wind) {
    return 'Chuva $rain% · vento $wind km/h · $date';
  }

  @override
  String get forecastBestDays => 'Melhores dias (próximos 16 dias)';

  @override
  String get checkpointsTitle => 'Checkpoints';

  @override
  String get checkpointLocked =>
      'Lore bloqueado — valida este checkpoint no local para revelar a história.';

  @override
  String checkpointRadius(Object meters) {
    return 'Raio $meters m';
  }

  @override
  String get checkpointValidate => 'Validar';

  @override
  String get checkpointDone => 'Concluído';

  @override
  String get rewardTitle => 'Recompensa de parceiro';

  @override
  String get rewardBody =>
      'Conclui todos os checkpoints para desbloquear ofertas em parceiros locais.';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewRate => 'Avaliar';

  @override
  String get reviewEdit => 'Editar review';

  @override
  String get reviewEmpty =>
      'Ainda não há reviews. Sê o primeiro a partilhar a tua experiência.';

  @override
  String get reviewSheetTitle => 'A tua review';

  @override
  String get reviewSheetHint =>
      'Ajuda outros exploradores a escolher a próxima missão.';

  @override
  String get reviewComment => 'Comentário (opcional)';

  @override
  String get reviewPublish => 'Publicar review';

  @override
  String get reviewPublished => 'Review publicada. Obrigado!';

  @override
  String get liveInProgress => 'Trilha em curso';

  @override
  String get liveRerun => 'Rever o percurso';

  @override
  String get liveTitle => 'Trilha ao vivo';

  @override
  String liveStats(Object distance, Object minutes) {
    return '$minutes min · $distance km percorridos';
  }

  @override
  String get liveSubtitle =>
      'GPS em tempo real, checkpoints automáticos e recados no caminho.';

  @override
  String get liveResume => 'Retomar trilha';

  @override
  String get liveStart => 'Iniciar trilha ao vivo';

  @override
  String get messagesTitle => 'Recados do caminho';

  @override
  String get messagesEmptyPreview =>
      'Ainda não há recados. Inicia a trilha para deixar o primeiro.';

  @override
  String get messagesStart => 'Iniciar';

  @override
  String messagesSeeAll(Object count) {
    return 'Ver os $count recados no mapa';
  }

  @override
  String get messagesSee => 'Ver recados no mapa';

  @override
  String get messagesEmpty =>
      'Ainda não há recados nesta trilha.\nSê o primeiro a deixar uma dica.';

  @override
  String get messagesHeader => 'Recados do caminho';

  @override
  String get messagesPositionUnknown => 'Ainda não temos a tua posição.';

  @override
  String get messagesPosted => 'Recado deixado no caminho!';

  @override
  String get messagesReported => 'Recado denunciado. Obrigado.';

  @override
  String get messagesCompose => 'Deixar recado no caminho';

  @override
  String get messagesComposeHint =>
      'Ajuda quem vem depois (máx. 280 caracteres).';

  @override
  String get messagesComposePlaceholder => 'Ex.: Fonte seca — leva água extra.';

  @override
  String get messagesPublish => 'Publicar recado';

  @override
  String get messagesReport => 'Denunciar';

  @override
  String get timeNow => 'agora';

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
  String get liveBack => 'Voltar';

  @override
  String get liveSimulatedGps => 'GPS simulado';

  @override
  String get liveFollow => 'Seguir-me';

  @override
  String get liveOffRoute => 'Estás fora da rota. Segue o traço verde.';

  @override
  String get liveNextCheckpoint => 'Próximo checkpoint';

  @override
  String get liveAllValidated => 'Todos validados';

  @override
  String get liveTrailComplete => 'Trilha completa!';

  @override
  String liveCheckpointsValidated(Object done, Object total) {
    return '$done/$total checkpoints validados';
  }

  @override
  String get liveRecado => 'Recado';

  @override
  String get liveGpsButton => 'GPS';

  @override
  String get liveFinish => 'Terminar';

  @override
  String get liveFinishTitle => 'Terminar trilha?';

  @override
  String liveFinishBody(Object distance, Object duration) {
    return 'Percorrestes $distance em $duration. O progresso dos checkpoints já está guardado.';
  }

  @override
  String get liveKeepGoing => 'Continuar';

  @override
  String get liveOfflineSync => 'Sem rede: check-in guardado para sincronizar.';

  @override
  String get simulatorTitle => 'GPS simulado (conta de teste)';

  @override
  String get simulatorHint =>
      'Toca longo no mapa para teletransportar, ou usa os atalhos.';

  @override
  String simulatorTeleported(Object name) {
    return 'Teleportado para $name';
  }

  @override
  String get simulatorMoved => 'GPS simulado movido.';

  @override
  String get simulatorStart => 'Simular percurso';

  @override
  String get simulatorStarting => 'A simular caminhada…';

  @override
  String get simulatorStop => 'Parar';

  @override
  String get detailError => 'Perdido na trilha?';

  @override
  String get locationDisabled => 'Serviço de localização desativado.';

  @override
  String get locationDenied => 'Permissão de localização negada.';
}
