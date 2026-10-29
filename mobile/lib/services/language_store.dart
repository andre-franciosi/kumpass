import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../theme/kumpas_theme.dart';

/// Persistência do idioma escolhido pelo utilizador.
class LanguageStore {
  static const String _key = 'kumpas_locale';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

/// Botão de idioma para a AppBar (abre folha com PT/EN).
class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final isPt = locale.languageCode == 'pt';
    return TextButton(
      onPressed: () => _openSheet(context),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(
        isPt ? 'PT' : 'EN',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KumpasPalette.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.language,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: KumpasPalette.ink,
                  ),
                ),
              ),
            ),
            _LanguageOption(
              label: l10n.languagePt,
              code: 'pt',
              selected: locale.languageCode == 'pt',
              onTap: () {
                onChanged(const Locale('pt'));
                Navigator.of(sheetContext).pop();
              },
            ),
            _LanguageOption(
              label: l10n.languageEn,
              code: 'en',
              selected: locale.languageCode == 'en',
              onTap: () {
                onChanged(const Locale('en'));
                Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? KumpasPalette.forest : KumpasPalette.muted,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: KumpasPalette.ink,
        ),
      ),
      trailing: Text(
        code.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: KumpasPalette.muted,
        ),
      ),
    );
  }
}

/// Toggle compacto de idioma (usado no login, antes de existir AppBar).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'pt', label: Text(context.l10n.languagePt)),
        ButtonSegment(value: 'en', label: Text(context.l10n.languageEn)),
      ],
      selected: {locale.languageCode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(Locale(selection.first)),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
