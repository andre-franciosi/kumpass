import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'models/models.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/language_store.dart';
import 'services/map_cache.dart';
import 'theme/kumpas_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapCache.init();
  runApp(const KumpasApp());
}

class KumpasApp extends StatefulWidget {
  const KumpasApp({super.key});

  @override
  State<KumpasApp> createState() => _KumpasAppState();
}

class _KumpasAppState extends State<KumpasApp> {
  KumpasUser? _user;

  /// `null` = seguir o idioma do dispositivo (PT se pt*, senão EN).
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _restoreLocale();
  }

  Future<void> _restoreLocale() async {
    final code = await LanguageStore.load();
    if (!mounted || code == null) return;
    setState(() => _locale = Locale(code));
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    LanguageStore.save(locale.languageCode);
  }

  Locale get _effectiveLocale {
    if (_locale != null) return _locale!;
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return device.languageCode == 'pt' ? const Locale('pt') : const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kumpas',
      debugShowCheckedModeBanner: false,
      theme: KumpasTheme.light(),
      locale: _effectiveLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _user == null
          ? LoginScreen(
              onLoggedIn: (user) => setState(() => _user = user),
              locale: _effectiveLocale,
              onLocaleChanged: _setLocale,
            )
          : HomeScreen(
              user: _user!,
              onLogout: () => setState(() => _user = null),
              locale: _effectiveLocale,
              onLocaleChanged: _setLocale,
            ),
    );
  }
}
