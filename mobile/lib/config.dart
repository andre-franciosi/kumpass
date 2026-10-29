/// Base URL da API (backend Fastify).
/// Configurável em runtime: `flutter run --dart-define=API_BASE_URL=...`
/// Default: emulador Android (10.0.2.2 -> host).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
