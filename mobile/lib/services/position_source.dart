import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Leitura de GPS normalizada (real ou simulada).
class GpsFix {
  const GpsFix({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.heading = 0,
    this.speed = 0,
    this.accuracy = 5,
    this.simulated = false,
  });

  final double lat;
  final double lng;
  final DateTime timestamp;
  final double heading;
  final double speed;
  final double accuracy;
  final bool simulated;

  LatLng get latLng => LatLng(lat, lng);
}

abstract class PositionSource {
  Stream<GpsFix> get stream;
  bool get isSimulated;
  Future<void> dispose();
}

// ---------------------------------------------------------------------------
// GPS real
// ---------------------------------------------------------------------------

class LivePositionSource implements PositionSource {
  LivePositionSource() {
    _controller = StreamController<GpsFix>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  late final StreamController<GpsFix> _controller;
  StreamSubscription<Position>? _subscription;

  @override
  Stream<GpsFix> get stream => _controller.stream;

  @override
  bool get isSimulated => false;

  Future<void> _start() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _controller.addError(Exception('Serviço de localização desativado.'));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _controller.addError(Exception('Permissão de localização negada.'));
      return;
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen(
      (position) => _controller.add(
        GpsFix(
          lat: position.latitude,
          lng: position.longitude,
          heading: position.heading,
          speed: position.speed,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        ),
      ),
      onError: _controller.addError,
    );
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> dispose() async {
    await _stop();
    await _controller.close();
  }
}

// ---------------------------------------------------------------------------
// GPS simulado (apenas contas de teste)
// ---------------------------------------------------------------------------

/// Emite fixes ao longo do track (ou onde o utilizador tocar), para testar
/// auto-unlock, fora-de-rota e recados sem sair do sofá.
class SimulatedPositionSource implements PositionSource {
  SimulatedPositionSource({
    required this.track,
    this.walkingSpeedMps = 1.4,
  });

  final List<LatLng> track;
  final double walkingSpeedMps;

  final StreamController<GpsFix> _controller =
      StreamController<GpsFix>.broadcast();

  Timer? _timer;
  double _progressMeters = 0;
  GpsFix? _current;

  @override
  Stream<GpsFix> get stream => _controller.stream;

  @override
  bool get isSimulated => true;

  GpsFix? get current => _current;

  static const double _metersPerDegreeLat = 110540;

  double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  double _trackLength() {
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      total += _haversine(track[i - 1], track[i]);
    }
    return total;
  }

  LatLng _pointAt(double meters) {
    if (track.isEmpty) return const LatLng(38.72, -9.14);
    if (track.length == 1) return track.first;

    var travelled = 0.0;
    for (var i = 1; i < track.length; i++) {
      final segment = _haversine(track[i - 1], track[i]);
      if (travelled + segment >= meters) {
        final t = segment == 0 ? 0.0 : (meters - travelled) / segment;
        return LatLng(
          track[i - 1].latitude +
              (track[i].latitude - track[i - 1].latitude) * t,
          track[i - 1].longitude +
              (track[i].longitude - track[i - 1].longitude) * t,
        );
      }
      travelled += segment;
    }
    return track.last;
  }

  double _headingAt(double meters) {
    if (track.length < 2) return 0;
    var travelled = 0.0;
    for (var i = 1; i < track.length; i++) {
      final segment = _haversine(track[i - 1], track[i]);
      if (travelled + segment >= meters) {
        final dx = (track[i].longitude - track[i - 1].longitude) *
            math.cos(track[i].latitude * math.pi / 180);
        final dy = track[i].latitude - track[i - 1].latitude;
        final degrees = math.atan2(dx, dy) * 180 / math.pi;
        return (degrees + 360) % 360;
      }
      travelled += segment;
    }
    return 0;
  }

  void _emit(LatLng point, {double speed = 0}) {
    _current = GpsFix(
      lat: point.latitude,
      lng: point.longitude,
      heading: _headingAt(_progressMeters),
      speed: speed,
      accuracy: 3,
      timestamp: DateTime.now(),
      simulated: true,
    );
    if (!_controller.isClosed) _controller.add(_current!);
  }

  /// Coloca o utilizador num ponto arbitrário (toque longo no mapa).
  void teleport(LatLng point) {
    _stopWalking();
    final distance = track.isEmpty ? 0.0 : _nearestProgress(point);
    _progressMeters = distance;
    _emit(point);
  }

  double _nearestProgress(LatLng point) {
    var best = 0.0;
    var bestDistance = double.infinity;
    var travelled = 0.0;
    for (var i = 1; i < track.length; i++) {
      travelled += _haversine(track[i - 1], track[i]);
      final d = _haversine(point, track[i]);
      if (d < bestDistance) {
        bestDistance = d;
        best = travelled;
      }
    }
    return best;
  }

  /// Simula caminhada ao longo do track, a `walkingSpeedMps`.
  void startWalking({double? fromMeters}) {
    _stopWalking();
    if (fromMeters != null) _progressMeters = fromMeters;
    final total = _trackLength();
    if (_progressMeters >= total) _progressMeters = 0;
    _emit(_pointAt(_progressMeters));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _progressMeters += walkingSpeedMps;
      if (_progressMeters > total) {
        _progressMeters = total;
        _emit(_pointAt(_progressMeters));
        _stopWalking();
        return;
      }
      _emit(_pointAt(_progressMeters), speed: walkingSpeedMps);
    });
  }

  void _stopWalking() {
    _timer?.cancel();
    _timer = null;
  }

  void stop() {
    _stopWalking();
    if (_current != null && !_controller.isClosed) {
      _controller.add(
        GpsFix(
          lat: _current!.lat,
          lng: _current!.lng,
          timestamp: DateTime.now(),
          accuracy: 3,
          simulated: true,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _stopWalking();
    await _controller.close();
  }

  /// Distância metros por grau (para o modo teleporte aproximar do track).
  static double get metersPerDegreeLat => _metersPerDegreeLat;
}
