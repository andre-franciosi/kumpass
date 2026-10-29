/// Estilo do mapa (CARTO Voyager, visual próximo do Google Maps).
///
/// A key do CARTO é opcional e injetada em runtime:
/// `--dart-define=CARTO_KEY=...`
///
/// Se o CARTO passar a exigir key e esta não existir, força o fallback OSM:
/// `--dart-define=USE_OSM_TILES=true`
library;

const String kCartoKey = String.fromEnvironment(
  'CARTO_KEY',
  defaultValue: '',
);

/// Override de desenvolvimento (ex.: proxy local de tiles).
/// `--dart-define=MAP_TILE_URL=http://127.0.0.1:3001/{z}/{x}/{y}.png`
const String kMapTileUrlOverride = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: '',
);

const bool kForceOsmTiles = bool.fromEnvironment(
  'USE_OSM_TILES',
  defaultValue: false,
);

const String _cartoVoyagerUrl =
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

const String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

bool get isUsingCarto =>
    !kForceOsmTiles &&
    (kCartoKey.isNotEmpty || kMapTileUrlOverride.isNotEmpty);

String get kMapTileUrl {
  if (kMapTileUrlOverride.isNotEmpty) return kMapTileUrlOverride;
  if (kForceOsmTiles || kCartoKey.isEmpty) return _osmUrl;
  return '$_cartoVoyagerUrl?key=$kCartoKey';
}

String get kMapAttribution =>
    isUsingCarto ? '© OpenStreetMap © CARTO' : '© OpenStreetMap';

String get kMapUserAgent => 'dev.kumpas.app';

/// Nome do store FMTC. v2 invalida os tiles OSM antigos guardados no v1.
String get kMapStoreName => 'kumpas_maps_v2';
