import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../map_style.dart';

/// Cache de tiles (CARTO Voyager por defeito, OSM como fallback) com um store
/// FMTC partilhado.
///
/// A app continua funcional sem cache: se a inicialização falhar, os mapas
/// usam o provider de rede normal do flutter_map.
class MapCache {
  MapCache._();

  static const String _offlinePrefix = 'kumpas_offline_';

  static FMTCStore? _store;
  static bool _ready = false;
  static Object? _error;

  static bool get isReady => _ready;
  static Object? get error => _error;

  /// Um provider por `TileLayer`: partilhar o mesmo `FMTCTileProvider` entre
  /// mapas simultâneos (Home + detalhe) mistura tiles de câmaras diferentes.
  static TileProvider? createTileProvider() {
    if (!_ready) return null;
    return FMTCTileProvider(
      stores: {kMapStoreName: BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      recordHitsAndMisses: false,
    );
  }

  /// Compatibilidade (preferir [createTileProvider]).
  static TileProvider? get tileProvider => createTileProvider();

  /// Contador de tiles falhados (diagnóstico; não é mostrado na UI).
  static int tileErrors = 0;

  /// Zoom nativo máximo dos tiles guardados/descarregados.
  static const int maxNativeZoom = 16;

  /// Falhas de tile são contadas para diagnóstico interno.
  static void noteTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    tileErrors++;
  }

  static Future<void> init() async {
    if (_ready) return;

    try {
      await FMTCObjectBoxBackend().initialise();
      final store = FMTCStore(kMapStoreName);
      if (!await store.manage.ready) {
        await store.manage.create();
      }
      _store = store;
      _ready = true;
      _error = null;
    } catch (error) {
      _error = error;
      _ready = false;
    }
  }

  static Future<bool> isOffline(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_offlinePrefix$questId') ?? false;
  }

  static Future<void> _setOffline(String questId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool('$_offlinePrefix$questId', true);
    } else {
      await prefs.remove('$_offlinePrefix$questId');
    }
  }

  /// Descarrega os tiles do bbox da trilha (zoom 10-16).
  static Future<void> downloadRegion({
    required String questId,
    required LatLngBounds bounds,
    required void Function(double progress) onProgress,
  }) async {
    if (!_ready) await init();
    if (!_ready || _store == null) {
      throw Exception('Cache offline indisponível neste dispositivo.');
    }

    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: 10,
      maxZoom: maxNativeZoom,
      options: TileLayer(
        urlTemplate: kMapTileUrl,
        userAgentPackageName: kMapUserAgent,
      ),
    );

    // Ritmo baixo para respeitar a política de uso do tile server OSM.
    final streams = _store!.download.startForeground(
      region: region,
      parallelThreads: 2,
      maxBufferLength: 40,
      skipExistingTiles: true,
      skipSeaTiles: true,
      rateLimit: 4,
      disableRecovery: true,
    );

    // Contabiliza sucesso/falha real de tiles: a stream de progresso termina
    // mesmo quando todos os pedidos falham (ex.: sem internet).
    var successes = 0;
    var existing = 0;
    var failures = 0;
    final eventSub = streams.tileEvents.listen((event) {
      if (event is SuccessfulTileEvent) {
        successes++;
      } else if (event is ExistingTileEvent) {
        existing++;
      } else if (event is FailedTileEvent) {
        failures++;
      }
    });

    await for (final progress in streams.downloadProgress) {
      final value = (progress.percentageProgress / 100).clamp(0.0, 1.0);
      onProgress(value.toDouble());
    }

    await eventSub.cancel();

    final usable = successes + existing;
    final total = usable + failures;
    if (usable == 0) {
      throw Exception(
        'sem tiles descarregados ($failures falhas de $total). '
        'Confirma a ligação à internet.',
      );
    }
    if (failures > usable) {
      throw Exception(
        'ligação instável: $failures de $total tiles falharam. '
        'Tenta novamente.',
      );
    }

    await _setOffline(questId, true);
  }

  /// Apaga todos os tiles offline (o store é partilhado pelas trilhas).
  static Future<void> clearAll() async {
    if (!_ready) await init();
    if (_store != null) {
      await _store!.manage.delete();
      await _store!.manage.create();
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_offlinePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
